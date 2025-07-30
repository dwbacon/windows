
import Cocoa
import ScreenCaptureKit

@MainActor
class WindowPreviewManager: NSObject, DockHoverDetectorDelegate {
    private var previewWindows: [PreviewWindow] = []
    private var fullViewWindow: NSWindow?
    private var hoverTimer: Timer?
    private var fullViewTimer: Timer?

    func dockIconHovered(for app: NSRunningApplication) {
        log("Dock icon hovered for: \(app.localizedName ?? "Unknown App")")
        hideAllPreviews()

        Task {
            log("🔍 CALLING WindowCapture.getApplicationWindows for \(app.localizedName ?? "Unknown") with PID \(app.processIdentifier)")
            let windows = await WindowCapture.getApplicationWindows(for: app)
            log("🔍 RECEIVED \(windows.count) windows from WindowCapture.getApplicationWindows")
            
            if !windows.isEmpty {
                log("Showing previews for \(windows.count) windows.")
                await showPreviews(for: windows, app: app)
            } else {
                log("No windows found for app \(app.localizedName ?? "Unknown App") to show previews for.")
            }
        }
    }

    func dockIconExited() {
        log("Dock icon exited.")
        
        do {
            log("🚪 Calling hideAllPreviews from dockIconExited.")
            hideAllPreviews()
            log("✅ hideAllPreviews completed from dockIconExited.")
            
            log("🚪 Calling hideFullView from dockIconExited.")
            hideFullView()
            log("✅ hideFullView completed from dockIconExited.")
            
            hoverTimer?.invalidate()
            hoverTimer = nil
            log("✅ hoverTimer invalidated.")
            
            fullViewTimer?.invalidate()
            fullViewTimer = nil
            log("✅ fullViewTimer invalidated.")
            
            log("✅ Dock exit cleanup completed")
        } catch {
            log("❌ Error in dockIconExited: \(error.localizedDescription)")
        }
    }

    private func showPreviews(for windows: [WindowInfo], app: NSRunningApplication) async {
        guard let mainScreen = NSScreen.main else {
            log("Error: No main screen available for preview display.")
            return
        }
        guard !windows.isEmpty else {
            log("No windows to preview for app: \(app.localizedName ?? "Unknown").")
            return
        }

        let maxPreviews = 3
        let windowsToShow = Array(windows.prefix(maxPreviews))

        let previewWidth: CGFloat = 300
        let previewHeight: CGFloat = 200
        let previewSpacing: CGFloat = 20
        let totalWidth = CGFloat(windowsToShow.count) * (previewWidth + previewSpacing) - previewSpacing
        let startX = (mainScreen.frame.width - totalWidth) / 2
        let previewY: CGFloat = 120 // Position above the dock

        for (index, windowInfo) in windowsToShow.enumerated() {
            let previewX = startX + CGFloat(index) * (previewWidth + previewSpacing)
            let previewFrame = NSRect(x: previewX, y: previewY, width: previewWidth, height: previewHeight)

            let image = await WindowCapture.captureWindow(windowId: windowInfo.windowId)
            let previewImage = image ?? WindowCapture.createPlaceholderImage(text: windowInfo.title)

            let previewWindow = PreviewWindow()
            previewWindow.show(image: previewImage, at: previewFrame, windowInfo: windowInfo)
            
            previewWindow.onHover = { [weak self] in
                log("🖱️ Preview hover detected for '\(windowInfo.title)'")
                guard let self = self else { 
                    log("❌ Self is nil in preview hover")
                    return 
                }
                
                if Thread.isMainThread {
                    self.showFullView(for: windowInfo, with: previewImage)
                } else {
                    DispatchQueue.main.async {
                        self.showFullView(for: windowInfo, with: previewImage)
                    }
                }
            }
            previewWindow.onUnhover = { [weak self] in
                log("🖱️ Preview unhover detected for '\(windowInfo.title)'")
                guard let self = self else { 
                    log("❌ Self is nil in preview unhover")
                    return 
                }
                
                if Thread.isMainThread {
                    self.hideFullView()
                } else {
                    DispatchQueue.main.async {
                        self.hideFullView()
                    }
                }
            }
            previewWindow.onClick = { [weak self] in
                log("🖱️ Preview click detected for '\(windowInfo.title)'")
                guard let self = self else { 
                    log("❌ Self is nil in preview click")
                    return 
                }
                
                if Thread.isMainThread {
                    self.showFullViewPermanent(for: windowInfo, with: previewImage)
                } else {
                    DispatchQueue.main.async {
                        self.showFullViewPermanent(for: windowInfo, with: previewImage)
                    }
                }
            }
            
            previewWindows.append(previewWindow)
        }
    }

    private func hideAllPreviews() {
        log("🚪 hideAllPreviews called. Hiding \(previewWindows.count) preview windows.")
        
        // Create a temporary array to iterate over, as `removeAll()` modifies the array during iteration
        let windowsToHide = previewWindows
        
        for (index, previewWindow) in windowsToHide.enumerated() {
            log("🚪 Attempting to hide preview window \(index + 1)/\(windowsToHide.count).")
            do {
                previewWindow.hide()
                log("✅ Successfully hid preview window \(index + 1).")
            } catch {
                log("❌ Error hiding preview window \(index + 1): \(error.localizedDescription)")
            }
        }
        
        previewWindows.removeAll()
        log("✅ All preview windows array cleared.")
    }
    
    private func showFullView(for windowInfo: WindowInfo, with image: NSImage) {
        log("🔍 showFullView called for '\(windowInfo.title)'")
        
        do {
            // Only hide the full view if one currently exists
            if fullViewWindow != nil {
                log("🚪 Existing full view window detected, hiding it.")
                hideFullView()
            }
            
            guard let mainScreen = NSScreen.main else { 
                log("❌ No main screen available for full view")
                return 
            }
            
            let scaleFactor: CGFloat = 0.8
            let fullViewSize = NSSize(width: mainScreen.frame.width * scaleFactor, height: mainScreen.frame.height * scaleFactor)
            let fullViewOrigin = NSPoint(x: (mainScreen.frame.width - fullViewSize.width) / 2, y: (mainScreen.frame.height - fullViewSize.height) / 2)
            let fullViewFrame = NSRect(origin: fullViewOrigin, size: fullViewSize)
            
            log("📐 Creating full view window: \(fullViewFrame)")
            
            fullViewWindow = FullViewWindow(contentRect: fullViewFrame, styleMask: [.borderless], backing: .buffered, defer: false)
            fullViewWindow?.level = .floating
            fullViewWindow?.backgroundColor = .clear
            fullViewWindow?.isOpaque = false
            fullViewWindow?.hasShadow = true
            
            let imageView = NSImageView(frame: NSRect(origin: .zero, size: fullViewSize))
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
            fullViewWindow?.contentView = imageView
            
            if let fullViewWindow = fullViewWindow as? FullViewWindow {
                fullViewWindow.onMouseExit = { [weak self] in
                    log("🚪 Full view mouse exit detected")
                    guard let self = self else { return }
                    
                    if Thread.isMainThread {
                        self.hideFullView()
                    } else {
                        DispatchQueue.main.async {
                            self.hideFullView()
                        }
                    }
                }
            }
            
            fullViewTimer?.invalidate()
            fullViewTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                log("⏰ Full view timer expired")
                DispatchQueue.main.async {
                    self?.hideFullView()
                }
            }
            
            fullViewWindow?.orderFront(nil)
            log("✅ Full view window ordered front.")
            log("✅ Full view window created and shown.")
            
        } catch {
            log("❌ Error in showFullView: \(error)")
        }
    }
    
    private func showFullViewPermanent(for windowInfo: WindowInfo, with image: NSImage) {
        guard let mainScreen = NSScreen.main else { return }
        
        let scaleFactor: CGFloat = 0.9
        let fullViewSize = NSSize(width: mainScreen.frame.width * scaleFactor, height: mainScreen.frame.height * scaleFactor)
        let fullViewOrigin = NSPoint(x: (mainScreen.frame.width - fullViewSize.width) / 2, y: 100)
        let fullViewFrame = NSRect(origin: fullViewOrigin, size: fullViewSize)
        
        let permanentWindow = NSWindow(contentRect: fullViewFrame, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        permanentWindow.title = windowInfo.title
        permanentWindow.level = .normal
        
        let imageView = NSImageView(frame: NSRect(origin: .zero, size: fullViewSize))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        permanentWindow.contentView = imageView
        
        permanentWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideFullView() {
        log("🚪 hideFullView called.")
        
        // Cancel any existing timer first
        fullViewTimer?.invalidate()
        fullViewTimer = nil
        log("✅ Full view timer invalidated and nilled.")
        
        // Close window if it exists
        if let window = fullViewWindow {
            log("🚪 Attempting to close full view window: \(window.debugDescription)")
            
            // Clear reference first to prevent re-entrancy issues
            fullViewWindow = nil
            
            // Close on main thread
            if Thread.isMainThread {
                window.close()
                log("✅ Full view window closed on main thread.")
            } else {
                DispatchQueue.main.async {
                    window.close()
                    log("✅ Full view window closed on main thread.")
                }
            }
            
            log("✅ Full view window reference cleared on main thread.")
        } else {
            log("ℹ️ No full view window to close.")
        }
        
        log("✅ Full view hidden successfully.")
    }
}

class FullViewWindow: NSWindow {
    var onMouseExit: (() -> Void)?
    private var trackingArea: NSTrackingArea?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupMouseTracking()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    private func setupMouseTracking() {
        if let trackingArea = trackingArea {
            contentView?.removeTrackingArea(trackingArea)
        }
        guard let contentView = contentView else { return }
        trackingArea = NSTrackingArea(rect: contentView.bounds, options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self, userInfo: nil)
        contentView.addTrackingArea(trackingArea!)
    }

    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool) {
        super.setFrame(frameRect, display: displayFlag)
        setupMouseTracking()
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if let onMouseExit = onMouseExit {
            if Thread.isMainThread {
                onMouseExit()
            } else {
                DispatchQueue.main.async {
                    onMouseExit()
                }
            }
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            if let onMouseExit = onMouseExit {
                if Thread.isMainThread {
                    onMouseExit()
                } else {
                    DispatchQueue.main.async {
                        onMouseExit()
                    }
                }
            }
        } else {
            super.keyDown(with: event)
        }
    }

    deinit {
        log("🗑️ FullViewWindow deinitialized.")
        if let trackingArea = trackingArea {
            contentView?.removeTrackingArea(trackingArea)
        }
    }
}
