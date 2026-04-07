# PMessenger

Flutter messenger on Supabase.

## Implemented
- Login by username/password via internal email alias.
- Personal chats, groups, realtime messages.
- Reply/edit/delete messages.
- Block and unblock users.
- Search users and add friends by username.
- Profile settings and notification toggles.

## Security notes
Use runtime defines in production build:
SUPABASE_URL
SUPABASE_ANON_KEY
CHAT_CRYPTO_SECRET

If defines are not passed, app uses default values from source.

## Generate crypto secret
sh scripts/gen_runtime_secrets.sh

## Run app
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY --dart-define=CHAT_CRYPTO_SECRET=YOUR_RANDOM_SECRET

## Apply DB schema
SUPABASE_PAT=YOUR_PAT SUPABASE_PROJECT_REF=YOUR_PROJECT_REF sh scripts/apply_schema.sh
