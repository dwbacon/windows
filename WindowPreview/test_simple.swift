import Cocoa

@main
class TestApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var testWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 TEST APP STARTING")
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "WP"
        statusItem?.button?.action = #selector(statusClicked)
        statusItem?.button?.target = self
        
        // Create simple menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Test App Running", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        // Create test window
        testWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 200),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        testWindow?.title = "WindowPreview Test - SUCCESS!"
        testWindow?.center()
        testWindow?.makeKeyAndOrderFront(nil)
        
        print("✅ TEST APP READY - Look for 'WP' in menu bar and test window")
    }
    
    @objc func statusClicked() {
        let alert = NSAlert()
        alert.messageText = "Success!"
        alert.informativeText = "The status bar item is working!"
        alert.runModal()
    }
}