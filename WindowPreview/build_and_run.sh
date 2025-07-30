#!/bin/bash

echo "🔨 Building WindowPreview..."
cd /Users/derekwood/Desktop/WindowPreview

# Clean and build
xcodebuild clean
xcodebuild -scheme WindowPreview -configuration Debug build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "🚀 Launching app..."
    
    # Kill any existing instances
    pkill -f WindowPreview || true
    
    # Launch the app
    open /Users/derekwood/Library/Developer/Xcode/DerivedData/WindowPreview-acqrelywhssmvmdxkgweletxjoyc/Build/Products/Debug/WindowPreview.app
    
    echo "📱 App should now appear in dock and menu bar!"
    echo "👀 Look for 'WP' text or stack icon in menu bar"
else
    echo "❌ Build failed!"
    exit 1
fi