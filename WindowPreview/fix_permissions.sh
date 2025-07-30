#!/bin/bash

echo "🔧 WindowPreview Permission Fix Script"
echo "======================================"

# Reset permissions to start fresh
echo "1. Resetting Screen Recording permissions..."
tccutil reset ScreenCapture

echo "2. Checking current code signing status..."
APP_PATH="/Users/derekwood/Library/Developer/Xcode/DerivedData/WindowPreview-acqrelywhssmvmdxkgweletxjoyc/Build/Products/Debug/WindowPreview.app"

if [ -d "$APP_PATH" ]; then
    codesign -dv "$APP_PATH" 2>&1
    echo ""
    
    echo "3. Attempting to sign with ad-hoc signature..."
    codesign --force --deep --sign - "$APP_PATH"
    
    if [ $? -eq 0 ]; then
        echo "✅ App signed successfully"
        echo ""
        echo "4. Verifying signature..."
        codesign -dv "$APP_PATH" 2>&1
        echo ""
        echo "🚀 Now try running the app and granting screen recording permission."
        echo "   The permission should stick after recompiling."
    else
        echo "❌ Failed to sign app"
    fi
else
    echo "❌ App not found at expected path"
    echo "   Build the app first with: xcodebuild -project WindowPreview.xcodeproj -scheme WindowPreview -configuration Debug build"
fi

echo ""
echo "📋 Manual Steps:"
echo "1. Open System Settings → Privacy & Security → Screen Recording"
echo "2. Remove WindowPreview if it's listed"
echo "3. Run the newly signed app"
echo "4. Grant screen recording permission when prompted"
echo "5. The permission should now persist across rebuilds"