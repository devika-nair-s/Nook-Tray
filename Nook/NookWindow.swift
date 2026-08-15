import AppKit
import SwiftUI

class NookWindow: NSPanel {
    private var hostingView: NSHostingView<AnyView>?
    private var trackingView: NookTrackingView?
    private var isExpanded = false
    private var isLocked = false
    private var backdropWindow: NookBackdropWindow?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private let musicController = MusicPlayerController()
    
    // Widths
    private let collapsedWidth: CGFloat = 160
    private let hoverWidth: CGFloat = 220
    private let fullExpandedWidth: CGFloat = 220
    
    // Heights
    private let collapsedHeight: CGFloat = 6
    private let hoverHeight: CGFloat = 44
    private let fullExpandedHeight: CGFloat = 44
    
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        positionUnderCamera()
        setupContent()
        setupBackdrop()
        setupScreenNotifications()
    }
    
    private var targetScreen: NSScreen? {
        return NSScreen.screens.first ?? NSScreen.main
    }
    
    private func setupScreenNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.positionUnderCamera()
        }
    }
    
    private func setupWindow() {
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        isMovable = false
        isMovableByWindowBackground = false
        acceptsMouseMovedEvents = true
        alphaValue = 1.0
    }
    
    private func positionUnderCamera() {
        guard let screen = targetScreen else { return }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let centerX = screenFrame.midX
        
        // Exact mathematical center of the physical display
        let x = round(centerX - (collapsedWidth / 2.0))
        let y = visibleFrame.maxY - collapsedHeight
        
        setFrame(NSRect(x: x, y: y, width: collapsedWidth, height: collapsedHeight), display: true)
    }
    
    private func setupContent() {
        let nookContentView = NookContentView(
            isExpanded: false,
            isLocked: false,
            onExpand: { [weak self] in
                self?.animateExpansion()
            },
            onClose: { [weak self] in
                self?.unlockAndCollapse()
            },
            musicController: musicController
        )
        
        hostingView = NSHostingView(rootView: AnyView(nookContentView))
        hostingView?.frame = self.frame.offsetBy(dx: -self.frame.origin.x, dy: -self.frame.origin.y)
        hostingView?.autoresizingMask = [.width, .height]
        
        trackingView = NookTrackingView(frame: self.frame.offsetBy(dx: -self.frame.origin.x, dy: -self.frame.origin.y))
        trackingView?.autoresizingMask = [.width, .height]
        
        trackingView?.onMouseEntered = { [weak self] in
            self?.handleMouseEntered()
        }
        
        trackingView?.onMouseExited = { [weak self] in
            self?.handleMouseExited()
        }
        
        if let trackingView = trackingView, let hostingView = hostingView {
            trackingView.addSubview(hostingView)
            self.contentView = trackingView
        }
    }
    
    private func setupBackdrop() {
        let backdrop = NookBackdropWindow()
        backdrop.onClickOutside = { [weak self] in
            self?.unlockAndCollapse()
        }
        self.backdropWindow = backdrop
    }
    
    private func handleMouseEntered() {
        guard !isLocked else { return }
        animateHover(expand: true)
    }
    
    private func handleMouseExited() {
        guard !isLocked else { return }
        animateHover(expand: false)
    }
    
    private func handleMouseClicked() {
        if !isLocked {
            isLocked = true
            animateHover(expand: true)
            showBackdrop()
        }
    }
    
    private func animateHover(expand: Bool) {
        guard let screen = targetScreen else { return }
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let screenCenterX = screenFrame.midX
        let topY = visibleFrame.maxY // Exactly at the bottom edge of the camera space
        
        isExpanded = expand
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            var newFrame = frame
            if expand {
                let targetWidth: CGFloat = isLocked ? fullExpandedWidth : hoverWidth
                let targetHeight: CGFloat = isLocked ? fullExpandedHeight : hoverHeight
                
                newFrame.size = NSSize(width: targetWidth, height: targetHeight)
                newFrame.origin.x = round(screenCenterX - (targetWidth / 2.0))
                newFrame.origin.y = topY - targetHeight
            } else {
                newFrame.size = NSSize(width: collapsedWidth, height: collapsedHeight)
                newFrame.origin.x = round(screenCenterX - (collapsedWidth / 2.0))
                newFrame.origin.y = topY - collapsedHeight
            }
            
            animator().setFrame(newFrame, display: true)
        }
        
        updateContent(expanded: expand)
    }
    
    private func showBackdrop() {
        guard let screen = NSScreen.main else { return }
        backdropWindow?.show(for: screen)
        
        removeEventMonitors()
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !self.frame.contains(mouseLocation) {
                DispatchQueue.main.async {
                    self.unlockAndCollapse()
                }
            }
        }
        
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            let mouseLocation = NSEvent.mouseLocation
            if !self.frame.contains(mouseLocation) {
                DispatchQueue.main.async {
                    self.unlockAndCollapse()
                }
            }
            return event
        }
    }
    
    private func hideBackdrop() {
        backdropWindow?.hide()
        removeEventMonitors()
    }
    
    private func removeEventMonitors() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }
    
    func unlockAndCollapse() {
        guard isLocked || isExpanded else { return }
        
        isLocked = false
        hideBackdrop()
        animateHover(expand: false)
    }
    
    private func animateExpansion() {
        if !isLocked {
            isLocked = true
            animateHover(expand: true)
            showBackdrop()
        }
    }
    
    func expand() {
        animateExpansion()
    }
    
    private func updateContent(expanded: Bool) {
        hostingView?.rootView = AnyView(
            NookContentView(
                isExpanded: expanded,
                isLocked: isLocked,
                onExpand: { [weak self] in
                    self?.animateExpansion()
                },
                onClose: { [weak self] in
                    self?.unlockAndCollapse()
                },
                musicController: musicController
            )
        )
    }
    
    deinit {
        hideBackdrop()
    }
}

// Full-screen transparent backdrop that catches clicks outside the Nook window
class NookBackdropWindow: NSPanel {
    var onClickOutside: (() -> Void)?
    
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating - 1
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovable = false
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        let view = BackdropView()
        view.onMouseDown = { [weak self] in
            self?.onClickOutside?()
        }
        self.contentView = view
    }
    
    func show(for screen: NSScreen) {
        setFrame(screen.frame, display: true)
        orderFront(nil)
    }
    
    func hide() {
        orderOut(nil)
    }
}

class BackdropView: NSView {
    var onMouseDown: (() -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        onMouseDown?()
    }
    
    override func rightMouseDown(with event: NSEvent) {
        onMouseDown?()
    }
    
    override func otherMouseDown(with event: NSEvent) {
        onMouseDown?()
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
