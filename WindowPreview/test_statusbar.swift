#!/usr/bin/swift

import Cocoa

class TestApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 TEST APP STARTING")
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.title = "TEST"
            print("✅ Status bar button created with title: TEST")
        } else {
            print("❌ Failed to create status bar button")
        }
        
        // Create simple menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Test Item", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        print("✅ Menu attached to status bar")
        
        print("🎯 App should now show 'TEST' in menu bar")
    }
}

// Create and run app
let app = NSApplication.shared
let delegate = TestApp()
app.delegate = delegate
app.setActivationPolicy(.accessory)
print("🏃 Running test app...")
app.run()