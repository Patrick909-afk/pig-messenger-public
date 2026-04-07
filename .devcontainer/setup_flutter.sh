#!/usr/bin/env bash
set -euo pipefail
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"
flutter config --no-analytics
flutter precache --android
flutter doctor -v
