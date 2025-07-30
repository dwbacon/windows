import Cocoa

@main
class MinimalAppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("MINIMAL APP: Starting...")
        
        // Create status bar item with text to ensure visibility
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "TEST"
        
        // Create minimal menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        
        print("MINIMAL APP: Status bar should show 'TEST'")
    }
}