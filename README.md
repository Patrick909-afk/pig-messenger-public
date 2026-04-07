# PIG MESSENGER

Flutter messenger for friends with Supabase backend.

## Done
- Auth (email/password) via Supabase.
- Friends list from `profiles`.
- DM creation via SQL RPC `start_dm(other_user uuid)`.
- Realtime chat from `messages` table.
- Android minimum version: 5.0 (API 21).
- Round PNG icon created from your source image.

## Project structure
- `lib/main.dart` - app UI and Supabase integration.
- `supabase/schema.sql` - full database schema + RLS policies + triggers + RPC.
- `supabase/project_info.md` - created project info and keys.
- `assets/icons/app_icon_round.png` - generated round app icon.
- `scripts/create_project_and_schema.sh` - create project + apply schema via Supabase API.
- `scripts/apply_schema.sh` - apply schema to existing Supabase project.

## Run
1. Install Flutter SDK (stable channel).
2. In this folder run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter run \
  --dart-define=SUPABASE_URL=https://tmgiciwryliplkvewlhp.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If you keep default constants from `lib/main.dart`, `--dart-define` is optional.
