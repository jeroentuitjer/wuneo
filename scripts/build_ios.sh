#!/bin/bash

# Auto build script for iOS with automatic build number increment
echo "🚀 Starting iOS build process..."

# Run auto increment script
./scripts/auto_increment_build.sh

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Build for iOS
echo "📱 Building for iOS..."
flutter build ios --release

echo "✅ Build complete!"
echo "📦 Ready to archive in Xcode..." 