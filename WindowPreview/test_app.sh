#!/bin/bash

echo "🧪 Testing WindowPreview App"
echo "=============================="

APP_PATH="/Users/derekwood/Desktop/WindowPreview/build/Debug/WindowPreview.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at: $APP_PATH"
    exit 1
fi

echo "✅ App found at: $APP_PATH"
echo ""
echo "🚀 Launching app and showing debug output..."
echo "   (Press Ctrl+C to stop)"
echo ""

# Launch the app and show its console output
open "$APP_PATH" --stdout --stderr

# Give it a moment to launch
sleep 2

echo ""
echo "📋 App should now be running."
echo "   1. Look for a stack icon (📚) in your menu bar"
echo "   2. Check Console.app for debug messages"
echo "   3. Try hovering over dock icons"
echo ""
echo "If you don't see the menu bar icon, the app may need accessibility permissions."
echo "Check System Preferences > Security & Privacy > Privacy > Accessibility"