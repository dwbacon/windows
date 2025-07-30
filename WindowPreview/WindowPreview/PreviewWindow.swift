
import Cocoa

class PreviewWindow: NSWindow {
    private let imageView: NSImageView
    private var trackingArea: NSTrackingArea?
    private var isCleanedUp = false
    
    var onHover: (() -> Void)?
    var onUnhover: (() -> Void)?
    var onClick: (() -> Void)?
    
    init() {
        imageView = NSImageView(frame: .zero)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 150),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        self.contentView = imageView
        self.isOpaque = false
        self.backgroundColor = NSColor.black.withAlphaComponent(0.1)
        self.hasShadow = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        setupMouseTracking()
    }
    
    private func setupMouseTracking() {
        guard !isCleanedUp else { return }
        
        // Clear any existing tracking area first
        if let trackingArea = trackingArea {
            contentView?.removeTrackingArea(trackingArea)
            self.trackingArea = nil
        }
        
        guard let contentView = contentView else {
            log("❌ No contentView for tracking area setup")
            return
        }
        
        trackingArea = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(trackingArea!)
        log("✅ Mouse tracking area setup: \(contentView.bounds)")
    }
    
    override func mouseEntered(with event: NSEvent) {
        guard !isCleanedUp else { return }
        log("🖱️ PreviewWindow mouseEntered detected")
        
        // Execute hover callback safely
        if let onHover = onHover {
            onHover()
        } else {
            log("❌ PreviewWindow mouseEntered: onHover is nil")
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        guard !isCleanedUp else { return }
        log("🖱️ PreviewWindow mouseExited detected")
        
        // Execute unhover callback safely
        if let onUnhover = onUnhover {
            onUnhover()
        } else {
            log("ℹ️ PreviewWindow mouseExited: onUnhover is nil, skipping")
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        guard !isCleanedUp else { return }
        super.mouseDown(with: event)
        onClick?()
    }
    
    func show(image: NSImage, at rect: NSRect, windowInfo: WindowInfo) {
        log("📺 PreviewWindow showing for '\(windowInfo.title)' at \(rect)")
        
        imageView.image = image
        
        // Use the provided rect directly
        self.setFrame(rect, display: true)
        
        // Update tracking area after frame change
        setupMouseTracking()
        
        self.orderFront(nil)
        log("✅ PreviewWindow shown successfully")
    }
    
    func hide() {
        log("🚪 PreviewWindow hiding")
        
        // Mark as cleaned up to prevent further mouse events
        isCleanedUp = true
        
        // Clean up tracking area FIRST
        if let trackingArea = trackingArea {
            contentView?.removeTrackingArea(trackingArea)
            self.trackingArea = nil
        }
        
        // Clear callbacks to prevent crashes
        onHover = nil
        onUnhover = nil
        onClick = nil
        
        // Hide window and clear image
        self.orderOut(nil)
        imageView.image = nil
        
        log("✅ PreviewWindow hidden and cleaned up")
    }
    
    deinit {
        log("🗑️ PreviewWindow deinitialized.")
        if let trackingArea = trackingArea {
            contentView?.removeTrackingArea(trackingArea)
        }
    }
}
