
import Cocoa
import ScreenCaptureKit

struct WindowInfo {
    let windowId: CGWindowID
    let title: String
    let frame: CGRect
    let appName: String
    let appPID: Int
}

@available(macOS 12.3, *)
class WindowCapture {

    static func captureWindow(windowId: CGWindowID) async -> NSImage? {
        // Prefer the more reliable CGWindowList capture API
        if let image = captureWindowCG(windowId: windowId) {
            return image
        }

        // Fallback to ScreenCaptureKit if CGWindowList fails
        do {
            let content = try await SCShareableContent.current
            guard let window = content.windows.first(where: { $0.windowID == windowId }) else {
                log("Error: Window with ID \(windowId) not found in shareable content during fallback.")
                return nil
            }

            let filter = SCContentFilter(desktopIndependentWindow: window)
            let config = SCStreamConfiguration()
            config.width = Int(window.frame.width)
            config.height = Int(window.frame.height)
            config.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            log("Successfully captured window \(windowId) with ScreenCaptureKit fallback")
            return NSImage(cgImage: image, size: .zero)

        } catch {
            log("Error capturing window with ScreenCaptureKit fallback: \(error.localizedDescription)")
            return nil
        }
    }

    private static func captureWindowCG(windowId: CGWindowID) -> NSImage? {
        let image = CGWindowListCreateImage(.null, .optionIncludingWindow, windowId, [.boundsIgnoreFraming, .bestResolution])
        if let cgImg = image {
            log("Successfully captured window \(windowId) with CGWindowListCreateImage")
            return NSImage(cgImage: cgImg, size: .zero)
        }
        log("Failed to capture window \(windowId) with CGWindowListCreateImage")
        return nil
    }

    static func getApplicationWindows(for app: NSRunningApplication) async -> [WindowInfo] {
        guard let appName = app.localizedName else {
            log("❌ No app name for PID \(app.processIdentifier)")
            return []
        }
        let pid = app.processIdentifier

        // Use the CGWindowList API first as it's more reliable
        let cgWindows = getApplicationWindowsCG(for: app)
        if !cgWindows.isEmpty {
            return cgWindows
        }

        // Fallback to ScreenCaptureKit window enumeration
        do {
            let content = try await SCShareableContent.current
            log("🔍 WindowCapture fallback: Found \(content.windows.count) total windows")
            log("🎯 WindowCapture fallback: Looking for \(appName) with PID \(pid)")

            let windowInfos = content.windows.compactMap { window -> WindowInfo? in
                let windowPID = window.owningApplication?.processID ?? -1
                guard windowPID == pid else { return nil }

                guard shouldIncludeWindow(window, forApp: app) else { return nil }

                let windowTitle = window.title ?? ""
                let windowID = window.windowID
                let windowFrame = window.frame

                log("✅ ACCEPTED fallback: '\(windowTitle)' (ID:\(windowID), \(Int(windowFrame.width))x\(Int(windowFrame.height))) from \(appName)")

                return WindowInfo(
                    windowId: windowID,
                    title: windowTitle,
                    frame: windowFrame,
                    appName: appName,
                    appPID: Int(pid)
                )
            }

            let sortedWindows = windowInfos.sorted { $0.frame.width * $0.frame.height > $1.frame.width * $1.frame.height }
            return sortedWindows

        } catch {
            log("❌ Error getting shareable content fallback: \(error.localizedDescription)")
            return []
        }
    }

    private static func getApplicationWindowsCG(for app: NSRunningApplication) -> [WindowInfo] {
        guard let appName = app.localizedName else { return [] }
        let pid = app.processIdentifier

        guard let infoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var result: [WindowInfo] = []
        for info in infoList {
            let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t ?? 0
            if ownerPID != pid { continue }

            let windowID = info[kCGWindowNumber as String] as? CGWindowID ?? 0
            let boundsDict = info[kCGWindowBounds as String] as? [String: Any] ?? [:]
            let frame = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) ?? .zero
            let title = info[kCGWindowName as String] as? String ?? ""

            result.append(WindowInfo(windowId: windowID, title: title, frame: frame, appName: appName, appPID: Int(pid)))
        }
        return result.sorted { $0.frame.width * $0.frame.height > $1.frame.width * $1.frame.height }
    }

    private static func shouldIncludeWindow(_ window: SCWindow, forApp app: NSRunningApplication) -> Bool {
        let windowTitle = window.title ?? ""
        let windowWidth = window.frame.width
        let windowHeight = window.frame.height
        let windowLayer = window.windowLayer
        let appName = app.localizedName ?? "Unknown App"

        log("🔬 Examining window: '\(windowTitle)' (ID:\(window.windowID), \(Int(windowWidth))x\(Int(windowHeight))) Layer: \(windowLayer) for app \(appName)")

        // 1. Check for minimum size
        let minWidth: CGFloat = 50
        let minHeight: CGFloat = 50
        guard windowWidth >= minWidth && windowHeight >= minHeight else {
            log("❌ REJECTED: '\(windowTitle)' (ID:\(window.windowID)) - too small (\(Int(windowWidth))x\(Int(window.frame.height)))")
            return false
        }

        // 2. Check visibility
        guard window.isOnScreen else {
            log("❌ REJECTED: '\(windowTitle)' (ID:\(window.windowID)) - not on screen")
            return false
        }
        
        // 3. Filter out problematic window layers
        // Layer 0 is normal application windows. Layer 1 can be some utility windows.
        // Other layers often include overlays, popups, tooltips, etc.
        guard windowLayer == 0 || windowLayer == 1 else {
            log("❌ REJECTED: '\(windowTitle)' (ID:\(window.windowID)) - unacceptable layer (\(windowLayer))")
            return false
        }

        // 4. Filter out known problematic window titles/types
        let lowercasedTitle = windowTitle.lowercased()
        let excludedTitles = [
            "item-", "menu", "popup", "tooltip", "notification",
            "axsystemdialog", "statusindicator", "dock", "menubar",
            "spotlight", "siri", "control center", "mission control",
            "app switcher", "dashboard", "loginwindow", "screencapture"
        ]
        
        for excluded in excludedTitles {
            if lowercasedTitle.contains(excluded) {
                log("❌ REJECTED: '\(windowTitle)' (ID:\(window.windowID)) - bad title (contains '\(excluded)')")
                return false
            }
        }
        
        // 5. Exclude windows that are clearly not main application windows (e.g., empty title but large size)
        // This is a heuristic and might need adjustment.
        if windowTitle.isEmpty && (windowWidth > 1000 || windowHeight > 800) {
             log("❌ REJECTED: '\(windowTitle)' (ID:\(window.windowID)) - large window with empty title (likely background/system)")
             return false
        }

        return true
    }
    
    static func createPlaceholderImage(text: String) -> NSImage {
        let size = NSSize(width: 300, height: 200)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Gradient background
        let gradient = NSGradient(colors: [
            NSColor.controlBackgroundColor.withAlphaComponent(0.9),
            NSColor.controlBackgroundColor.withAlphaComponent(0.7)
        ])
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        // Border with rounded corners effect
        NSColor.separatorColor.withAlphaComponent(0.5).setStroke()
        let borderRect = NSRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
        let path = NSBezierPath(rect: borderRect)
        path.lineWidth = 2
        path.stroke()
        
        // Icon placeholder (window symbol)
        let iconSize: CGFloat = 40
        let iconRect = NSRect(
            x: (size.width - iconSize) / 2,
            y: (size.height - iconSize) / 2 + 20,
            width: iconSize,
            height: iconSize
        )
        
        NSColor.tertiaryLabelColor.setStroke()
        let iconPath = NSBezierPath(rect: iconRect.insetBy(dx: 4, dy: 4))
        iconPath.lineWidth = 2
        iconPath.stroke()
        
        // Inner window lines
        let line1 = NSBezierPath()
        line1.move(to: NSPoint(x: iconRect.minX + 8, y: iconRect.maxY - 8))
        line1.line(to: NSPoint(x: iconRect.maxX - 8, y: iconRect.maxY - 8))
        line1.stroke()
        
        let line2 = NSBezierPath()
        line2.move(to: NSPoint(x: iconRect.minX + 8, y: iconRect.maxY - 14))
        line2.line(to: NSPoint(x: iconRect.maxX - 8, y: iconRect.maxY - 14))
        line2.stroke()
        
        // Text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textRect = NSRect(x: 10, y: (size.height / 2) - 40, width: size.width - 20, height: 60)
        attributedString.draw(in: textRect)
        
        // Subtle "No Preview" indicator
        let subtext = "Preview unavailable"
        let subtextAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
        
        let subtextString = NSAttributedString(string: subtext, attributes: subtextAttributes)
        let subtextSize = subtextString.size()
        let subtextRect = NSRect(
            x: (size.width - subtextSize.width) / 2,
            y: 15,
            width: subtextSize.width,
            height: subtextSize.height
        )
        
        subtextString.draw(in: subtextRect)
        
        image.unlockFocus()
        return image
    }
}