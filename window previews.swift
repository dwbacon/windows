import Cocoa
import CoreGraphics
import ScreenCaptureKit
import QuartzCore

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem!
    var dockPreviewManager: DockPreviewManager!
    var settingsWindow: SettingsWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("=== DockPreview Starting ===")
        
        // CRITICAL: Set activation policy FIRST before anything else
        NSApp.setActivationPolicy(.accessory)
        
        // Hide from dock completely
        if let bundleId = Bundle.main.bundleIdentifier {
            let runningApp = NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == bundleId }
            runningApp?.hide()
        }
        
        setupMenuBarItem()
        checkAndRequestPermissions()
        
        // Initialize preview manager
        dockPreviewManager = DockPreviewManager()
        dockPreviewManager.startMonitoring()
        
        print("=== DockPreview Started Successfully ===")
    }
    
    func setupMenuBarItem() {
        // Create status item with fixed width
        statusItem = NSStatusBar.system.statusItem(withLength: 30)
        
        guard let button = statusItem.button else {
            print("ERROR: Could not create status bar button")
            return
        }
        
        // Set button properties
        button.title = "👁"
        button.toolTip = "DockPreview - Window Previews"
        button.target = self
        
        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Enable Previews", action: #selector(togglePreviews), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Test Preview", action: #selector(testPreview), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit DockPreview", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
        print("Menu bar item created successfully")
    }
    
    @objc func togglePreviews() {
        Settings.shared.enabled.toggle()
        updateMenuTitle()
        print("Previews toggled: \(Settings.shared.enabled)")
    }
    
    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        settingsWindow!.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func testPreview() {
        print("Testing preview...")
        dockPreviewManager.testPreview()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func updateMenuTitle() {
        guard let menu = statusItem.menu else { return }
        menu.items[0].title = Settings.shared.enabled ? "Disable Previews" : "Enable Previews"
    }
    
    func checkAndRequestPermissions() {
        // Screen Recording
        let hasScreenAccess = CGPreflightScreenCaptureAccess()
        print("Screen recording access: \(hasScreenAccess)")
        
        if !hasScreenAccess {
            CGRequestScreenCaptureAccess()
        }
        
        // Accessibility
        let hasAccessibility = AXIsProcessTrusted()
        print("Accessibility access: \(hasAccessibility)")
        
        if !hasAccessibility {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
    }
}

// MARK: - Settings
class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var enabled: Bool = true {
        didSet { save() }
    }
    
    @Published var animationSpeed: Double = 0.3 {
        didSet { save() }
    }
    
    @Published var previewSize: PreviewSize = .medium {
        didSet { save() }
    }
    
    enum PreviewSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        var dimensions: CGSize {
            switch self {
            case .small: return CGSize(width: 200, height: 125)
            case .medium: return CGSize(width: 300, height: 200)
            case .large: return CGSize(width: 400, height: 250)
            }
        }
    }
    
    private init() {
        load()
    }
    
    private func save() {
        UserDefaults.standard.set(enabled, forKey: "enabled")
        UserDefaults.standard.set(animationSpeed, forKey: "animationSpeed")
        UserDefaults.standard.set(previewSize.rawValue, forKey: "previewSize")
    }
    
    private func load() {
        enabled = UserDefaults.standard.object(forKey: "enabled") as? Bool ?? true
        animationSpeed = UserDefaults.standard.object(forKey: "animationSpeed") as? Double ?? 0.3
        if let sizeString = UserDefaults.standard.string(forKey: "previewSize"),
           let size = PreviewSize(rawValue: sizeString) {
            previewSize = size
        }
    }
}

// MARK: - Settings Window
class SettingsWindowController: NSWindowController {
    
    override init(window: NSWindow?) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "DockPreview Settings"
        window.center()
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Enable checkbox
        let enableCheckbox = NSButton(checkboxWithTitle: "Enable Window Previews", target: self, action: #selector(enableToggled))
        enableCheckbox.state = Settings.shared.enabled ? .on : .off
        
        // Animation speed
        let speedLabel = NSTextField(labelWithString: "Animation Speed:")
        let speedSlider = NSSlider()
        speedSlider.minValue = 0.1
        speedSlider.maxValue = 1.0
        speedSlider.doubleValue = Settings.shared.animationSpeed
        speedSlider.target = self
        speedSlider.action = #selector(speedChanged)
        
        // Preview size
        let sizeLabel = NSTextField(labelWithString: "Preview Size:")
        let sizePopup = NSPopUpButton()
        Settings.PreviewSize.allCases.forEach { size in
            sizePopup.addItem(withTitle: size.rawValue)
        }
        sizePopup.selectItem(withTitle: Settings.shared.previewSize.rawValue)
        sizePopup.target = self
        sizePopup.action = #selector(sizeChanged)
        
        stackView.addArrangedSubview(enableCheckbox)
        stackView.addArrangedSubview(speedLabel)
        stackView.addArrangedSubview(speedSlider)
        stackView.addArrangedSubview(sizeLabel)
        stackView.addArrangedSubview(sizePopup)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    @objc private func enableToggled(_ sender: NSButton) {
        Settings.shared.enabled = sender.state == .on
    }
    
    @objc private func speedChanged(_ sender: NSSlider) {
        Settings.shared.animationSpeed = sender.doubleValue
    }
    
    @objc private func sizeChanged(_ sender: NSPopUpButton) {
        if let title = sender.selectedItem?.title,
           let size = Settings.PreviewSize(rawValue: title) {
            Settings.shared.previewSize = size
        }
    }
}

// MARK: - Preview Manager
class DockPreviewManager {
    private var mouseTracker: Any?
    private var previewWindows: [PreviewWindow] = []
    private var lastMouseLocation: NSPoint = .zero
    private var screenRecorder: ScreenRecorder?
    
    init() {
        if #available(macOS 12.3, *) {
            screenRecorder = ScreenRecorder()
        }
    }
    
    func startMonitoring() {
        stopMonitoring() // Clean up any existing tracking
        
        mouseTracker = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            guard Settings.shared.enabled else { return }
            self?.handleMouseMove(event.locationInWindow)
        }
        
        print("Mouse tracking started")
    }
    
    func stopMonitoring() {
        if let tracker = mouseTracker {
            NSEvent.removeMonitor(tracker)
            mouseTracker = nil
        }
        hideAllPreviews()
    }
    
    private func handleMouseMove(_ location: NSPoint) {
        let mouseLocation = NSEvent.mouseLocation
        lastMouseLocation = mouseLocation
        
        if isInDockArea(mouseLocation) {
            showPreviews()
        } else {
            hideAllPreviews()
        }
    }
    
    private func isInDockArea(_ point: NSPoint) -> Bool {
        guard let screen = NSScreen.main else { return false }
        
        // Bottom 150 pixels of screen
        let dockArea = NSRect(x: 0, y: 0, width: screen.frame.width, height: 150)
        return dockArea.contains(point)
    }
    
    private func showPreviews() {
        guard previewWindows.isEmpty else { return } // Already showing
        
        let apps = getVisibleApps()
        guard !apps.isEmpty else { return }
        
        print("Showing previews for \(apps.count) apps")
        
        let maxPreviews = min(apps.count, 6)
        let previewSize = Settings.shared.previewSize.dimensions
        let spacing: CGFloat = 10
        let totalWidth = CGFloat(maxPreviews) * previewSize.width + CGFloat(maxPreviews - 1) * spacing
        
        guard let screen = NSScreen.main else { return }
        let startX = (screen.frame.width - totalWidth) / 2
        let y: CGFloat = 200 // Above dock
        
        for (index, app) in apps.prefix(maxPreviews).enumerated() {
            let x = startX + CGFloat(index) * (previewSize.width + spacing)
            let frame = NSRect(x: x, y: y, width: previewSize.width, height: previewSize.height)
            
            let preview = PreviewWindow(app: app, frame: frame, screenRecorder: screenRecorder)
            previewWindows.append(preview)
            preview.show()
        }
    }
    
    private func hideAllPreviews() {
        guard !previewWindows.isEmpty else { return }
        
        previewWindows.forEach { $0.hide() }
        previewWindows.removeAll()
    }
    
    private func getVisibleApps() -> [AppInfo] {
        let workspace = NSWorkspace.shared
        return workspace.runningApplications.compactMap { app in
            guard let bundleId = app.bundleIdentifier,
                  app.activationPolicy == .regular,
                  !app.isHidden,
                  bundleId != Bundle.main.bundleIdentifier else {
                return nil
            }
            
            return AppInfo(
                name: app.localizedName ?? "Unknown",
                bundleId: bundleId,
                processId: app.processIdentifier
            )
        }
    }
    
    func testPreview() {
        hideAllPreviews()
        
        // Force show previews at center bottom
        if let screen = NSScreen.main {
            lastMouseLocation = NSPoint(x: screen.frame.width / 2, y: 50)
            showPreviews()
            
            // Auto-hide after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.hideAllPreviews()
            }
        }
    }
}

// MARK: - App Info
struct AppInfo: Sendable {
    let name: String
    let bundleId: String
    let processId: pid_t
}

// MARK: - Preview Window
class PreviewWindow: NSWindow {
    private let app: AppInfo
    private let screenRecorder: ScreenRecorder?
    private var imageView: NSImageView!
    private var titleLabel: NSTextField!
    
    init(app: AppInfo, frame: NSRect, screenRecorder: ScreenRecorder?) {
        self.app = app
        self.screenRecorder = screenRecorder
        
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupContent()
        captureWindow()
    }
    
    private func setupWindow() {
        level = .floating
        backgroundColor = NSColor.black.withAlphaComponent(0.9)
        isOpaque = false
        hasShadow = true
        ignoresMouseEvents = false
    }
    
    private func setupContent() {
        guard let contentView = contentView else { return }
        
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 8
        
        // Title label
        titleLabel = NSTextField(labelWithString: app.name)
        titleLabel.textColor = .white
        titleLabel.backgroundColor = .clear
        titleLabel.isBordered = false
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Image view
        imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.darkGray.cgColor
        imageView.layer?.cornerRadius = 4
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            titleLabel.heightAnchor.constraint(equalToConstant: 16),
            
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -8)
        ])
        
        // Click handling
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        contentView.addGestureRecognizer(clickGesture)
    }
    
    @objc private func handleClick() {
        // Activate the clicked app
        let runningApps = NSWorkspace.shared.runningApplications
        if let targetApp = runningApps.first(where: { $0.processIdentifier == app.processId }) {
            targetApp.activate(options: [.activateAllWindows])
        }
        
        // Animate out
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Settings.shared.animationSpeed
            animator().alphaValue = 0
        } completionHandler: {
            self.orderOut(nil)
        }
    }
    
    private func captureWindow() {
        // Set placeholder first
        setPlaceholderImage()
        
        if #available(macOS 12.3, *), let recorder = screenRecorder {
            Task {
                let image = await recorder.captureWindow(for: app)
                DispatchQueue.main.async { [weak self] in
                    if let image = image {
                        self?.imageView.image = image
                    }
                }
            }
        }
    }
    
    private func setPlaceholderImage() {
        let size = NSSize(width: 64, height: 64)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.systemGray.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        imageView.image = image
    }
    
    func show() {
        alphaValue = 0
        orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Settings.shared.animationSpeed
            animator().alphaValue = 1
        }
    }
    
    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Settings.shared.animationSpeed
            animator().alphaValue = 0
        } completionHandler: {
            self.orderOut(nil)
        }
    }
}

// MARK: - Screen Recorder
@available(macOS 12.3, *)
class ScreenRecorder: Sendable {
    
    func captureWindow(for app: AppInfo) async -> NSImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            let appWindows = content.windows.filter { window in
                window.owningApplication?.processID == app.processId
            }
            
            guard let targetWindow = appWindows.first else {
                print("No window found for \(app.name)")
                return nil
            }
            
            let filter = SCContentFilter(desktopIndependentWindow: targetWindow)
            let config = SCStreamConfiguration()
            config.width = 400
            config.height = 300
            config.capturesAudio = false
            config.showsCursor = false
            
            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            return NSImage(cgImage: cgImage, size: NSSize(width: 400, height: 300))
            
        } catch {
            print("Screen capture failed for \(app.name): \(error)")
            return nil
        }
    }
}
