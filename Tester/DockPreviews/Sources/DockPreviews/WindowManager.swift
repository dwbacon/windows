
import Foundation
import AppKit

class WindowManager {
    func getOpenWindows(for appName: String) -> [NSImage] {
        // Avoid triggering the system Screen Recording prompt automatically.
        if #available(macOS 10.15, *) {
            guard CGPreflightScreenCaptureAccess() else {
                print("WindowManager: Screen Recording permission not granted.")
                return []
            }
        }

        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as! [[String: AnyObject]]

        print("WindowManager: Found \(windowListInfo.count) total windows.")

        var windowImages: [NSImage] = []

        for windowInfo in windowListInfo {
            if let ownerName = windowInfo[kCGWindowOwnerName as String] as? String {
                print("WindowManager: Processing window for app: \(ownerName)")
                if ownerName == appName {
                    print("WindowManager: Matched app: \(appName)")
                    if let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID {
                        let image = CGWindowListCreateImage(CGRect.null, .optionIncludingWindow, windowID, .bestResolution)
                        if let image = image {
                            windowImages.append(NSImage(cgImage: image, size: .zero))
                            print("WindowManager: Captured image for window ID: \(windowID)")
                        } else {
                            print("WindowManager: Failed to capture image for window ID: \(windowID)")
                        }
                    } else {
                        print("WindowManager: Could not get window ID.")
                    }
                }
            }
        }

        return windowImages
    }
}
