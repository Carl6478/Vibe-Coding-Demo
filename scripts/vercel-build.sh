#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

echo "Installing Flutter (${FLUTTER_VERSION})..."
curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_VERSION}/linux/flutter_linux_3.24.5-${FLUTTER_VERSION}.tar.xz" -o flutter.tar.xz
tar xf flutter.tar.xz
export PATH="$PWD/flutter/bin:$PATH"

flutter --version
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
