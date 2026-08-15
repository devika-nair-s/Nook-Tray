import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()
    
    private var customWindow: NSWindow?
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("NookSettingsWindow")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        window.minSize = NSSize(width: 600, height: 400)
        
        // Ensure standard system traffic light buttons are visible and active
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
        
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        
        window.contentView = hostingView
        
        self.init(window: window)
        self.customWindow = window
        window.delegate = self
    }
    
    func showSettings() {
        guard let window = self.window ?? customWindow else { return }
        
        // Temporarily switch to regular app so Settings window can become key
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        // Restore accessory policy when settings window closes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
