#!/bin/bash

# Auto build script for Android with automatic build number increment
echo "🚀 Starting Android build process..."

# Run auto increment script
./scripts/auto_increment_build.sh

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Build for Android
echo "📱 Building for Android..."
flutter build apk --release

echo "✅ Build complete!"
echo "📦 APK ready for distribution..." 