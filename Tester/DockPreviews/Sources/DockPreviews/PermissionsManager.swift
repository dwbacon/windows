
import Foundation
import AppKit
import CoreGraphics

class PermissionsManager {
    /// Checks the current permission status without prompting the user.
    static func checkPermissions() -> Bool {
        let status = permissionsStatus()
        print("Current Permissions Status: \(status)")
        return status["Accessibility"] ?? false
    }

    static func permissionsStatus() -> [String: Bool] {
        // Use AXIsProcessTrustedWithOptions with the prompt option disabled to
        // avoid showing any permission dialogs when simply checking status.
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let accessibilityGranted = AXIsProcessTrustedWithOptions(options)
        let screenRecordingGranted: Bool
        if #available(macOS 10.15, *) {
            screenRecordingGranted = CGPreflightScreenCaptureAccess()
        } else {
            screenRecordingGranted = true
        }
        return [
            "Accessibility": accessibilityGranted,
            "Screen Recording": screenRecordingGranted
        ]
    }

    static func manuallyRequestPermissions() {
        requestAccessibilityPermission()
        requestScreenRecordingPermission()
    }

    static func requestAccessibilityPermission() {
        openAccessibilitySettings()
    }

    static func requestScreenRecordingPermission() {
        if #available(macOS 10.15, *) {
            CGRequestScreenCaptureAccess()
        }
        openScreenRecordingSettings()
    }

    // These methods are kept private as helpers for opening the relevant
    // System Settings panes.

    private static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenRecording") {
            NSWorkspace.shared.open(url)
        }
    }
}
