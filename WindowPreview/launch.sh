#!/bin/bash

echo "🚀 Launching WindowPreview with console output..."
echo "================================================"

# Kill any existing instances
echo "🔪 Killing any existing WindowPreview instances..."
pkill -f WindowPreview || true

# Find the app bundle
APP_PATH="/Users/derekwood/Desktop/WindowPreview/build/Debug/WindowPreview.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at $APP_PATH"
    echo "🔨 Building the app first..."
    cd /Users/derekwood/Desktop/WindowPreview
    xcodebuild -scheme WindowPreview -configuration Debug build
fi

# Get the executable path
EXECUTABLE="$APP_PATH/Contents/MacOS/WindowPreview"

if [ ! -f "$EXECUTABLE" ]; then
    echo "❌ Executable not found at $EXECUTABLE"
    exit 1
fi

echo "✅ Found executable at: $EXECUTABLE"
echo "================================================"
echo "📋 Starting app with console output..."
echo "================================================"

# Run the app directly to see all console output
"$EXECUTABLE"