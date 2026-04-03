import Cocoa
import SwiftUI

class ClockManager: ObservableObject {
    static let shared = ClockManager()
    
    private var clockWindows: [String: NSWindow] = [:]  // clockId -> window
    private var updateTimer: Timer?
    private var displayLink: CVDisplayLink?
    private var currentSpaceIndex: Int = 0
    
    @Published var currentTime: Date = Date()
    @Published var isEditMode: Bool = false
    @Published var editingClockId: String?
    @Published var currentSpaceIndex_Published: Int = 0
    
    private init() {
        setupUpdateTimer()
        startSpaceMonitoring()
    }
    
    // MARK: - Space Monitoring
    private func startSpaceMonitoring() {
        // Monitor for space changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(spaceDidChange),
            name: NSNotification.Name("com.apple.spaces.switched"),
            object: nil
        )
    }
    
    @objc private func spaceDidChange() {
        DispatchQueue.main.async {
            self.updateSpaceIndex()
            self.updateAllClockWindows()
        }
    }
    
    private func updateSpaceIndex() {
        // Update space index based on system
        // Note: macOS doesn't provide a reliable public API to get current space index
        // We use a simplified approach that works with Distributed Notifications
        currentSpaceIndex_Published = currentSpaceIndex
    }
    
    private func getActiveSpaceIndex() -> Int? {
        // Simplified approach: return current space index from our tracking
        // In practice, we update this via space change notifications
        return currentSpaceIndex
    }
    
    // MARK: - Multi-Desktop Window Management
    /// Check if clock should be visible in current space
    func shouldShowClock(_ config: ClockConfig) -> Bool {
        guard config.isEnabled else { return false }
        
        switch config.desktopMode {
        case .allSpaces:
            return true
        case .currentSpace:
            return true  // Always show on current space
        case .specificSpaces:
            return config.visibleSpaces.contains(currentSpaceIndex)
        }
    }
    
    /// Creates and shows clock windows for all configured spaces
    func showClockWindow(with config: ClockConfig) {
        // Remove existing window for this clock if any
        hideClockWindow(for: config.id)
        
        guard let screen = NSScreen.main else { return }
        
        let contentView = ClockDisplayView(config: config)
        let hostingView = NSHostingView(rootView: contentView)
        
        // Calculate window frame based on position
        let screenFrame = screen.frame
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 150
        
        let positionPoint = config.customPosition ?? config.position.normalized
        let x = screenFrame.origin.x + (screenFrame.width * positionPoint.x) - (windowWidth / 2)
        let y = screenFrame.origin.y + (screenFrame.height * (1 - positionPoint.y)) - (windowHeight / 2)
        
        let windowRect = NSRect(x: x, y: y, width: windowWidth, height: windowHeight)
        
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        
        // Configure collection behavior based on desktop mode
        switch config.desktopMode {
        case .allSpaces:
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        case .currentSpace:
            window.collectionBehavior = [.stationary, .ignoresCycle]
        case .specificSpaces:
            window.collectionBehavior = [.stationary, .ignoresCycle]
        }
        
        window.ignoresMouseEvents = true
        window.alphaValue = CGFloat(config.opacity)
        window.makeKeyAndOrderFront(nil)
        
        self.clockWindows[config.id] = window
    }
    
    /// Updates the active clock window
    func updateClockWindow(with config: ClockConfig) {
        if clockWindows[config.id] != nil {
            showClockWindow(with: config)
        }
    }
    
    /// Hides and removes the clock window
    func hideClockWindow(for clockId: String) {
        clockWindows[clockId]?.close()
        clockWindows.removeValue(forKey: clockId)
    }
    
    /// Hide all clock windows
    func hideAllClockWindows() {
        for (_, window) in clockWindows {
            window.close()
        }
        clockWindows.removeAll()
    }
    
    /// Update all visible clock windows based on current space
    private func updateAllClockWindows() {
        for window in clockWindows.values {
            window.setIsVisible(false)
        }
    }
    
    /// Updates only the position of the clock window
    func updateClockPosition(for clockId: String, x: CGFloat, y: CGFloat) {
        guard let window = clockWindows[clockId] else { return }
        var frame = window.frame
        frame.origin.x = x
        frame.origin.y = y
        window.setFrame(frame, display: true, animate: false)
    }
    
    /// Updates only the opacity of the clock window
    func updateClockOpacity(for clockId: String, _ opacity: Double) {
        clockWindows[clockId]?.alphaValue = CGFloat(opacity)
    }
    
    /// Enter edit mode - returns normalized position
    func enterEditMode(for clockId: String) -> CGPoint? {
        isEditMode = true
        editingClockId = clockId
        
        guard let window = clockWindows[clockId], let screen = NSScreen.main else { return nil }
        
        let screenFrame = screen.frame
        let normalizedX = (window.frame.midX - screenFrame.origin.x) / screenFrame.width
        let normalizedY = (screenFrame.origin.y + screenFrame.height - window.frame.midY) / screenFrame.height
        
        return CGPoint(x: normalizedX, y: normalizedY)
    }
    
    /// Exit edit mode and update position
    func exitEditMode(with newPosition: CGPoint) {
        isEditMode = false
        editingClockId = nil
    }
    
    /// Update window position during drag
    func updateWindowDuringDrag(for clockId: String, position: CGPoint) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 150
        
        let x = screenFrame.origin.x + (screenFrame.width * position.x) - (windowWidth / 2)
        let y = screenFrame.origin.y + (screenFrame.height * (1 - position.y)) - (windowHeight / 2)
        
        updateClockPosition(for: clockId, x: x, y: y)
    }
    
    // MARK: - Timer Setup
    private func setupUpdateTimer() {
        // Update every second for smooth clock display
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentTime = Date()
            }
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
    }
    
    deinit {
        updateTimer?.invalidate()
        hideAllClockWindows()
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
