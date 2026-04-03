import Cocoa
import SwiftUI
import AVKit

class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()
    
    private var windows: [NSScreen: NSWindow] = [:]  // Ein Fenster pro Screen
    @Published var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    
    private var timer: Timer?
    private var didAutoPaused = false
    
    private var isPlayingBeforeSleep = false
    
    // MARK: - Multi-Desktop Support
    private var currentSpaceIndex: Int = 0
    @Published var currentSpaceIndex_Published: Int = 0
    private var currentVideoConfig: Video?
    
    private init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                if isOvercast() {
                    self?.autoPauseVideo()
                } else {
                    self?.autoResumeVideo()
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
        
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        workspace.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        startSpaceMonitoring()
        
    } // Singleton
    
    // MARK: - Space Monitoring for Wallpaper
    private func startSpaceMonitoring() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(spaceDidChange),
            name: NSNotification.Name("com.apple.spaces.switched"),
            object: nil
        )
    }
    
    @objc private func spaceDidChange() {
        DispatchQueue.main.async {
            self.currentSpaceIndex = (self.currentSpaceIndex + 1) % 4
            self.updateSpaceIndex()
            self.updateWallpaperVisibility()
        }
    }
    
    private func updateSpaceIndex() {
        currentSpaceIndex_Published = currentSpaceIndex
    }
    
    /// Check if wallpaper should be visible in current space
    func shouldShowWallpaper(_ video: Video) -> Bool {
        switch video.desktopMode {
        case .allSpaces:
            return true
        case .currentSpace:
            return true
        case .specificSpaces:
            return video.visibleSpaces.contains(currentSpaceIndex)
        }
    }
    
    /// Update wallpaper visibility based on current space
    private func updateWallpaperVisibility() {
        guard let config = currentVideoConfig else { return }
        
        let shouldShow = shouldShowWallpaper(config)
        
        for (_, window) in windows {
            if shouldShow {
                if window.isVisible == false {
                    window.orderFront(nil)
                }
            } else {
                if window.isVisible == true {
                    window.orderOut(nil)
                }
            }
        }
    }
    
    @objc private func handleWake() {
        print("System woke from sleep")
        if isPlayingBeforeSleep {
            print("resume player")
            player?.play()
            objectWillChange.send()
        }
    }
    
    @objc private func handleSleep() {
        print("System is about to sleep")
        if player?.rate != 0 {
            isPlayingBeforeSleep = true
        } else {
            isPlayingBeforeSleep = false
        }
    }
    
    /// Creates wallpaper windows for all screens
    private func createWallpaperWindows(for video: Video) {
        // Close existing windows
        for (_, window) in windows {
            window.close()
        }
        windows.removeAll()
        
        // Create a window for each screen
        let allScreens = NSScreen.screens
        
        for screen in allScreens {
            let newWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            newWindow.isOpaque = false
            newWindow.backgroundColor = .clear
            newWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
            
            // Configure collection behavior based on desktop mode
            switch video.desktopMode {
            case .allSpaces:
                newWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            case .currentSpace:
                newWindow.collectionBehavior = [.stationary, .ignoresCycle]
            case .specificSpaces:
                newWindow.collectionBehavior = [.stationary, .ignoresCycle]
            }
            
            newWindow.ignoresMouseEvents = true
            newWindow.makeKeyAndOrderFront(nil)
            
            windows[screen] = newWindow
            
            print("Created wallpaper window for screen: \(screen.localizedName) - Frame: \(screen.frame)")
        }
    }
    
    /// Sets or updates the wallpaper video URL
    func setWallpaperVideo(video: Video) {
        currentVideoConfig = video
        
        guard let url = constructURL(from: video.url) else { return }
        
        if !isValidMovieFile(at: url) {
            return
        }
        
        for track in player?.currentItem?.tracks ?? [] {
            removeSnapshot()
            track.isEnabled = true
            didAutoPaused = false
        }
        
        if windows.isEmpty {
            createWallpaperWindows(for: video)
        }
        
        let playerItem = AVPlayerItem(url: url)
        
        looper?.disableLooping()
        looper = nil
        player?.removeAllItems()
        player = AVQueuePlayer()
        looper = AVPlayerLooper(player: player!, templateItem: playerItem)
        
        // Update content for each window
        for (_, window) in windows {
            let playerView = PlayerLayerView(player: player!, video: video)
            let hostView = NSHostingView(rootView: playerView)
            animateContentViewTransition(window: window, newContentView: hostView)
        }
        
        updateWallpaperVisibility()
        
        player!.play()
    }
    
    private func animateContentViewTransition(window: NSWindow?, newContentView: NSView) {
        guard let window = window else { return }
        
        window.contentView?.wantsLayer = true
        newContentView.wantsLayer = true
        
        newContentView.alphaValue = 0
        
        window.contentView?.addSubview(newContentView)
        
        newContentView.frame = window.contentView?.bounds ?? .zero
        newContentView.autoresizingMask = [.width, .height]
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            window.contentView?.subviews.forEach { view in
                if view != newContentView {
                    view.animator().alphaValue = 0
                }
            }
            
            newContentView.animator().alphaValue = 1
        } completionHandler: {
            window.contentView = newContentView
            newContentView.alphaValue = 1
        }
    }
    
    /// Mute or unmute the wallpaper video
    func toggleMute() {
        if let player = player {
            player.isMuted.toggle()
            
            for track in player.currentItem?.tracks ?? [] {
                if track.assetTrack?.hasMediaCharacteristic(.audible) == true {
                    track.isEnabled = !player.isMuted
                }
            }
        }
        
        objectWillChange.send()
    }
    
    func togglePlaying() {
        if player?.rate == 0 {
            player?.play()
        } else {
            player?.pause()
        }
        objectWillChange.send()
    }
    
    func destroy() {
        looper = nil
        player?.removeAllItems()
        player = nil
        
        for (_, window) in windows {
            window.close()
        }
        windows.removeAll()
    }
    
    private func autoPauseVideo() {
        if UserSetting.shared.powerSaver && !didAutoPaused {
            for track in player?.currentItem?.tracks ?? [] {
                if track.assetTrack?.hasMediaCharacteristic(.visual) == true {
                    takeSnapshot()
                    track.isEnabled = false
                    didAutoPaused = true
                    print("auto paused")
                }
            }
        }
    }
    
    private func autoResumeVideo() {
        if didAutoPaused {
            for track in player?.currentItem?.tracks ?? [] {
                removeSnapshot()
                track.isEnabled = true
                didAutoPaused = false
                print("auto resumed")
            }
        }
    }
    
    private func takeSnapshot() {
        guard let (_, window) = windows.first,
              let playerItem = player?.currentItem,
              let rootView = window.contentView else {
            return
        }
        
        let generator = AVAssetImageGenerator(asset: playerItem.asset)
        generator.appliesPreferredTrackTransform = true
        let time = playerItem.currentTime()
        
        let image = try? generator.copyCGImage(at: time, actualTime: nil)
        let snapshot = image.map { NSImage(cgImage: $0, size: .zero) }
        
        let imageView = NSImageViewFill()
        imageView.image = snapshot
        imageView.frame = rootView.bounds
        imageView.autoresizingMask = [.width, .height]
        imageView.identifier = NSUserInterfaceItemIdentifier("SnapshotOverlay")
        
        let showDarkLayer: Bool = {
            guard UserSetting.shared.adaptiveMode else { return false }
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? true : false
        }()
        
        if showDarkLayer {
            imageView.layer?.addSublayer(createAdaptiveDarkModeOverlay(rect: rootView.bounds, characteristics: UserSetting.shared.video.attrs))
        }
        
        rootView.addSubview(imageView, positioned: .above, relativeTo: nil)
    }
    
    private func removeSnapshot() {
        for (_, window) in windows {
            guard let rootView = window.contentView else { continue }
            
            for subview in rootView.subviews {
                if subview.identifier?.rawValue == "SnapshotOverlay" {
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.5
                        subview.animator().alphaValue = 0
                    }, completionHandler: {
                        subview.removeFromSuperview()
                    })
                }
            }
        }
    }
    
    deinit {
        timer?.invalidate()
        looper = nil
        player?.removeAllItems()
        player = nil
        
        for (_, window) in windows {
            window.close()
        }
        
        DistributedNotificationCenter.default().removeObserver(self)
    }
}

struct PlayerWrapper: NSViewRepresentable {
    let playerView: AVPlayerView
    
    func makeNSView(context: Context) -> AVPlayerView {
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
}

class NSImageViewFill: NSImageView {
    open override var image: NSImage? {
        set {
            self.layer = CALayer()
            self.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
            self.layer?.contents = newValue
            self.wantsLayer = true
            
            super.image = newValue
        }
        
        get {
            return super.image
        }
    }
}
