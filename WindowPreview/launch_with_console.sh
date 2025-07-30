#!/bin/bash
set -x

echo "🚀 Launching WindowPreview with console output..."

# Kill any existing instances
pkill -f WindowPreview || true

# Define a temporary log file
LOG_FILE="/tmp/window_preview_log.txt"

# Launch the app and redirect its output to the log file
"/Users/derekwood/Library/Developer/Xcode/DerivedData/WindowPreview-acqrelywhssmvmdxkgweletxjoyc/Build/Products/Debug/WindowPreview.app/Contents/MacOS/WindowPreview" > "$LOG_FILE" 2>&1 &

# Give the app a moment to start and write logs
sleep 2

echo "📱 App launched! Check for menu bar icon and debug output above."
echo "Press Ctrl+C to quit."

# Display the log file content
cat "$LOG_FILE"

# Keep script running
wait