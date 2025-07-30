
import SwiftUI

struct SettingsView: View {
    var onRestart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("WindowPreview Settings")
                .font(.largeTitle)
            
            Text("Permissions")
                .font(.title2)
            
            PermissionRow(
                title: "Screen Recording",
                description: "Required to capture window content.",
                isGranted: isScreenRecordingEnabled(),
                requestAction: requestScreenRecordingPermission
            )
            
            PermissionRow(
                title: "Accessibility",
                description: "Required to detect hovered applications in the dock.",
                isGranted: AXIsProcessTrusted(),
                requestAction: requestAccessibilityPermission
            )
            
            Spacer()
            
            VStack(spacing: 10) {
                Button("Reset Permissions") {
                    resetPermissions()
                }
                .foregroundColor(.red)
                
                Button("Restart App", action: onRestart)
            }
        }
        .padding()
        .frame(width: 400, height: 320)
    }
    
    private func isScreenRecordingEnabled() -> Bool {
        if #available(macOS 10.15, *) {
            let stream = CGDisplayStream(dispatchQueueDisplay: CGMainDisplayID(), outputWidth: 1, outputHeight: 1, pixelFormat: 1, properties: nil, queue: .main) { _, _, _, _ in }
            return stream != nil
        }
        return false
    }
    
    private func requestScreenRecordingPermission() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func requestAccessibilityPermission() {
        let options: [String: Bool] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private func resetPermissions() {
        let alert = NSAlert()
        alert.messageText = "Reset Permissions"
        alert.informativeText = "This will reset all TCC permissions for WindowPreview and quit the app. You'll need to grant permissions again when you restart the app.\n\nContinue?"
        alert.addButton(withTitle: "Reset & Quit")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Reset permissions using tccutil
            let task = Process()
            task.launchPath = "/usr/bin/tccutil"
            task.arguments = ["reset", "All", "com.derekwood.WindowPreview"]
            
            do {
                try task.run()
                task.waitUntilExit()
                
                if task.terminationStatus == 0 {
                    let successAlert = NSAlert()
                    successAlert.messageText = "Permissions Reset"
                    successAlert.informativeText = "All permissions have been reset. The app will now restart and prompt for permissions again."
                    successAlert.runModal()
                    restartApp()
                } else {
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Reset Failed"
                    errorAlert.informativeText = "Failed to reset permissions. You may need to manually reset them in System Settings."
                    errorAlert.runModal()
                }
            } catch {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Reset Failed"
                errorAlert.informativeText = "Failed to reset permissions: \(error.localizedDescription)"
                errorAlert.runModal()
            }
        }
    }
    
    private func restartApp() {
        // Get the path to the current application
        let appPath = Bundle.main.bundlePath
        
        // Create a task to restart the app after a short delay
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 0.5 && open '\(appPath)'"]
        
        do {
            try task.run()
            // Quit the current app instance
            NSApplication.shared.terminate(nil)
        } catch {
            // Fallback: just quit if restart fails
            NSApplication.shared.terminate(nil)
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let requestAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(description).font(.caption)
            }
            Spacer()
            if isGranted {
                Text("Granted")
                    .foregroundColor(.green)
            } else {
                Button("Grant", action: requestAction)
            }
        }
    }
}
