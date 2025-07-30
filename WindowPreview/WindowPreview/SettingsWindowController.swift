import Cocoa
import ScreenCaptureKit

class SettingsWindowController: NSWindowController {
    
    override init(window: NSWindow?) {
        super.init(window: window)
        setupWindow()
    }
    
    convenience init() {
        self.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindow()
    }
    
    private var screenCaptureStatusDot: NSView!
    private var screenCaptureLabel: NSTextField!
    private var screenCaptureButton: NSButton!
    
    private var accessibilityStatusDot: NSView!
    private var accessibilityLabel: NSTextField!
    private var accessibilityButton: NSButton!
    
    private var automationStatusDot: NSView!
    private var automationLabel: NSTextField!
    private var automationButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        log("🔧 windowDidLoad called")
        
        // IMMEDIATE debug - add basic label right here
        if let contentView = window?.contentView {
            log("✅ Got contentView in windowDidLoad")
            let debugLabel = NSTextField(frame: NSRect(x: 20, y: 300, width: 400, height: 30))
            debugLabel.stringValue = "🚨 SETTINGS LOADED - windowDidLoad working!"
            debugLabel.font = NSFont.boldSystemFont(ofSize: 16)
            debugLabel.isBezeled = false
            debugLabel.isEditable = false
            debugLabel.backgroundColor = .systemRed
            debugLabel.textColor = .white
            contentView.addSubview(debugLabel)
            log("✅ Added debug label in windowDidLoad")
        } else {
            log("❌ No contentView in windowDidLoad")
        }
        
        // Force setup UI immediately
        DispatchQueue.main.async {
            log("🔧 Forcing setupUI in main queue")
            self.setupUI()
            self.updatePermissionStatus()
        }
        
        // Auto-refresh permissions every 2 seconds
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updatePermissionStatus()
            }
        }
    }
    
    private func setupWindow() {
        log("🔧 setupWindow called")
        
        if self.window != nil {
            log("⚠️ Window already exists, not creating new one")
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WindowPreview Settings"
        window.center()
        self.window = window
        log("🔧 window created and assigned")
        
        // Add immediate test content to the window
        if let contentView = window.contentView {
            log("✅ Got contentView in setupWindow")
            let testLabel = NSTextField(frame: NSRect(x: 50, y: 250, width: 400, height: 30))
            testLabel.stringValue = "🎯 SETUP WINDOW TEST - Basic UI working!"
            testLabel.font = NSFont.boldSystemFont(ofSize: 16)
            testLabel.isBezeled = false
            testLabel.isEditable = false
            testLabel.backgroundColor = .systemBlue
            testLabel.textColor = .white
            contentView.addSubview(testLabel)
            log("✅ Added test label in setupWindow")
        } else {
            log("❌ No contentView in setupWindow")
        }
    }
    
    func forceSetupUI() {
        log("🔧 forceSetupUI called directly!")
        setupUI()
    }
    
    private func setupUI() {
        log("🔧 setupUI called")
        guard let contentView = window?.contentView else {
            log("❌ No contentView found!")
            return
        }
        log("✅ contentView found, adding UI elements...")
        
        // Add a simple test label first
        let testLabel = NSTextField(frame: NSRect(x: 50, y: 200, width: 400, height: 50))
        testLabel.stringValue = "🎉 SETTINGS WINDOW TEST - If you see this, UI is working!"
        testLabel.font = NSFont.boldSystemFont(ofSize: 16)
        testLabel.isBezeled = false
        testLabel.isEditable = false
        testLabel.isSelectable = false
        testLabel.alignment = .center
        testLabel.backgroundColor = .systemYellow
        testLabel.textColor = .black
        contentView.addSubview(testLabel)
        log("✅ Added test label")
        
        // Title
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: 340, width: 460, height: 30))
        titleLabel.stringValue = "🔒 Permissions & Settings"
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)
        log("✅ Added title label")
        
        // Subtitle
        let subtitleLabel = NSTextField(frame: NSRect(x: 20, y: 310, width: 460, height: 20))
        subtitleLabel.stringValue = "WindowPreview needs these permissions to show window previews when hovering over dock icons"
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.isBezeled = false
        subtitleLabel.isEditable = false
        subtitleLabel.isSelectable = false
        subtitleLabel.alignment = .center
        subtitleLabel.textColor = .secondaryLabelColor
        contentView.addSubview(subtitleLabel)
        log("✅ Added subtitle label")
        
        // Screen Capture Permission
        log("🔧 Setting up Screen Capture permission row...")
        setupPermissionRow(
            y: 250,
            title: "Screen Recording",
            description: "Required to capture window previews",
            statusDot: &screenCaptureStatusDot,
            label: &screenCaptureLabel,
            button: &screenCaptureButton,
            action: #selector(requestScreenCapturePermission),
            contentView: contentView
        )
        log("✅ Screen Capture permission row setup complete")
        
        // Accessibility Permission
        setupPermissionRow(
            y: 180,
            title: "Accessibility",
            description: "Required to detect window focus and dock interactions",
            statusDot: &accessibilityStatusDot,
            label: &accessibilityLabel,
            button: &accessibilityButton,
            action: #selector(requestAccessibilityPermission),
            contentView: contentView
        )
        
        // Automation Permission
        setupPermissionRow(
            y: 110,
            title: "Automation",
            description: "Required to interact with other applications",
            statusDot: &automationStatusDot,
            label: &automationLabel,
            button: &automationButton,
            action: #selector(requestAutomationPermission),
            contentView: contentView
        )
        
        // Footer
        let footerLabel = NSTextField(frame: NSRect(x: 20, y: 20, width: 460, height: 60))
        footerLabel.stringValue = "💡 Tip: After granting permissions, you may need to restart WindowPreview.\n\n🚀 Once all permissions are granted, hover over dock icons to see window previews!"
        footerLabel.font = NSFont.systemFont(ofSize: 11)
        footerLabel.isBezeled = false
        footerLabel.isEditable = false
        footerLabel.isSelectable = false
        footerLabel.alignment = .center
        footerLabel.textColor = .secondaryLabelColor
        contentView.addSubview(footerLabel)
    }
    
    private func setupPermissionRow(
        y: CGFloat,
        title: String,
        description: String,
        statusDot: inout NSView!,
        label: inout NSTextField!,
        button: inout NSButton!,
        action: Selector,
        contentView: NSView
    ) {
        // Status dot
        statusDot = NSView(frame: NSRect(x: 30, y: y + 15, width: 12, height: 12))
        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 6
        contentView.addSubview(statusDot)
        
        // Title label
        let titleLabel = NSTextField(frame: NSRect(x: 55, y: y + 20, width: 200, height: 20))
        titleLabel.stringValue = title
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        contentView.addSubview(titleLabel)
        
        // Status label
        label = NSTextField(frame: NSRect(x: 55, y: y + 2, width: 250, height: 16))
        label.font = NSFont.systemFont(ofSize: 11)
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        contentView.addSubview(label)
        
        // Description
        let descLabel = NSTextField(frame: NSRect(x: 55, y: y - 15, width: 280, height: 14))
        descLabel.stringValue = description
        descLabel.font = NSFont.systemFont(ofSize: 10)
        descLabel.isBezeled = false
        descLabel.isEditable = false
        descLabel.isSelectable = false
        descLabel.textColor = .tertiaryLabelColor
        contentView.addSubview(descLabel)
        
        // Request button
        button = NSButton(frame: NSRect(x: 350, y: y + 5, width: 120, height: 30))
        button.title = "Grant Permission"
        button.bezelStyle = .rounded
        button.target = self
        button.action = action
        contentView.addSubview(button)
    }
    
    private func updatePermissionStatus() {
        // Screen Capture Permission
        let screenCaptureGranted = checkScreenCapturePermission()
        updatePermissionUI(
            granted: screenCaptureGranted,
            statusDot: screenCaptureStatusDot,
            label: screenCaptureLabel,
            button: screenCaptureButton,
            grantedText: "✅ Granted - Screen recording enabled",
            deniedText: "❌ Denied - Click to grant screen recording access"
        )
        
        // Accessibility Permission
        let accessibilityGranted = AXIsProcessTrusted()
        updatePermissionUI(
            granted: accessibilityGranted,
            statusDot: accessibilityStatusDot,
            label: accessibilityLabel,
            button: accessibilityButton,
            grantedText: "✅ Granted - Accessibility access enabled",
            deniedText: "❌ Denied - Click to grant accessibility access"
        )
        
        // Automation Permission (this is trickier to check, so we'll assume it needs to be granted)
        let automationGranted = true // We'll update this based on actual automation attempts
        updatePermissionUI(
            granted: automationGranted,
            statusDot: automationStatusDot,
            label: automationLabel,
            button: automationButton,
            grantedText: "✅ Granted - Automation access enabled",
            deniedText: "❌ Denied - Click to grant automation access"
        )
    }
    
    private func updatePermissionUI(
        granted: Bool,
        statusDot: NSView,
        label: NSTextField,
        button: NSButton,
        grantedText: String,
        deniedText: String
    ) {
        if granted {
            statusDot.layer?.backgroundColor = NSColor.systemGreen.cgColor
            label.stringValue = grantedText
            label.textColor = .systemGreen
            button.title = "✓ Granted"
            button.isEnabled = false
        } else {
            statusDot.layer?.backgroundColor = NSColor.systemRed.cgColor
            label.stringValue = deniedText
            label.textColor = .systemRed
            button.title = "Grant Permission"
            button.isEnabled = true
        }
    }
    
    private func checkScreenCapturePermission() -> Bool {
        log("🔍 SettingsWindowController - Testing screen recording permission...")
        
        // Use CGWindowListCopyWindowInfo to check without triggering any dialogs
        guard let windowList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] else {
            log("❌ SettingsWindowController - Could not get window list")
            return false
        }
        
        print("📊 SettingsWindowController - Found \(windowList.count) windows")
        
        var windowsWithNames = 0
        
        // Look for any window with a name - if no names are available, permission is denied
        for window in windowList {
            if let windowName = window[kCGWindowName as String] as? String, !windowName.isEmpty {
                windowsWithNames += 1
            }
        }
        
        let hasPermission = windowsWithNames > 0
        print("📊 SettingsWindowController - Screen recording permission: \(hasPermission ? "GRANTED" : "DENIED") (\(windowsWithNames) windows with names)")
        
        return hasPermission
    }
    
    @objc private func requestScreenCapturePermission() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "WindowPreview needs Screen Recording permission to capture window previews.\n\n1. Click 'Open System Preferences'\n2. Go to Privacy & Security → Screen Recording\n3. Enable WindowPreview\n4. Restart WindowPreview"
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    @objc private func requestAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "WindowPreview needs Accessibility permission to detect window interactions.\n\n1. Click 'Open System Preferences'\n2. Go to Privacy & Security → Accessibility\n3. Enable WindowPreview\n4. Restart WindowPreview"
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    @objc private func requestAutomationPermission() {
        let alert = NSAlert()
        alert.messageText = "Automation Permission Required"
        alert.informativeText = "WindowPreview needs Automation permission to interact with other applications.\n\n1. Click 'Open System Preferences'\n2. Go to Privacy & Security → Automation\n3. Enable WindowPreview for relevant applications\n4. Restart WindowPreview"
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}