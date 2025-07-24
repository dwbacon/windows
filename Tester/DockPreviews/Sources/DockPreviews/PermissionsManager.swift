
import Foundation
import AppKit
import CoreGraphics

class PermissionsManager {
    static func checkAndRequestPermissions() -> Bool {
        let status = permissionsStatus()
        print("Current Permissions Status: \(status)")
        let accessibilityGranted = checkAccessibilityPermissions()
        checkScreenRecordingPermissions()
        return accessibilityGranted
    }

    static func permissionsStatus() -> [String: Bool] {
        let accessibilityGranted = AXIsProcessTrusted()
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
        openAccessibilitySettings()
        openScreenRecordingSettings()
    }

    private static func checkAccessibilityPermissions() -> Bool {
        let accessEnabled = AXIsProcessTrusted()

        if !accessEnabled {
            print("Accessibility access NOT granted. Please go to System Settings -> Privacy & Security -> Accessibility and ensure 'DockPreviews' (or 'Xcode' if running from there) is checked.")
            openAccessibilitySettings()
        } else {
            print("Accessibility access GRANTED.")
        }
        return accessEnabled
    }

    private static func checkScreenRecordingPermissions() {
        if #available(macOS 10.15, *) {
            if !CGPreflightScreenCaptureAccess() {
                print("Screen Recording access NOT granted. Requesting access...")
                CGRequestScreenCaptureAccess()
            } else {
                print("Screen Recording access GRANTED.")
            }
        }
    }

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
