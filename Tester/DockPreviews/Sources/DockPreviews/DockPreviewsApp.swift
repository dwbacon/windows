
import SwiftUI

@main
struct DockPreviewsApp: App {
    private var dockMonitor: DockMonitor?
    @State private var settingsWindow: NSWindow?

    var body: some Scene {
        MenuBarExtra("Dock Previews", systemImage: "square.on.square") {
            Button("Preferences...") {
                openSettingsWindow()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Dock Previews") {
                NSApplication.shared.terminate(self)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    init() {
        // Check permissions on app launch
        let permissionsGranted = PermissionsManager.checkAndRequestPermissions()
        if permissionsGranted {
            self.dockMonitor = DockMonitor()
        } else {
            self.dockMonitor = nil
            print("DockPreviewsApp: DockMonitor not initialized due to missing Accessibility permissions.")
        }
    }

    func openSettingsWindow() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false)
            window.center()
            window.title = "Dock Previews Preferences"
            window.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.orderFrontRegardless() // Ensure it's on top
    }
}
