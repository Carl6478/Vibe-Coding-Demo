#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

echo "Installing Flutter ${FLUTTER_VERSION} (${FLUTTER_CHANNEL})..."
curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" -o flutter.tar.xz
tar xf flutter.tar.xz
export PATH="$PWD/flutter/bin:$PATH"

git config --global --add safe.directory "$PWD/flutter"
flutter --version
flutter config --no-analytics
flutter config --enable-web

echo "Fetching Dart/Flutter dependencies..."
flutter pub get

if [[ ! -f .env ]]; then
  echo "Generating .env from environment variables..."
  {
    [[ -n "${SUPABASE_URL:-}" ]] && echo "SUPABASE_URL=${SUPABASE_URL}"
    [[ -n "${SUPABASE_ANON_KEY:-}" ]] && echo "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"
    [[ -n "${WEATHER_LOCATION:-}" ]] && echo "WEATHER_LOCATION=${WEATHER_LOCATION}"
  } > .env
fi

echo "Building Flutter web release..."
flutter build web --release

echo "Build complete: build/web"
