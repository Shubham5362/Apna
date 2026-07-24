#!/bin/bash
set -e

# Establish path variables
export PATH="$PWD/.flutter/bin:$PATH"

# Check if Flutter is already cached/installed in .flutter folder
if [ ! -d ".flutter" ]; then
  echo "=== Downloading and Installing Flutter ==="
  curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
  tar xf flutter_linux_3.24.0-stable.tar.xz
  mv flutter .flutter
  rm flutter_linux_3.24.0-stable.tar.xz
fi

echo "=== Configuring Flutter ==="
flutter config --no-analytics
flutter config --enable-web

echo "=== Building Flutter Web ==="
flutter pub get
flutter build web --release --dart-define=BACKEND_URL=https://apna-mandla-backend.onrender.com

echo "=== Build Completed Successfully ==="
