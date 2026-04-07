-- PIG MESSENGER schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  full_name text,
  avatar_url text,
  last_seen timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  is_group boolean not null default false,
  title text,
  created_by uuid not null references public.profiles(id) on delete cascade,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  last_read_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

alter table public.conversation_participants
  add column if not exists role text not null default 'member'
  check (role in ('owner','admin','member'));

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now()
);


alter table public.messages
  add column if not exists message_type text not null default 'text'
  check (message_type in ('text','sticker','image','video','gif','file','location'));
alter table public.messages
  add column if not exists media_url text;
alter table public.messages
  add column if not exists file_name text;
alter table public.messages
  add column if not exists mime_type text;
alter table public.messages
  add column if not exists latitude double precision;
alter table public.messages
  add column if not exists longitude double precision;
alter table public.messages
  add column if not exists meta jsonb not null default '{}'::jsonb;

alter table public.messages drop constraint if exists messages_body_check;
alter table public.messages add constraint messages_body_check check (
  length(trim(coalesce(body, ''))) > 0
  or media_url is not null
  or (latitude is not null and longitude is not null)
);

create index if not exists idx_messages_conversation_created
  on public.messages(conversation_id, created_at);

create index if not exists idx_participants_user
  on public.conversation_participants(user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, full_name)
  values (
    new.id,
    coalesce(split_part(new.email, '@', 1) || '_' || substr(new.id::text, 1, 6), 'user_' || substr(new.id::text, 1, 8)),
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.touch_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
  set updated_at = now()
  where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists trg_touch_conversation on public.messages;
create trigger trg_touch_conversation
after insert on public.messages
for each row execute function public.touch_conversation();

create or replace function public.start_dm(other_user uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  convo uuid;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  if me = other_user then
    raise exception 'cannot create chat with self';
  end if;

  select cp1.conversation_id
  into convo
  from public.conversation_participants cp1
  join public.conversation_participants cp2
    on cp1.conversation_id = cp2.conversation_id
  join public.conversations c
    on c.id = cp1.conversation_id
  where cp1.user_id = me
    and cp2.user_id = other_user
    and c.is_group = false
  limit 1;

  if convo is null then
    insert into public.conversations (is_group, title, created_by)
    values (false, null, me)
    returning id into convo;

    insert into public.conversation_participants (conversation_id, user_id)
    values (convo, me), (convo, other_user);
  end if;

  return convo;
end;
$$;


create or replace function public.create_group_chat(group_title text, member_ids uuid[])
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  convo uuid;
  member_id uuid;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  insert into public.conversations (is_group, title, created_by)
  values (true, nullif(trim(group_title), ''), me)
  returning id into convo;

  insert into public.conversation_participants (conversation_id, user_id, role)
  values (convo, me, 'owner')
  on conflict do nothing;

  if member_ids is not null then
    foreach member_id in array member_ids loop
      if member_id is not null and member_id <> me and exists (select 1 from public.profiles p where p.id = member_id) then
        insert into public.conversation_participants (conversation_id, user_id, role)
        values (convo, member_id, 'member')
        on conflict do nothing;
      end if;
    end loop;
  end if;

  return convo;
end;
$$;

create or replace function public.set_group_role(group_id uuid, member_id uuid, new_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  my_role text;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  if new_role not in ('admin','member') then
    raise exception 'invalid role';
  end if;

  select role into my_role
  from public.conversation_participants
  where conversation_id = group_id and user_id = me;

  if my_role not in ('owner','admin') then
    raise exception 'forbidden';
  end if;

  update public.conversation_participants
  set role = new_role
  where conversation_id = group_id and user_id = member_id and role <> 'owner';
end;
$$;

create or replace function public.remove_group_member(group_id uuid, member_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  my_role text;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  if me <> member_id then
    select role into my_role
    from public.conversation_participants
    where conversation_id = group_id and user_id = me;

    if my_role not in ('owner','admin') then
      raise exception 'forbidden';
    end if;
  end if;

  delete from public.conversation_participants
  where conversation_id = group_id and user_id = member_id and role <> 'owner';
end;
$$;

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

-- profiles policies
drop policy if exists "profiles_select_all_auth" on public.profiles;
create policy "profiles_select_all_auth"
on public.profiles
for select
using (auth.role() = 'authenticated');

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- conversations policies
drop policy if exists "conversations_select_member" on public.conversations;
create policy "conversations_select_member"
on public.conversations
for select
using (
  exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = id and cp.user_id = auth.uid()
  )
);

drop policy if exists "conversations_insert_authenticated" on public.conversations;
create policy "conversations_insert_authenticated"
on public.conversations
for insert
with check (auth.uid() = created_by);

-- participant policies
drop policy if exists "participants_select_member" on public.conversation_participants;
create policy "participants_select_member"
on public.conversation_participants
for select
using (
  exists (
    select 1 from public.conversation_participants me
    where me.conversation_id = conversation_participants.conversation_id
      and me.user_id = auth.uid()
  )
);

drop policy if exists "participants_insert_self_or_admin" on public.conversation_participants;
create policy "participants_insert_self_or_admin"
on public.conversation_participants
for insert
with check (
  user_id = auth.uid()
  or exists (
    select 1 from public.conversation_participants me
    where me.conversation_id = conversation_participants.conversation_id
      and me.user_id = auth.uid()
      and me.role in ('owner','admin')
  )
);

drop policy if exists "participants_update_admin" on public.conversation_participants;
create policy "participants_update_admin"
on public.conversation_participants
for update
using (
  exists (
    select 1 from public.conversation_participants me
    where me.conversation_id = conversation_participants.conversation_id
      and me.user_id = auth.uid()
      and me.role in ('owner','admin')
  )
)
with check (
  exists (
    select 1 from public.conversation_participants me
    where me.conversation_id = conversation_participants.conversation_id
      and me.user_id = auth.uid()
      and me.role in ('owner','admin')
  )
);

drop policy if exists "participants_delete_self_or_admin" on public.conversation_participants;
create policy "participants_delete_self_or_admin"
on public.conversation_participants
for delete
using (
  user_id = auth.uid()
  or exists (
    select 1 from public.conversation_participants me
    where me.conversation_id = conversation_participants.conversation_id
      and me.user_id = auth.uid()
      and me.role in ('owner','admin')
  )
);

-- messages policies
drop policy if exists "messages_select_member" on public.messages;
create policy "messages_select_member"
on public.messages
for select
using (
  exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = messages.conversation_id
      and cp.user_id = auth.uid()
  )
);

drop policy if exists "messages_insert_sender_member" on public.messages;
create policy "messages_insert_sender_member"
on public.messages
for insert
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = messages.conversation_id
      and cp.user_id = auth.uid()
  )
);

drop policy if exists "messages_delete_own" on public.messages;
create policy "messages_delete_own"
on public.messages
for delete
using (sender_id = auth.uid());

grant usage on schema public to anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert on public.conversations to authenticated;
grant select, insert, update, delete on public.conversation_participants to authenticated;
grant select, insert, delete on public.messages to authenticated;
grant execute on function public.start_dm(uuid) to authenticated;

grant execute on function public.create_group_chat(text, uuid[]) to authenticated;
grant execute on function public.set_group_role(uuid, uuid, text) to authenticated;
grant execute on function public.remove_group_member(uuid, uuid) to authenticated;
