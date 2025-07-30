
import Cocoa

// Disabled - using AppDelegate.swift as main entry point instead
// @main
class SimpleApp: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Window Preview"
        
        // Create a text field
        let textField = NSTextField(frame: NSRect(x: 20, y: 130, width: 440, height: 40))
        textField.stringValue = "Hello, World!"
        textField.isBezeled = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = NSFont.systemFont(ofSize: 32)
        textField.alignment = .center
        
        // Add the text field to the window's content view
        window.contentView?.addSubview(textField)
        
        // Show the window
        window.makeKeyAndOrderFront(nil)
        
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}


