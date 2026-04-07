#!/bin/sh
set -eu

if command -v openssl >/dev/null 2>&1; then
  CHAT_CRYPTO_SECRET=$(openssl rand -base64 48 | tr -d "\n" | tr "/+" "_-" | cut -c1-64)
else
  CHAT_CRYPTO_SECRET=$(date +%s%N | sha256sum | cut -d" " -f1)
fi

echo "Generated CHAT_CRYPTO_SECRET"
echo ""
echo "Export before run/build:"
echo "export CHAT_CRYPTO_SECRET=${CHAT_CRYPTO_SECRET}"
echo ""
echo "Example:"
echo "flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY --dart-define=CHAT_CRYPTO_SECRET=${CHAT_CRYPTO_SECRET}"
