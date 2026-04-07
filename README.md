# PMessenger

Flutter-мессенджер для друзей на Supabase.

## Что есть
- Авторизация email/password через Supabase.
- Личные чаты и realtime сообщения.
- Русский интерфейс по умолчанию.
- Переключение языка на казахский в настройках.
- Визуальные эффекты в настройках: Liquid Glass, блюр, прозрачность.
- Глобальный шрифт Monocraft.
- Android minSdk 21 (Android 5.0).

## Основные файлы
- `lib/main.dart`
- `pubspec.yaml`
- `supabase/schema.sql`
- `assets/fonts/Monocraft.ttf`
- `assets/icons/app_icon_round.png`
- `.github/workflows/build-apk.yml`

## Сборка
```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter build apk --release
```
