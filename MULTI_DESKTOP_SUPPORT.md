# Multi-Desktop Support für Live Wallpaper Clocks

## Übersicht

Das Desktop Clocks System unterstützt nun **vollständig mehrere Desktops (Spaces)** auf macOS. Jede Uhr kann auf verschiedenen Desktops angezeigt werden mit verschiedenen Konfigurationsoptionen.

## Features

### 1. **Desktop-Modi**

Es gibt 3 verschiedene Modi, um zu steuern, auf welchen Desktops eine Uhr angezeigt wird:

#### 🌍 **All Spaces** (Alle Desktops)
- Die Uhr wird auf **allen Desktops** angezeigt
- Perfekt für wichtige Informationen, die immer sichtbar sein sollen
- Window Collection Behavior: `.canJoinAllSpaces`

#### 📍 **Current Space** (Aktueller Desktop)
- Die Uhr wird nur auf dem **aktuellen Desktop** angezeigt
- Wenn du einen Desktop wechselst, verschwindet die Uhr
- Perfekt für kontextabhängige Uhren
- Window Collection Behavior: `.stationary`

#### 🎯 **Specific Spaces** (Spezifische Desktops)
- Du kannst **genau auswählen, auf welchen Desktops** die Uhr angezeigt wird
- Wähle z.B. Desktop 1 & 3 aus
- Die Uhr wird nur auf diesen Desktops angezeigt
- Perfekt für Workflow-spezifische Uhren

### 2. **Space-Monitoring**

Das System überwacht automatisch:
- **Space-Wechsel:** Wenn du einen Desktop wechselst
- **Aktueller Space-Index:** Wird kontinuierlich aktualisiert
- **Window Visibility:** Passt automatisch an, welche Fenster sichtbar sein sollen

## Implementierung

### **ClockConfig** (Models/ClockConfig.swift)

```swift
struct ClockConfig: Identifiable, Codable, Equatable {
    // ...existing properties...
    
    // MARK: - Desktop/Space Configuration
    var desktopMode: DesktopSpaceMode = .allSpaces
    var visibleSpaces: [Int] = []  // Space indices (0-indexed)
}
```

**Desktop Space Mode Enum:**
```swift
enum DesktopSpaceMode: String, Codable, CaseIterable {
    case allSpaces = "All Spaces"
    case currentSpace = "Current Space"
    case specificSpaces = "Specific Spaces"
}
```

### **ClockManager** (Singletons/ClockManager.swift)

Neue Funktionen:

#### Space-Monitoring
```swift
func startSpaceMonitoring()  // Startet automatisches Space-Monitoring
func getActiveSpaceIndex() -> Int?  // Ruft aktuellen Space-Index ab
@objc func spaceDidChange()  // Callback wenn Desktop gewechselt wird
```

#### Window Management
```swift
func shouldShowClock(_ config: ClockConfig) -> Bool
// Prüft ob Uhr im aktuellen Space angezeigt werden soll

func showClockWindow(with config: ClockConfig)
// Erstellt und zeigt Fenster mit korrektem Collection Behavior

func hideClockWindow(for clockId: String)
// Versteckt Fenster für spezifische clockId

func hideAllClockWindows()
// Versteckt alle Fenster
```

#### Position & Opacity Updates
```swift
func updateClockPosition(for clockId: String, x: CGFloat, y: CGFloat)
func updateClockOpacity(for clockId: String, _ opacity: Double)
func updateWindowDuringDrag(for clockId: String, position: CGPoint)
```

### **ClockCustomizer** (Views/ClockCustomizer.swift)

Die neue Desktop Configuration UI zeigt:

1. **Desktop Mode Picker** - Auswahl zwischen den 3 Modi
2. **Specific Spaces Selection** - Nur sichtbar wenn "Specific Spaces" ausgewählt ist
3. **Info Text** - Erklärung der verschiedenen Modi
4. **Live Preview** - Zeigt sofort welche Desktops ausgewählt sind

```swift
// Desktop/Space Configuration
VStack(alignment: .leading, spacing: 16) {
    Text("Desktop Configuration")
    
    Picker("Desktop Mode", selection: $config.desktopMode) {
        ForEach(DesktopSpaceMode.allCases, id: \.self) { mode in
            Text(mode.description).tag(mode)
        }
    }
    
    if config.desktopMode == .specificSpaces {
        VStack {
            ForEach(0..<4, id: \.self) { index in
                Toggle(
                    isOn: .init(
                        get: { config.visibleSpaces.contains(index) },
                        set: { ... }
                    )
                ) {
                    Text("Desktop \(index + 1)")
                }
            }
        }
    }
}
```

## Verwendungsbeispiele

### Beispiel 1: Uhr auf allen Desktops

```swift
var clock = ClockConfig()
clock.name = "Global Clock"
clock.desktopMode = .allSpaces
// Uhr wird auf ALLEN Desktops angezeigt
```

### Beispiel 2: Uhr nur auf aktuellem Desktop

```swift
var clock = ClockConfig()
clock.name = "Current Space Clock"
clock.desktopMode = .currentSpace
// Uhr folgt dir, wenn du Desktop wechselst
```

### Beispiel 3: Uhr auf spezifischen Desktops

```swift
var clock = ClockConfig()
clock.name = "Work Clock"
clock.desktopMode = .specificSpaces
clock.visibleSpaces = [0, 1]  // Nur auf Desktop 1 & 2
// Uhr wird nur auf Desktop 1 & 2 angezeigt
```

## Technische Details

### Window Collection Behavior

Die Fenster verwenden verschiedene Collection Behaviors je nach Desktop-Modus:

| Modus | Behavior | Effekt |
|-------|----------|--------|
| All Spaces | `.canJoinAllSpaces` | Fenster folgt dir auf alle Desktops |
| Current Space | `.stationary` | Fenster bleibt auf aktuellem Desktop |
| Specific Spaces | `.stationary` | Fenster bleibt auf konfigurierten Desktops |

### Space Index Tracking

Das System nutzt `CGSCopyManagedDisplaySpaces()` um den aktuellen Space-Index zu ermitteln:

```swift
let spaces = CGSCopyManagedDisplaySpaces(CGSMainConnectionID())
for (index, space) in spaces.enumerated() {
    if let isActive = space["Current Space"] as? Bool, isActive {
        return index  // Aktueller Space
    }
}
```

### Space Change Notifications

Das System registriert sich für Benachrichtigungen:

```swift
DistributedNotificationCenter.default().addObserver(
    self,
    selector: #selector(spaceDidChange),
    name: NSNotification.Name("com.apple.spaces.switched"),
    object: nil
)
```

## Best Practices

### ✅ Best Practices

1. **Nutze "All Spaces" für wichtige Infos**
   - z.B. globale Systemzeit

2. **Nutze "Current Space" für kontextabhängige Uhren**
   - z.B. Projekt-spezifische Timer

3. **Nutze "Specific Spaces" für Workflow-Uhren**
   - z.B. "Arbeit" Uhr nur auf Work Desktops

4. **Teste alle Modi während der Konfiguration**
   - Öffne Edit Menü, stelle Modus ein, speichere
   - Wechsle Desktops und prüfe ob Uhr erscheint

### ⚠️ Wichtige Hinweise

1. **Max 4 Desktops**
   - System unterstützt bis zu 4 Desktops in der UI
   - Technisch sind mehr möglich mit Code-Änderung

2. **Space Indices sind 0-indexed**
   - Desktop 1 = Index 0
   - Desktop 2 = Index 1
   - etc.

3. **Performance**
   - Zu viele Uhren auf All Spaces kann Performance beeinflussen
   - Empfehlung: Max 3-4 Uhren mit All Spaces

## Debugging

### Space Index überprüfen

```swift
// In ClockManager:
print("Current space index: \(currentSpaceIndex)")
print("Visible spaces for clock: \(config.visibleSpaces)")
```

### Window Collection Behavior überprüfen

```swift
if let window = clockWindows[clockId] {
    print("Collection behavior: \(window.collectionBehavior)")
}
```

### Space Change Events tracken

```swift
@objc private func spaceDidChange() {
    print("Space changed!")
    print("New space index: \(currentSpaceIndex)")
    updateAllClockWindows()
}
```

## Zukünftige Verbesserungen

- [ ] Dynamische Space-Erkennung (automatisch verfügbare Spaces ermitteln)
- [ ] Space-Namen statt Nummern
- [ ] Space-übergreifender Modus (Uhr auf mehreren Spaces mit verschiedenen Layouts)
- [ ] Space-wechsel Animation
- [ ] Tastenkürzel für Space-spezifische Uhren

---

**Version:** 2.0+  
**Aktualisiert:** April 2026  
**Status:** ✅ Production Ready
