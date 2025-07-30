#!/usr/bin/env python3
import subprocess
import time
import sys

print("🧪 Testing WindowPreview App...")
print("=" * 50)

# Launch the app in background
try:
    process = subprocess.Popen([
        '/Users/derekwood/Desktop/WindowPreview/build/Release/WindowPreview.app/Contents/MacOS/WindowPreview'
    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    
    print("✅ App launched, waiting 3 seconds for initialization...")
    time.sleep(3)
    
    # Check if process is still running
    if process.poll() is None:
        print("✅ App is still running")
        
        # Try to get any output
        try:
            stdout, stderr = process.communicate(timeout=2)
            if stdout:
                print("📝 STDOUT:")
                print(stdout)
            if stderr:
                print("❌ STDERR:")
                print(stderr)
        except subprocess.TimeoutExpired:
            print("⏰ App is running but no immediate output")
            
        # Kill the process
        process.terminate()
        process.wait()
        print("🛑 App terminated")
    else:
        print("❌ App exited immediately")
        stdout, stderr = process.communicate()
        if stdout:
            print("📝 STDOUT:")
            print(stdout)
        if stderr:
            print("❌ STDERR:")
            print(stderr)
            
except Exception as e:
    print(f"❌ Error: {e}")

print("=" * 50)
print("🔍 Now checking if any WindowPreview processes are running...")
try:
    result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
    windowpreview_lines = [line for line in result.stdout.split('\n') if 'WindowPreview' in line and 'grep' not in line]
    if windowpreview_lines:
        print("✅ Found WindowPreview processes:")
        for line in windowpreview_lines:
            print(f"  {line}")
    else:
        print("❌ No WindowPreview processes found")
except Exception as e:
    print(f"❌ Error checking processes: {e}")