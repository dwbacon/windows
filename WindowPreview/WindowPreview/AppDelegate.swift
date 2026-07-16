import Cocoa
import SwiftUI
import ScreenCaptureKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var dockHoverDetector: DockHoverDetector?
    private var windowPreviewManager: WindowPreviewManager?
    private var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        log("🚀 APPDELEGATE applicationDidFinishLaunching CALLED!")
        do {
            try setupEverything()
        } catch {
            log("❌ Error during setupEverything: \(error.localizedDescription)")
            let alert = NSAlert()
            alert.messageText = "Application Error"
            alert.informativeText = "WindowPreview encountered an error during startup: \(error.localizedDescription). Please check the debug log for more details."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            NSApp.terminate(self)
        }
    }
    
    @MainActor
    func setupEverything() throws { // Mark as throws
        log("🚀 SETUP - WindowPreview AppDelegate running...")
        
        do {
            setupStatusBar()
            log("✅ Status bar setup complete.")
        } catch {
            log("❌ Error setting up status bar: \(error.localizedDescription)")
            throw error // Re-throw to be caught by applicationDidFinishLaunching
        }
        
        do {
            setupDockHoverDetection()
            log("✅ Dock hover detection setup complete.")
        } catch {
            log("❌ Error setting up dock hover detection: \(error.localizedDescription)")
            throw error // Re-throw
        }
        
        log("✅ SETUP COMPLETE!")
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "WP"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Debug Info...", action: #selector(showDebugInfo), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit WindowPreview", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func showDebugInfo() {
        log("🔧 showDebugInfo called!")
        let debugWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        debugWindow.center()
        debugWindow.title = "WindowPreview Debug Info"

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 660, height: 520))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        
        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.string = collectDebugInfo()
        
        scrollView.documentView = textView
        debugWindow.contentView?.addSubview(scrollView)
        
        // Copy All button
        let copyButton = NSButton(title: "Copy All", target: self, action: #selector(copyDebugInfoToClipboard))
        copyButton.frame = NSRect(x: 20, y: 20, width: 100, height: 32)
        copyButton.bezelStyle = .rounded
        copyButton.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        copyButton.layer?.borderColor = NSColor.separatorColor.cgColor
        copyButton.layer?.borderWidth = 1
        copyButton.layer?.cornerRadius = 6
        copyButton.wantsLayer = true
        debugWindow.contentView?.addSubview(copyButton)
        
        
        debugWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController = NSWindowController(window: debugWindow)
    }
    
    @objc func copyDebugInfoToClipboard(_ sender: NSButton) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(collectDebugInfo(), forType: .string)
        
        let originalTitle = sender.title
        sender.title = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            sender.title = originalTitle
        }
    }
    

    func collectDebugInfo() -> String {
        var info = "WindowPreview Debug Information\n"
        info += "Generated: \(Date())\n"
        info += "================================\n\n"
        
        // App info
        info += "APP INFO:\n"
        info += "Bundle ID: \(Bundle.main.bundleIdentifier ?? "N/A")\n"
        info += "Bundle Path: \(Bundle.main.bundlePath)\n"
        info += "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A")\n"
        info += "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A")\n"
        info += "Product Name: \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "N/A")\n"
        info += "Is Debug Build: \(_isDebugAssertConfiguration())\n\n"
        
        // Permissions
        info += "PERMISSIONS:\n"
        info += "Screen Recording: \(isScreenRecordingEnabled() ? "Granted" : "Denied")\n"
        info += "Accessibility: \(AXIsProcessTrusted() ? "Granted" : "Denied")\n"
        
        // Test CGPreflightScreenCaptureAccess
        if #available(macOS 10.15, *) {
            let preflightResult = CGPreflightScreenCaptureAccess()
            info += "CGPreflightScreenCaptureAccess: \(preflightResult)\n"
        }
        
        // Test window list access
        if let windowList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] {
            var windowsWithNames = 0
            let totalWindows = windowList.count
            for window in windowList {
                let windowName = window[kCGWindowName as String] as? String ?? ""
                if !windowName.isEmpty {
                    windowsWithNames += 1
                }
            }
            info += "Window names available: \(windowsWithNames)/\(totalWindows)\n"
        }
        info += "\n"
        
        // System info
        info += "SYSTEM INFO:\n"
        let processInfo = ProcessInfo.processInfo
        info += "macOS Version: \(processInfo.operatingSystemVersionString)\n"
        info += "Host Name: \(processInfo.hostName)\n"
        info += "Process Name: \(processInfo.processName)\n"
        info += "Process ID: \(processInfo.processIdentifier)\n"
        
        // Display info
        if let mainScreen = NSScreen.main {
            info += "Main Screen Frame: \(mainScreen.frame)\n"
            info += "Main Screen Visible Frame: \(mainScreen.visibleFrame)\n"
        }
        info += "All Screens: \(NSScreen.screens.count)\n\n"
        
        // Running applications (first 10)
        let runningApps = NSWorkspace.shared.runningApplications
        info += "RUNNING APPLICATIONS (\(runningApps.count) total):\n"
        for app in runningApps.prefix(10) {
            info += "- \(app.localizedName ?? "Unknown") (PID: \(app.processIdentifier))\n"
        }
        if runningApps.count > 10 {
            info += "... and \(runningApps.count - 10) more\n"
        }
        info += "\n"
        
        info += "================================\n"
        info += "DEBUG LOG:\n"
        // Match the path used by Logger.swift
        let logPath = NSHomeDirectory() + "/Desktop/WindowPreview/logs/debug.log"
        if FileManager.default.fileExists(atPath: logPath) {
            do {
                let logContent = try String(contentsOfFile: logPath)
                let recentLines = String(logContent.suffix(3000)) // Last 3000 chars
                info += recentLines
            } catch {
                info += "Error reading log: \(error)\n"
            }
        } else {
            info += "No debug log found at \(logPath)\n"
        }
        
        return info
    }
    
    @objc func showSettings() {
        let settingsView = SettingsView(onRestart: { self.restartApplication() })
        let hostingController = NSHostingController(rootView: settingsView)
        
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.contentViewController = hostingController
        settingsWindow.title = "WindowPreview Settings"
        settingsWindow.center()
        settingsWindowController = NSWindowController(window: settingsWindow)
        settingsWindow.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func restartApplication() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        NSApp.terminate(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        log("App will terminate.")
        dockHoverDetector?.stopMonitoring()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    @MainActor
    func setupDockHoverDetection() {
        windowPreviewManager = WindowPreviewManager()
        dockHoverDetector = DockHoverDetector()
        dockHoverDetector?.delegate = windowPreviewManager
        dockHoverDetector?.startMonitoring()
    }
    
    private func isScreenRecordingEnabled() -> Bool {
        guard #available(macOS 10.15, *) else { return false }

        // Check using CGWindowList to avoid unreliable CGDisplayStream checks
        if let windowList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] {
            for window in windowList {
                if let name = window[kCGWindowName as String] as? String, !name.isEmpty {
                    return true
                }
            }
        }
        return false
    }
}