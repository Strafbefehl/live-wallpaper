import Cocoa
import SwiftUI
import AVKit

class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()
    
    private var windows: [NSScreen: NSWindow] = [:]  // Ein Fenster pro Screen (Desktop)
    private var lockScreenWindows: [NSScreen: NSWindow] = [:]  // Ein Fenster pro Screen (Lockscreen)
    @Published var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    
    private var timer: Timer?
    private var didAutoPaused = false
    
    private var isPlayingBeforeSleep = false
    private var isLockScreenActive = false
    
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
        startScreenChangeMonitoring()
        startLockScreenMonitoring()
        
    } // Singleton
    
    // MARK: - Lock Screen Monitoring
    private func startLockScreenMonitoring() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(lockScreenActivated),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(lockScreenDeactivated),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
    }
    
    @objc private func lockScreenActivated() {
        print("🔒 Sperrbildschirm aktiviert")
        isLockScreenActive = true
        
        // Stelle sicher, dass Lock Screen Windows existieren
        if lockScreenWindows.isEmpty && !windows.isEmpty {
            print("⚠️ Lock Screen Windows nicht vorhanden, erstelle sie...")
            for screen in NSScreen.screens {
                if lockScreenWindows[screen] == nil {
                    addLockScreenWindow(for: screen)
                }
            }
        }
        
        showLockScreenWallpaper()
    }
    
    @objc private func lockScreenDeactivated() {
        print("🔓 Sperrbildschirm deaktiviert")
        isLockScreenActive = false
        hideLockScreenWallpaper()
    }
    
    /// Zeigt das Wallpaper auf dem Sperrbildschirm
    private func showLockScreenWallpaper() {
        guard let config = currentVideoConfig, let player = player else {
            print("❌ Keine Wallpaper Config oder Player für Lock Screen")
            return
        }
        
        for (_, window) in lockScreenWindows {
            // Stelle sicher, dass das Fenster Content hat
            if window.contentView == nil || window.contentView?.subviews.isEmpty ?? true {
                let playerView = PlayerLayerView(player: player, video: config)
                let hostView = NSHostingView(rootView: playerView)
                window.contentView = hostView
                print("📺 Lock Screen Content wurde aktualisiert")
            }
            window.orderFront(nil)
        }
    }
    
    /// Versteckt das Wallpaper vom Sperrbildschirm
    private func hideLockScreenWallpaper() {
        for (_, window) in lockScreenWindows {
            window.orderOut(nil)
        }
    }
    
    // MARK: - Screen Change Monitoring (Hot-Plug Support)
    private func startScreenChangeMonitoring() {
        Foundation.NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func handleScreensChanged() {
        print("🖥️ Screen configuration changed - syncing wallpaper...")
        
        let currentScreens = Set(NSScreen.screens)
        let managedScreens = Set(windows.keys)
        let managedLockScreens = Set(lockScreenWindows.keys)
        
        // Neue Screens hinzufügen
        for screen in currentScreens {
            if !managedScreens.contains(screen) {
                print("✅ Neuer Monitor erkannt: \(screen.localizedName)")
                addWallpaperWindow(for: screen)
            }
            // Auch Lock Screen Fenster für neue Screens hinzufügen
            if !managedLockScreens.contains(screen) {
                addLockScreenWindow(for: screen)
            }
        }
        
        // Entfernte Screens bereinigen
        for screen in managedScreens {
            if !currentScreens.contains(screen) {
                print("❌ Monitor entfernt: \(screen.localizedName)")
                if let window = windows[screen] {
                    window.close()
                    windows.removeValue(forKey: screen)
                }
            }
        }
        
        // Entfernte Lock Screen Screens bereinigen
        for screen in managedLockScreens {
            if !currentScreens.contains(screen) {
                if let window = lockScreenWindows[screen] {
                    window.close()
                    lockScreenWindows.removeValue(forKey: screen)
                }
            }
        }
        
        updateWallpaperVisibility()
    }
    
    /// Adds a new wallpaper window for a specific screen (for hot-plug)
    private func addWallpaperWindow(for screen: NSScreen) {
        guard let config = currentVideoConfig else { return }
        
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
        switch config.desktopMode {
        case .allSpaces:
            newWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        case .currentSpace:
            newWindow.collectionBehavior = [.stationary, .ignoresCycle]
        case .specificSpaces:
            newWindow.collectionBehavior = [.stationary, .ignoresCycle]
        }
        
        newWindow.ignoresMouseEvents = true
        newWindow.makeKeyAndOrderFront(nil)
        
        // Add wallpaper content to new window
        if let player = player {
            let playerView = PlayerLayerView(player: player, video: config)
            let hostView = NSHostingView(rootView: playerView)
            newWindow.contentView = hostView
        }
        
        windows[screen] = newWindow
        print("✅ Wallpaper window erstellt für: \(screen.localizedName)")
    }
    
    /// Adds a new lock screen window for a specific screen
    private func addLockScreenWindow(for screen: NSScreen) {
        guard let config = currentVideoConfig else { return }
        
        let lockWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        lockWindow.isOpaque = false
        lockWindow.backgroundColor = .clear
        // Lock screen window sollte über der normalen Lock Screen liegen
        // Use a high window level to appear above lock screen
        lockWindow.level = NSWindow.Level(rawValue: 1000)
        
        lockWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        lockWindow.ignoresMouseEvents = true
        
        // Add wallpaper content to lock screen window
        if let player = player {
            let playerView = PlayerLayerView(player: player, video: config)
            let hostView = NSHostingView(rootView: playerView)
            lockWindow.contentView = hostView
        }
        
        lockScreenWindows[screen] = lockWindow
        
        // Verstecke Lock Screen Fenster initial (wird beim Sperren gezeigt)
        if !isLockScreenActive {
            lockWindow.orderOut(nil)
        } else {
            lockWindow.orderFront(nil)
        }
        
        print("✅ Lock Screen Wallpaper window erstellt für: \(screen.localizedName)")
    }
    
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
        
        // Close existing lock screen windows
        for (_, window) in lockScreenWindows {
            window.close()
        }
        lockScreenWindows.removeAll()
        
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
            
            // Add wallpaper content to desktop window
            if let player = player {
                let playerView = PlayerLayerView(player: player, video: video)
                let hostView = NSHostingView(rootView: playerView)
                newWindow.contentView = hostView
            }
            
            newWindow.makeKeyAndOrderFront(nil)
            
            windows[screen] = newWindow
            
            print("Created wallpaper window for screen: \(screen.localizedName) - Frame: \(screen.frame)")
            
            // Erstelle auch Lock Screen Fenster für jeden Screen
            let lockWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            lockWindow.isOpaque = false
            lockWindow.backgroundColor = .clear
            // Use a high window level to appear above lock screen
            lockWindow.level = NSWindow.Level(rawValue: 1000)
            lockWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            lockWindow.ignoresMouseEvents = true
            
            // Erstelle Lock Screen Fenster OHNE Content (wird später in setWallpaperVideo hinzugefügt)
            lockScreenWindows[screen] = lockWindow
            
            // Verstecke Lock Screen Fenster initial
            lockWindow.orderOut(nil)
            
            print("Created lock screen wallpaper window for screen: \(screen.localizedName)")
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
        
        // Update content for each window (Desktop)
        for (_, window) in windows {
            let playerView = PlayerLayerView(player: player!, video: video)
            let hostView = NSHostingView(rootView: playerView)
            animateContentViewTransition(window: window, newContentView: hostView)
        }
        
        // Update content for each lock screen window
        for (_, window) in lockScreenWindows {
            let playerView = PlayerLayerView(player: player!, video: video)
            let hostView = NSHostingView(rootView: playerView)
            animateContentViewTransition(window: window, newContentView: hostView)
        }
        
        updateWallpaperVisibility()
        
        // Extract first frame and set as macOS desktop wallpaper
        extractAndSetFirstFrame(from: url, video: video)
        
        player!.play()
    }
    
    // MARK: - macOS Desktop Wallpaper Integration
    
    /// Extrahiert den ersten Frame und setzt ihn als Desktop Wallpaper
    private func extractAndSetFirstFrame(from url: URL, video: Video) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                // Extrahiere Frame bei 0.1 Sekunden (nicht ganz am Anfang wegen Codec-Delays)
                let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 0.1, preferredTimescale: 600), actualTime: nil)
                let nsImage = NSImage(cgImage: cgImage, size: .zero)
                
                // Speichere die Thumbnail-Datei
                if let thumbnailURL = self?.saveThumbnail(nsImage, for: video) {
                    // Setze als Desktop Wallpaper
                    DispatchQueue.main.async {
                        self?.setDesktopWallpaper(imageURL: thumbnailURL)
                    }
                }
            } catch {
                print("❌ Fehler beim Extrahieren des Frames: \(error)")
            }
        }
    }
    
    /// Speichert die Thumbnail-Datei in der App Support Directory
    private func saveThumbnail(_ image: NSImage, for video: Video) -> URL? {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let wallpaperFolder = appSupportURL.appendingPathComponent("com.wallpaper.livewallpaper", isDirectory: true)
        
        // Erstelle Ordner, falls nicht vorhanden
        try? FileManager.default.createDirectory(at: wallpaperFolder, withIntermediateDirectories: true)
        
        // Generiere einen eindeutigen Namen basierend auf Video-URL
        let fileName = "wallpaper_\(video.url.hashValue).png"
        let fileURL = wallpaperFolder.appendingPathComponent(fileName)
        
        // Konvertiere NSImage zu PNG und speichere
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: fileURL)
                print("✅ Thumbnail gespeichert: \(fileURL.lastPathComponent)")
                return fileURL
            } catch {
                print("❌ Fehler beim Speichern des Thumbnails: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    /// Setzt das Bild als macOS Desktop Wallpaper (alle Screens)
    private func setDesktopWallpaper(imageURL: URL) {
        let screens = NSScreen.screens
        
        for screen in screens {
            do {
                try NSWorkspace.shared.setDesktopImageURL(
                    imageURL,
                    for: screen,
                    options: [:]
                )
                print("✅ Desktop Wallpaper gesetzt für: \(screen.localizedName)")
            } catch {
                print("❌ Fehler beim Setzen des Desktop Wallpapers: \(error)")
            }
        }
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
        
        Foundation.NotificationCenter.default.removeObserver(self)
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
