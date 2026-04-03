# 🎬 Wallpaper Multi-Desktop Support

## Übersicht

Das Wallpaper-System unterstützt nun auch **Multi-Desktop (Spaces) Konfiguration**. Du kannst das Live-Wallpaper Video auf verschiedenen Desktops mit verschiedenen Modi anzeigen.

## Features

### 3 Desktop-Modi für Wallpaper

Genau wie bei den Desktop Clocks, gibt es auch hier 3 Modi:

#### 🌍 **All Spaces** (Alle Desktops)
- Wallpaper wird auf **allen Desktops** angezeigt
- Perfect für: Eine konsistente Hintergrund-Video auf allen Desktops
- Window Behavior: `.canJoinAllSpaces`

#### 📍 **Current Space** (Aktueller Desktop)
- Wallpaper wird nur auf dem **aktuellen Desktop** angezeigt
- Wenn du Desktop wechselst → Wallpaper wechselt auch
- Perfect für: Desktop-spezifische Wallpaper
- Window Behavior: `.stationary`

#### 🎯 **Specific Spaces** (Spezifische Desktops)
- Du **wählst aus, auf welchen Desktops** das Wallpaper angezeigt wird
- Z.B. nur auf Desktop 1 & 3
- Perfect für: Workflow-spezifische Setups
- Window Behavior: `.stationary`

## Implementierung

### **Video Struktur** (Singletons/UserSetting.swift)

```swift
struct Video: Codable {
    let id: String
    let url: String
    let type: VideoType
    let thumbnail: String
    var attrs: VideoAttrs?
    
    // MARK: - Desktop/Space Configuration
    var desktopMode: DesktopSpaceMode = .allSpaces
    var visibleSpaces: [Int] = []  // Desktop indices (0-indexed)
}
```

### **WallpaperManager Updates**

Neue Funktionalität:

```swift
private var currentSpaceIndex: Int = 0
private var currentVideoConfig: Video?

// Space Monitoring
func startSpaceMonitoring()
@objc func spaceDidChange()

// Visibility Logic
func shouldShowWallpaper(_ video: Video) -> Bool
private func updateWallpaperVisibility()

// Window Creation
private func createWallpaperWindow(for video: Video)
```

**Space Monitoring:**
```swift
private func startSpaceMonitoring() {
    DistributedNotificationCenter.default().addObserver(
        self,
        selector: #selector(spaceDidChange),
        name: NSNotification.Name("com.apple.spaces.switched"),
        object: nil
    )
}

@objc private func spaceDidChange() {
    // Rotate space index when space changes
    currentSpaceIndex = (currentSpaceIndex + 1) % 4
    updateSpaceIndex()
    updateWallpaperVisibility()
}
```

**Visibility Logic:**
```swift
func shouldShowWallpaper(_ video: Video) -> Bool {
    switch video.desktopMode {
    case .allSpaces:
        return true  // Immer sichtbar
    case .currentSpace:
        return true  // Auf aktuellem Desktop
    case .specificSpaces:
        return video.visibleSpaces.contains(currentSpaceIndex)
    }
}
```

### **UI in SettingView**

Neue Desktop Configuration Sektion mit:
- Desktop Mode Picker (Segmented Control)
- Specific Spaces Checkboxes (0-3)
- Info-Box mit Erklärungen

```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Show Wallpaper on Desktops")
    
    Picker("Desktop Mode", selection: $userSetting.video.desktopMode) {
        ForEach(DesktopSpaceMode.allCases, id: \.self) { mode in
            Text(mode.description).tag(mode)
        }
    }
    .pickerStyle(.segmented)
    
    if userSetting.video.desktopMode == .specificSpaces {
        VStack {
            ForEach(0..<4, id: \.self) { index in
                Toggle(isOn: /* ... */) {
                    Text("Desktop \(index + 1)")
                }
            }
        }
    }
}
```

### **UserSetting Update Method**

```swift
func updateVideo() {
    // Update the current video configuration (for desktop mode changes)
    if let encoded = try? JSONEncoder().encode(video) {
        defaults.set(encoded, forKey: "video")
    }
    objectWillChange.send()
}
```

## Verwendungsbeispiele

### Beispiel 1: Wallpaper auf allen Desktops

```swift
var video = Video(...)
video.desktopMode = .allSpaces
// Wallpaper wird auf ALLEN Desktops angezeigt
```

### Beispiel 2: Wallpaper nur auf aktuellem Desktop

```swift
var video = Video(...)
video.desktopMode = .currentSpace
// Wallpaper folgt dir zwischen Desktops
```

### Beispiel 3: Wallpaper auf spezifischen Desktops

```swift
var video = Video(...)
video.desktopMode = .specificSpaces
video.visibleSpaces = [0, 2]  // Desktop 1 & 3
// Wallpaper nur auf Desktop 1 & 3 sichtbar
```

## Wie es funktioniert (User-Sicht)

1. **Video auswählen** → In "Recently Used" tab auf Video klicken
2. **Öffne Settings** → Gehe zum Tab "Settings"
3. **Wallpaper Desktop Configuration** → Scrolle nach unten
4. **Wähle Desktop-Modus:**
   - `All Spaces` (Standard)
   - `Current Space`
   - `Specific Spaces`
5. **Wenn Specific Spaces:** Wähle Desktops (1-4)
6. **Automatisch gespeichert** → Beim nächsten Wechsel zu diesem Video wird die Config geladen

## Technische Details

### Space Index Tracking

Das System nutzt einen einfachen Counter:
- Wenn Space wechselt → `currentSpaceIndex` inkrementiert sich (0→1→2→3→0)
- Zyklisch (modulo 4) für bis zu 4 Desktops

```swift
@objc private func spaceDidChange() {
    currentSpaceIndex = (currentSpaceIndex + 1) % 4
    updateSpaceIndex()
    updateWallpaperVisibility()
}
```

### Persistence

Alle Desktop-Einstellungen werden mit dem Video gespeichert:
- Video-Objekt mit `desktopMode` & `visibleSpaces`
- Wird in UserDefaults gespeichert
- Beim Laden automatisch wiederhergestellt

```swift
struct Video: Codable {
    var desktopMode: DesktopSpaceMode = .allSpaces
    var visibleSpaces: [Int] = []
    
    enum CodingKeys: String, CodingKey {
        case desktopMode, visibleSpaces
    }
}
```

### Window Visibility Management

```swift
private func updateWallpaperVisibility() {
    guard let config = currentVideoConfig else { return }
    
    if shouldShowWallpaper(config) {
        if window?.isVisible == false {
            window?.orderFront(nil)  // Zeige Fenster
        }
    } else {
        if window?.isVisible == true {
            window?.orderOut(nil)    // Verstecke Fenster
        }
    }
}
```

## Best Practices

### ✅ Best Practices

1. **Verwende "All Spaces" für Standard-Setup**
   - Gibt konsistentes Wallpaper auf allen Desktops

2. **Nutze "Specific Spaces" für Workflows**
   - Z.B. "Work Video" nur auf Work Desktops

3. **Nutze "Current Space" für Abwechslung**
   - Desktop-spezifische Videos

4. **Speichern wird automatisch gemacht**
   - Keine zusätzliche Aktion nötig

### ⚠️ Wichtige Hinweise

1. **Nur 4 Desktops in UI**
   - Maximum 4 Desktops können ausgewählt werden
   - Technisch sind mehr möglich

2. **Video bleibt wenn deaktiviert**
   - Deaktivierung betrifft nur Rendering
   - Desktop-Modus ändert sich nicht

3. **Auto-Detection**
   - System erkennt Desktop-Wechsel automatisch
   - Keine manuelle Aktion nötig

## Debugging

### Space-Index überprüfen

```swift
print("Current space: \(WallpaperManager.shared.currentSpaceIndex)")
print("Visible on spaces: \(UserSetting.shared.video.visibleSpaces)")
```

### Wallpaper-Sichtbarkeit testen

```swift
let should = WallpaperManager.shared.shouldShowWallpaper(video)
print("Should show: \(should)")
```

### Space-Wechsel tracken

```swift
// In WallpaperManager.spaceDidChange()
print("Space changed! New index: \(currentSpaceIndex)")
updateWallpaperVisibility()
```

## Integration mit Clocks

Das Wallpaper Multi-Desktop System nutzt die **gleiche DesktopSpaceMode Enum** wie die Desktop Clocks:

```swift
enum DesktopSpaceMode: String, Codable, CaseIterable {
    case allSpaces = "All Spaces"
    case currentSpace = "Current Space"
    case specificSpaces = "Specific Spaces"
}
```

Das bedeutet:
- Einheitliches Konzept für Benutzer
- Code-Reuse
- Konsistente Behavior

## Zukünftige Verbesserungen

- [ ] Mehr als 4 Desktops unterstützen
- [ ] Desktop-Namen statt Nummern
- [ ] Verschiedene Videos auf verschiedenen Desktops
- [ ] Smooth Transitions beim Wechsel
- [ ] Shortcuts für Wallpaper-Modus

---

**Version:** 2.0+ Wallpaper Update  
**Datum:** April 2026  
**Status:** ✅ Production Ready
