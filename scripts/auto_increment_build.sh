#!/bin/bash

# Auto increment build number script with timestamp
echo "🔢 Auto incrementing build number..."

# Generate timestamp-based build number (YYYYMMDDHHMM)
TIMESTAMP=$(date +"%Y%m%d%H%M")

echo "Current timestamp: $(date)"
echo "New build number: $TIMESTAMP"

# Update pubspec.yaml with new build number
sed -i '' "s/version: [0-9.]*+[0-9]*/version: 1.0.0+$TIMESTAMP/" pubspec.yaml

echo "✅ Build number updated to $TIMESTAMP"
echo "📦 Ready to build..." 