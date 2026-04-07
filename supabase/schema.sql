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

create table if not exists public.friendships (
  user_id uuid not null references public.profiles(id) on delete cascade,
  friend_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id < friend_id)
);

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
alter table public.messages
  add column if not exists edited_at timestamptz;

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

create or replace function public.upsert_profile(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user is null then
    return;
  end if;

  insert into public.profiles (id, username, full_name)
  values (
    p_user,
    'user_' || replace(p_user::text, '-', ''),
    'User'
  )
  on conflict (id) do nothing;
end;
$$;

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
after insert or update on public.messages
for each row execute function public.touch_conversation();

create or replace function public.mark_message_edited_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.edited_at := now();
  return new;
end;
$$;

drop trigger if exists trg_mark_message_edited on public.messages;
create trigger trg_mark_message_edited
before update on public.messages
for each row execute function public.mark_message_edited_at();

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

  perform public.upsert_profile(me);
  perform public.upsert_profile(other_user);

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


drop function if exists public.create_group_chat(text, uuid[]);

create or replace function public.create_group_chat(group_title text, member_ids text[] default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  convo uuid;
  member_text text;
  member_id uuid;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  perform public.upsert_profile(me);

  insert into public.conversations (is_group, title, created_by)
  values (true, nullif(trim(group_title), ''), me)
  returning id into convo;

  insert into public.conversation_participants (conversation_id, user_id, role)
  values (convo, me, 'owner')
  on conflict do nothing;

  foreach member_text in array coalesce(member_ids, array[]::text[]) loop
    begin
      member_id := nullif(trim(member_text), '')::uuid;
    exception when others then
      continue;
    end;

    if member_id is not null and member_id <> me then
      perform public.upsert_profile(member_id);
      insert into public.conversation_participants (conversation_id, user_id, role)
      values (convo, member_id, 'member')
      on conflict do nothing;
    end if;
  end loop;

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


create or replace function public.add_friend_by_username(p_username text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  target uuid;
  left_id uuid;
  right_id uuid;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  perform public.upsert_profile(me);

  select p.id into target
  from public.profiles p
  where lower(coalesce(p.username, '')) = lower(trim(p_username))
     or lower(coalesce(p.full_name, '')) = lower(trim(p_username))
  limit 1;

  if target is null then
    raise exception 'user_not_found';
  end if;

  if target = me then
    raise exception 'cannot_add_self';
  end if;

  perform public.upsert_profile(target);

  left_id := least(me, target);
  right_id := greatest(me, target);

  insert into public.friendships (user_id, friend_id)
  values (left_id, right_id)
  on conflict do nothing;

  return target;
end;
$$;

create or replace function public.get_my_friends()
returns table (
  id uuid,
  username text,
  full_name text,
  last_seen timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select p.id, p.username, p.full_name, p.last_seen, p.created_at
  from public.friendships f
  join public.profiles p
    on p.id = case when f.user_id = auth.uid() then f.friend_id else f.user_id end
  where auth.uid() in (f.user_id, f.friend_id)
  order by p.last_seen desc nulls last, p.created_at desc;
$$;

create or replace function public.get_friend_suggestions(limit_count integer default 10)
returns table (
  id uuid,
  username text,
  full_name text,
  last_seen timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select p.id, p.username, p.full_name, p.last_seen, p.created_at
  from public.profiles p
  where p.id <> auth.uid()
    and not exists (
      select 1
      from public.friendships f
      where (f.user_id = least(auth.uid(), p.id) and f.friend_id = greatest(auth.uid(), p.id))
    )
  order by p.last_seen desc nulls last, p.created_at desc
  limit greatest(1, least(coalesce(limit_count, 10), 20));
$$;


create or replace function public.search_users(p_query text default '', limit_count integer default 20)
returns table (
  id uuid,
  username text,
  full_name text,
  last_seen timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select p.id, p.username, p.full_name, p.last_seen, p.created_at
  from public.profiles p
  where p.id <> auth.uid()
    and (
      trim(coalesce(p_query, '')) = ''
      or lower(coalesce(p.username, '')) like '%' || lower(trim(p_query)) || '%'
      or lower(coalesce(p.full_name, '')) like '%' || lower(trim(p_query)) || '%'
    )
  order by p.last_seen desc nulls last, p.created_at desc
  limit greatest(1, least(coalesce(limit_count, 20), 50));
$$;

create or replace function public.start_self_chat()
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

  perform public.upsert_profile(me);

  select cp.conversation_id
  into convo
  from public.conversation_participants cp
  join public.conversations c on c.id = cp.conversation_id
  where cp.user_id = me
    and c.is_group = false
    and not exists (
      select 1
      from public.conversation_participants cp2
      where cp2.conversation_id = cp.conversation_id
        and cp2.user_id <> me
    )
  limit 1;

  if convo is null then
    insert into public.conversations (is_group, title, created_by)
    values (false, 'Saved Messages', me)
    returning id into convo;

    insert into public.conversation_participants (conversation_id, user_id, role)
    values (convo, me, 'owner')
    on conflict do nothing;
  end if;

  return convo;
end;
$$;

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.friendships enable row level security;
alter table public.messages enable row level security;

create or replace function public.is_conversation_member(p_conversation_id uuid, p_user uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.conversation_participants cp
    where cp.conversation_id = p_conversation_id
      and cp.user_id = coalesce(p_user, auth.uid())
  );
$$;

create or replace function public.is_conversation_admin(p_conversation_id uuid, p_user uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.conversation_participants cp
    where cp.conversation_id = p_conversation_id
      and cp.user_id = coalesce(p_user, auth.uid())
      and cp.role in ('owner','admin')
  );
$$;

create or replace function public.is_group_admin(p_conversation_id uuid, p_user uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.conversation_participants cp
    join public.conversations c on c.id = cp.conversation_id
    where cp.conversation_id = p_conversation_id
      and cp.user_id = coalesce(p_user, auth.uid())
      and cp.role in ('owner','admin')
      and c.is_group = true
  );
$$;

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
using (public.is_conversation_member(id));

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
using (public.is_conversation_member(conversation_participants.conversation_id));

drop policy if exists "participants_insert_self_or_admin" on public.conversation_participants;
create policy "participants_insert_self_or_admin"
on public.conversation_participants
for insert
with check (
  user_id = auth.uid()
  or public.is_conversation_admin(conversation_participants.conversation_id)
);

drop policy if exists "participants_update_admin" on public.conversation_participants;
create policy "participants_update_admin"
on public.conversation_participants
for update
using (public.is_conversation_admin(conversation_participants.conversation_id))
with check (public.is_conversation_admin(conversation_participants.conversation_id));

drop policy if exists "participants_delete_self_or_admin" on public.conversation_participants;
create policy "participants_delete_self_or_admin"
on public.conversation_participants
for delete
using (
  user_id = auth.uid()
  or public.is_conversation_admin(conversation_participants.conversation_id)
);

-- friendships policies
drop policy if exists "friendships_select_self" on public.friendships;
create policy "friendships_select_self"
on public.friendships
for select
using (auth.uid() in (user_id, friend_id));

drop policy if exists "friendships_insert_self" on public.friendships;
create policy "friendships_insert_self"
on public.friendships
for insert
with check (auth.uid() in (user_id, friend_id));

drop policy if exists "friendships_delete_self" on public.friendships;
create policy "friendships_delete_self"
on public.friendships
for delete
using (auth.uid() in (user_id, friend_id));

-- messages policies
drop policy if exists "messages_select_member" on public.messages;
create policy "messages_select_member"
on public.messages
for select
using (public.is_conversation_member(messages.conversation_id));

drop policy if exists "messages_insert_sender_member" on public.messages;
create policy "messages_insert_sender_member"
on public.messages
for insert
with check (
  sender_id = auth.uid()
  and public.is_conversation_member(messages.conversation_id)
);

drop policy if exists "messages_update_own_or_group_admin" on public.messages;
create policy "messages_update_own_or_group_admin"
on public.messages
for update
using (
  sender_id = auth.uid()
  or public.is_group_admin(messages.conversation_id)
)
with check (
  sender_id = auth.uid()
  or public.is_group_admin(messages.conversation_id)
);

drop policy if exists "messages_delete_own" on public.messages;
drop policy if exists "messages_delete_own_or_group_admin" on public.messages;
create policy "messages_delete_own_or_group_admin"
on public.messages
for delete
using (
  sender_id = auth.uid()
  or public.is_group_admin(messages.conversation_id)
);

grant usage on schema public to anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert on public.conversations to authenticated;
grant select, insert, update, delete on public.conversation_participants to authenticated;
grant select, insert, delete on public.friendships to authenticated;
grant select, insert, update, delete on public.messages to authenticated;
grant execute on function public.start_dm(uuid) to authenticated;
grant execute on function public.upsert_profile(uuid) to authenticated;
grant execute on function public.add_friend_by_username(text) to authenticated;
grant execute on function public.get_my_friends() to authenticated;
grant execute on function public.get_friend_suggestions(integer) to authenticated;
grant execute on function public.search_users(text, integer) to authenticated;
grant execute on function public.start_self_chat() to authenticated;
grant execute on function public.create_group_chat(text, text[]) to authenticated;
grant execute on function public.set_group_role(uuid, uuid, text) to authenticated;
grant execute on function public.remove_group_member(uuid, uuid) to authenticated;
grant execute on function public.is_conversation_member(uuid, uuid) to authenticated;
grant execute on function public.is_conversation_admin(uuid, uuid) to authenticated;
grant execute on function public.is_group_admin(uuid, uuid) to authenticated;


insert into storage.buckets (id, name, public, file_size_limit)
values ('chat-media', 'chat-media', true, 104857600)
on conflict (id) do nothing;

drop policy if exists "chat_media_public_read" on storage.objects;
create policy "chat_media_public_read"
on storage.objects
for select
using (bucket_id = 'chat-media');

drop policy if exists "chat_media_auth_insert" on storage.objects;
create policy "chat_media_auth_insert"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'chat-media');

drop policy if exists "chat_media_owner_update" on storage.objects;
create policy "chat_media_owner_update"
on storage.objects
for update
to authenticated
using (bucket_id = 'chat-media' and owner = auth.uid())
with check (bucket_id = 'chat-media' and owner = auth.uid());

drop policy if exists "chat_media_owner_delete" on storage.objects;
create policy "chat_media_owner_delete"
on storage.objects
for delete
to authenticated
using (bucket_id = 'chat-media' and owner = auth.uid());
