import Cocoa
import ApplicationServices

@MainActor
protocol DockHoverDetectorDelegate: AnyObject {
    func dockIconHovered(for app: NSRunningApplication)
    func dockIconExited()
}

class DockHoverDetector: NSObject {
    weak var delegate: DockHoverDetectorDelegate?
    
    private var isMonitoring = false
    private var lastHoveredApp: NSRunningApplication?
    private var debugCounter = 0
    private var timer: Timer?
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Check if accessibility is enabled
        guard AXIsProcessTrusted() else {
            log("❌ Accessibility permissions not granted for dock hover detection")
            return
        }
        
        // Start polling mouse position for dock hover detection
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkMousePosition), userInfo: nil, repeats: true)
        log("✅ Started mouse position-based dock hover monitoring")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        log("🛑 Stopped dock hover monitoring")
    }
    
    @MainActor
    @objc private func checkMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        
        // Convert screen coordinates to flipped coordinates for accessibility API
        guard let mainScreen = NSScreen.main else { return }
        let flippedY = mainScreen.frame.height - mouseLocation.y
        let accessibilityPoint = CGPoint(x: mouseLocation.x, y: flippedY)
        
        // Get the accessibility element at the mouse position
        let systemWideElement = AXUIElementCreateSystemWide()
        var elementRef: AXUIElement?
        
        let result = AXUIElementCopyElementAtPosition(
            systemWideElement,
            Float(accessibilityPoint.x),
            Float(accessibilityPoint.y),
            &elementRef
        )
        
        guard result == .success, let element = elementRef else {
            // No element at mouse position
            if lastHoveredApp != nil {
                log("🚪 Mouse left dock area")
                delegate?.dockIconExited()
                lastHoveredApp = nil
            }
            return
        }
        
        // Check if this element belongs to the Dock
        if let app = getAppFromElement(element) {
            // Only process dock-related apps
            if isDockElement(element) {
                if app.bundleIdentifier != lastHoveredApp?.bundleIdentifier {
                    log("🎯 Dock hover detected: \(app.localizedName ?? "Unknown") at (\(Int(mouseLocation.x)), \(Int(mouseLocation.y)))")
                    delegate?.dockIconHovered(for: app)
                    lastHoveredApp = app
                }
            } else if lastHoveredApp != nil {
                // Mouse is not over dock anymore
                log("🚪 Mouse left dock")
                delegate?.dockIconExited()
                lastHoveredApp = nil
            }
        } else if lastHoveredApp != nil {
            // No app found at position
            log("🚪 No app at mouse position")
            delegate?.dockIconExited()
            lastHoveredApp = nil
        }
    }
    
    private func isDockElement(_ element: AXUIElement) -> Bool {
        // Get the application that owns this element
        var appElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, "AXApplication" as CFString, &appElement)
        
        guard result == .success, let app = appElement else {
            return false
        }
        
        // Get the PID of the owning application
        var pid: pid_t = 0
        let pidResult = AXUIElementGetPid(app as! AXUIElement, &pid)
        
        guard pidResult == .success else {
            return false
        }
        
        // Check if this PID belongs to the Dock
        if let dockApp = NSWorkspace.shared.runningApplications.first(where: { 
            $0.bundleIdentifier == "com.apple.dock" 
        }) {
            return pid == dockApp.processIdentifier
        }
        
        return false
    }
    
    private func getAppFromElement(_ element: AXUIElement) -> NSRunningApplication? {
        var appElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXApplicationAttribute as CFString, &appElement)
        
        guard result == .success, let axApp = appElement else {
            return nil
        }
        
        var pid: pid_t = 0
        let pidResult = AXUIElementGetPid(axApp as! AXUIElement, &pid)
        
        guard pidResult == .success else {
            return nil
        }
        
        return NSWorkspace.shared.runningApplications.first { $0.processIdentifier == pid }
    }
    
    
    deinit {
        stopMonitoring()
    }
}