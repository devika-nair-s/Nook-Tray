import AppKit
import SwiftUI
import Combine

class NookWindow: NSPanel {
    private var hostingView: NSHostingView<AnyView>?
    private var trackingView: NookTrackingView?
    private var isExpanded = false
    private var isLocked = false
    private var backdropWindow: NookBackdropWindow?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private let musicController = MusicPlayerController()
    private var cancellables = Set<AnyCancellable>()
    
    // Base Sizes (will be dynamically adjusted by AppSettings tuning)
    private var baseCollapsedWidth: CGFloat = 88
    private var baseHoverWidth: CGFloat = 240
    private var baseFullExpandedWidth: CGFloat = 360
    
    private var baseCollapsedHeight: CGFloat = 18
    private var baseHoverHeight: CGFloat = 35
    private var baseFullExpandedHeight: CGFloat = 180
    
    private var currentCollapsedWidth: CGFloat {
        max(60, baseCollapsedWidth + CGFloat(AppSettings.shared.notchWidthOffset))
    }
    
    private var currentCollapsedHeight: CGFloat {
        max(12, baseCollapsedHeight + CGFloat(AppSettings.shared.notchHeightOffset))
    }
    
    private var currentHoverWidth: CGFloat {
        max(100, baseHoverWidth + CGFloat(AppSettings.shared.notchWidthOffset))
    }
    
    private var currentHoverHeight: CGFloat {
        max(24, baseHoverHeight + CGFloat(AppSettings.shared.notchHeightOffset))
    }
    
    private var currentFullExpandedWidth: CGFloat {
        max(200, baseFullExpandedWidth + CGFloat(AppSettings.shared.notchWidthOffset))
    }
    
    private var currentFullExpandedHeight: CGFloat {
        max(100, baseFullExpandedHeight + CGFloat(AppSettings.shared.notchHeightOffset))
    }
    
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
        setupSettingsObservation()
    }
    
    private var targetScreen: NSScreen? {
        return NSScreen.screens.first ?? NSScreen.main
    }
    
    private func setupSettingsObservation() {
        Publishers.CombineLatest3(AppSettings.shared.$notchXOffset, AppSettings.shared.$notchWidthOffset, AppSettings.shared.$notchHeightOffset)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                guard let self = self else { return }
                self.updateFrameForCurrentState()
            }
            .store(in: &cancellables)
    }
    
    private func setupScreenNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateFrameForCurrentState()
        }
    }
    
    private func setupWindow() {
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        
        isMovable = false
        isMovableByWindowBackground = false
        acceptsMouseMovedEvents = true
        alphaValue = 1.0
    }
    
    private func positionUnderCamera() {
        updateFrameForCurrentState()
    }
    
    func updateFrameForCurrentState() {
        guard let screen = targetScreen else { return }
        
        let screenFrame = screen.frame
        let screenCenterX = screenFrame.midX
        let topY = screenFrame.maxY
        
        let targetWidth: CGFloat
        let targetHeight: CGFloat
        
        if isLocked {
            targetWidth = currentFullExpandedWidth
            targetHeight = currentFullExpandedHeight
        } else if isExpanded {
            targetWidth = currentHoverWidth
            targetHeight = currentHoverHeight
        } else {
            targetWidth = currentCollapsedWidth
            targetHeight = currentCollapsedHeight
        }
        
        let x = round(screenCenterX - (targetWidth / 2.0) + CGFloat(AppSettings.shared.notchXOffset))
        let y = topY - targetHeight
        
        setFrame(NSRect(x: x, y: y, width: targetWidth, height: targetHeight), display: true)
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
        
        setupHoverDetection()
    }
    
    private var hoverTimer: Timer?
    
    private func setupHoverDetection() {
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkMouseHover()
        }
    }
    
    private func checkMouseHover() {
        guard !isLocked, !isExpanded, AppSettings.shared.expandOnHover else { return }
        guard let screen = targetScreen else { return }
        
        let mouseLoc = NSEvent.mouseLocation
        let screenFrame = screen.frame
        let centerX = screenFrame.midX
        let topY = screenFrame.maxY
        
        // Dynamic detection area based on hoverSensitivity and notchXOffset
        let sensitivity = max(0.5, min(3.0, AppSettings.shared.hoverSensitivity))
        let notchWidth: CGFloat = 60 + (CGFloat(sensitivity) * 120)
        let notchHeight: CGFloat = 15 + (CGFloat(sensitivity) * 15)
        let notchRect = NSRect(x: centerX - (notchWidth / 2.0) + CGFloat(AppSettings.shared.notchXOffset), y: topY - notchHeight, width: notchWidth, height: notchHeight)
        
        if notchRect.contains(mouseLoc) {
            animateHover(expand: true)
        }
    }
    
    private func setupBackdrop() {
        let backdrop = NookBackdropWindow()
        backdrop.onClickOutside = { [weak self] in
            guard AppSettings.shared.closeWhenClickingOutside else { return }
            self?.unlockAndCollapse()
        }
        self.backdropWindow = backdrop
    }
    
    private func handleMouseEntered() {
        guard !isLocked else { return }
        if AppSettings.shared.expandOnHover {
            animateHover(expand: true)
        }
    }
    
    private func handleMouseExited() {
        guard !isLocked else { return }
        if AppSettings.shared.expandOnHover {
            animateHover(expand: false)
        }
    }
    
    private func handleMouseClicked() {
        if AppSettings.shared.keepOpenWhenClicked {
            if !isLocked {
                isLocked = true
                animateHover(expand: true)
                showBackdrop()
            }
        } else {
            isLocked = false
            animateHover(expand: true)
        }
    }
    
    private func animateHover(expand: Bool) {
        guard let screen = targetScreen else { return }
        let screenFrame = screen.frame
        let screenCenterX = screenFrame.midX
        let topY = screenFrame.maxY
        
        isExpanded = expand
        
        NSAnimationContext.runAnimationGroup { context in
            let speed = max(0.2, min(3.0, AppSettings.shared.animationSpeed))
            context.duration = 0.22 / speed
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            var newFrame = frame
            if expand {
                let targetWidth: CGFloat = isLocked ? currentFullExpandedWidth : currentHoverWidth
                let targetHeight: CGFloat = isLocked ? currentFullExpandedHeight : currentHoverHeight
                
                newFrame.size = NSSize(width: targetWidth, height: targetHeight)
                newFrame.origin.x = round(screenCenterX - (targetWidth / 2.0) + CGFloat(AppSettings.shared.notchXOffset))
                newFrame.origin.y = topY - targetHeight
            } else {
                newFrame.size = NSSize(width: currentCollapsedWidth, height: currentCollapsedHeight)
                newFrame.origin.x = round(screenCenterX - (currentCollapsedWidth / 2.0) + CGFloat(AppSettings.shared.notchXOffset))
                newFrame.origin.y = topY - currentCollapsedHeight
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
            guard AppSettings.shared.closeWhenClickingOutside else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !self.frame.contains(mouseLocation) {
                DispatchQueue.main.async {
                    self.unlockAndCollapse()
                }
            }
        }
        
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            guard AppSettings.shared.closeWhenClickingOutside else { return event }
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
        if AppSettings.shared.keepOpenWhenClicked {
            if !isLocked {
                isLocked = true
                animateHover(expand: true)
                showBackdrop()
            }
        } else {
            isLocked = false
            animateHover(expand: true)
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
        level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue - 1)
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
