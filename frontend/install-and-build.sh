#!/usr/bin/env bash

# Exit on error
set -e

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$SCRIPT_DIR/.flutter"

# Install Flutter if it doesn't exist
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "Installing Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
else
    echo "Flutter SDK already installed."
fi

# Add Flutter to PATH
export PATH="$FLUTTER_DIR/bin:$PATH"

# Disable analytics
flutter config --no-analytics

# Run doctor
flutter doctor -v

# Run builds
cd "$SCRIPT_DIR"
flutter pub get

if [ -n "$BACKEND_URL" ]; then
    echo "Building Flutter Web with BACKEND_URL=$BACKEND_URL..."
    flutter build web --release --dart-define=BACKEND_URL="$BACKEND_URL"
else
    echo "Building Flutter Web with default BACKEND_URL..."
    flutter build web --release
fi
