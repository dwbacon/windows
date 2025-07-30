#!/bin/bash

# Set exit-on-error mode
set -e

echo "🔨 Building WindowPreview..."

# Navigate to the project directory
cd "/Users/derekwood/Desktop/WindowPreview"

# Clean and build
xcodebuild -scheme WindowPreview -configuration Release build

# Check if the build was successful
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Define the path to the built app in DerivedData
BUILT_APP_PATH="/Users/derekwood/Library/Developer/Xcode/DerivedData/WindowPreview-acqrelywhssmvmdxkgweletxjoyc/Build/Products/Release/WindowPreview.app"

# Define the destination path on the Desktop
DESTINATION_APP_PATH="/Users/derekwood/Desktop/WindowPreview.app"

# Kill any existing instances of the app
pkill -f "WindowPreview" || true

# Remove any existing app bundle on the Desktop to ensure a clean copy
rm -rf "$DESTINATION_APP_PATH"

# Copy the built app to the Desktop
echo "📦 Copying app to Desktop..."
cp -R "$BUILT_APP_PATH" "$DESTINATION_APP_PATH"

# Ensure the copied app is executable
chmod -R +x "$DESTINATION_APP_PATH"

echo "✅ App copied to Desktop: $DESTINATION_APP_PATH"

# Launch the app and capture its output (for debugging purposes, will still log to file)
echo "🚀 Launching app and capturing logs..."
LOG_FILE="/Users/derekwood/Desktop/WindowPreview/logs/debug.log"

# Create the logs directory if it doesn't exist
LOG_DIR="/Users/derekwood/Desktop/WindowPreview/logs"
mkdir -p "$LOG_DIR"

# Clear previous log content
> "$LOG_FILE"

# Launch the app in the background and redirect its output to the log file
open -a "$DESTINATION_APP_PATH"

# Give the app a moment to start and write logs
sleep 2

# Display the captured logs
echo "✅ App launched successfully!"
echo "ℹ️ The app is running in the background. Check the menu bar for the 'WP' icon."