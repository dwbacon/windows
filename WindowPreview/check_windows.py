#!/usr/bin/env python3
import subprocess
import json

print("🔍 Checking for WindowPreview windows and menu bar items...")

# Check for windows using AppleScript
try:
    script = '''
    tell application "System Events"
        set windowList to {}
        repeat with p in processes
            if name of p contains "WindowPreview" then
                set end of windowList to (name of p & ": " & (count of windows of p) & " windows")
                repeat with w in windows of p
                    try
                        set end of windowList to ("  Window: " & title of w)
                    end try
                end repeat
            end if
        end repeat
        return windowList
    end tell
    '''
    
    result = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
    if result.stdout.strip():
        print("✅ Found WindowPreview process info:")
        for line in result.stdout.strip().split(', '):
            print(f"  {line}")
    else:
        print("❌ No WindowPreview windows found")
        
    if result.stderr:
        print(f"❌ AppleScript error: {result.stderr}")
        
except Exception as e:
    print(f"❌ Error running AppleScript: {e}")

# Also check for status bar items
print("\n🔍 Checking menu bar for 'WP' text...")
try:
    script2 = '''
    tell application "System Events"
        tell process "SystemUIServer"
            set menuItems to {}
            try
                repeat with menuExtra in menu bar items of menu bar 1
                    set end of menuItems to title of menuExtra
                end repeat
            end try
            return menuItems
        end tell
    end tell
    '''
    
    result2 = subprocess.run(['osascript', '-e', script2], capture_output=True, text=True)
    if result2.stdout.strip():
        print("✅ Menu bar items found:")
        items = result2.stdout.strip().split(', ')
        found_wp = False
        for item in items:
            if 'WP' in item or 'WindowPreview' in item.lower():
                print(f"  🎯 FOUND: {item}")
                found_wp = True
            else:
                print(f"    {item}")
        if not found_wp:
            print("❌ No 'WP' or WindowPreview found in menu bar")
    else:
        print("❌ Could not read menu bar items")
        
except Exception as e:
    print(f"❌ Error checking menu bar: {e}")