import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var nookWindow: NookWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let path = Bundle.main.path(forResource: "app_photo", ofType: "jpg"),
           let iconImg = NSImage(contentsOfFile: path) {
            NSApplication.shared.applicationIconImage = iconImg
        }
        
        // Menu bar accessory app
        NSApp.setActivationPolicy(.accessory)
        
        // Create menu bar item
        setupMenuBar()
        
        // Create and show the Nook window
        setupNookWindow()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            if let path = Bundle.main.path(forResource: "app_photo", ofType: "jpg"),
               let rawImage = NSImage(contentsOfFile: path) {
                let menuBarImage = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
                    let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
                    path.addClip()
                    rawImage.draw(in: rect)
                    return true
                }
                button.image = menuBarImage
            } else {
                let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
                    let path = NSBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3))
                    NSColor.white.setStroke()
                    path.lineWidth = 1.5
                    path.stroke()
                    return true
                }
                image.isTemplate = true
                button.image = image
            }
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Open Nook", action: #selector(openNook), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupNookWindow() {
        nookWindow = NookWindow()
        nookWindow?.orderFrontRegardless()
    }
    
    @objc private func openNook() {
        nookWindow?.expand()
        nookWindow?.orderFrontRegardless()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
