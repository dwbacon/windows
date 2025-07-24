
import AppKit
import SwiftUI

class DockMonitor {
    private var observer: AXObserver?
    private var dock: AXUIElement
    private var previewWindow: NSWindow?

    init() {
        self.dock = AXUIElementCreateApplication(NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first!.processIdentifier)
        AXObserverCreate(NSRunningApplication.current.processIdentifier, { observer, element, notification, refcon in
            let self_ = Unmanaged<DockMonitor>.fromOpaque(refcon!).takeUnretainedValue()
            var title: AnyObject?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
            if let title = title as? String {
                print("DockMonitor: Detected hover over app: \(title)")
                let windowManager = WindowManager()
                let images = windowManager.getOpenWindows(for: title)
                print("DockMonitor: Found \(images.count) window images for \(title)")
                DispatchQueue.main.async {
                    self_.showPreviews(images: images)
                }
            } else {
                print("DockMonitor: Could not get title for hovered element.")
            }
        }, &observer)

        if let observer = observer {
            AXObserverAddNotification(observer, dock, kAXFocusedUIElementChangedNotification as CFString, Unmanaged.passUnretained(self).toOpaque())
            CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }
    }

    func showPreviews(images: [NSImage]) {
        if let previewWindow = previewWindow {
            previewWindow.close()
        }

        guard let firstImage = images.first else {
            print("DockMonitor: No images to show for preview.")
            return
        }

        let previewView = PreviewView(image: firstImage)
        let hostingView = NSHostingView(rootView: previewView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        self.previewWindow = window
        print("DockMonitor: Preview window shown.")
    }

    deinit {
        if let observer = observer {
            AXObserverRemoveNotification(observer, dock, kAXFocusedUIElementChangedNotification as CFString)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }
    }
}
