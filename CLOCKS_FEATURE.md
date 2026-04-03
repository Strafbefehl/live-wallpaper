# Desktop Clocks Feature - Dokumentation

## Überblick

Die Desktop Clocks Funktion ermöglicht es dir, benutzerdefinierte Text-basierte Uhren direkt auf deinem macOS Schreibtisch anzuzeigen. Unterstützt digitale (12h/24h) und analoge Formate mit vollständig anpassbaren Schriftarten, Farben und Positionen.

## Features

✨ **Uhr-Formate:**
- Digitale 12-Stunden (z.B. 3:45 PM)
- Digitale 24-Stunden (z.B. 15:45)
- Analoge Uhren mit beweglichen Zeigern

🎨 **Anpassung:**
- Eigene Schriftart auswählen (System-Fonts: Monaco, Menlo, Helvetica, etc.)
- Schriftgröße anpassen (12-72 Punkte)
- Individuelle Farben für Text und Hintergrund
- Mehrere Positionsvorgaben (9 Positionen) oder benutzerdefinierte Position
- Deckkraft/Opacity einstellen
- Sekunden optional anzeigen

🖥️ **Desktop Integration:**
- Uhren laufen im Hintergrund (hinter anderen Fenstern)
- Startet automatisch beim App-Start
- Läuft über alle Workspaces hinweg
- Ignoriert Mausinteraktionen

💾 **Persistierung:**
- Alle Uhren-Konfigurationen werden automatisch gespeichert
- Aktive Uhr wird beim Neustart wiederhergestellt

## Verwendung

### Neue Uhr erstellen

1. Öffne die App und navigiere zum Tab **"Desktop Clocks"**
2. Klicke auf das **"+"** Symbol, um eine neue Uhr zu erstellen
3. Im **Customizer**:
   - Gib einen Namen für die Uhr ein
   - Wähle das gewünschte Format (Digital 12h, Digital 24h, oder Analog)
   - Wähle Schriftart und -größe
   - Passe Farben für Text und Hintergrund an
   - Wähle die Position auf dem Bildschirm
   - Schalte "Sekunden anzeigen" optional ein
   - Stelle die Deckkraft ein
   - Klicke "Save"

### Uhr auf dem Desktop anzeigen

1. In der Uhr-Liste findest du deine erstellte Uhr
2. Klicke das **Menu-Symbol** (⋯) und wähle **"Show on Desktop"**
3. Die Uhr erscheint sofort auf deinem Schreibtisch

### Uhr bearbeiten

1. Klicke das **Menu-Symbol** (⋯) auf der Uhr
2. Wähle **"Edit"**
3. Passe die gewünschten Einstellungen an
4. Klicke "Save"
5. Die Live-Anzeige wird automatisch aktualisiert

### Uhr duplizieren

1. Klicke das **Menu-Symbol** (⋯)
2. Wähle **"Duplicate"**
3. Eine Kopie mit dem Namen "(Copy)" wird erstellt

### Uhr löschen

1. Klicke das **Menu-Symbol** (⋯)
2. Wähle **"Delete"** (oder nutze Swipe-to-Delete in der Liste)
3. Die Uhr wird gelöscht

## Technische Details

### Dateistruktur

```
LiveWallpaper/
├── Models/
│   └── ClockConfig.swift           # Datenstrukturen
├── Singletons/
│   ├── ClockManager.swift          # Window & Timer Management
│   └── UserSetting.swift           # Erweitert mit Clocks
├── Components/
│   ├── DigitalClockView.swift      # Digitale Uhren-Anzeige
│   ├── AnalogClockView.swift       # Analoge Uhren-Anzeige
│   └── ClockDisplayView.swift      # Wrapper-View
└── Views/
    ├── ClockManagerView.swift      # Uhren-Verwaltungs-UI
    ├── ClockCustomizer.swift       # Bearbeiten/Erstellen Modal
    └── ClockPreview.swift          # Live-Vorschau
```

### Architektur

**ClockConfig:** Speichert alle Uhr-Parameter
- Format, Schriftart, Farben, Position
- Codable für JSON-Persistierung

**ClockManager:** Verwaltet Desktop-Fenster
- Erstellt/aktualisiert NSWindow auf Desktop-Ebene
- Timer für Sekunden-Updates (1Hz)
- Ignoriert Mausinteraktionen

**UserSetting:** Persistiert Konfiguration
- `@Published clocks: [ClockConfig]`
- `@Published activeClock: ClockConfig?`
- Automatische UserDefaults-Speicherung

**ClockManagerView:** Benutzeroberfläche
- Liste aller Uhren
- CRUD-Operationen (Create, Read, Update, Delete)
- Toggle zwischen Anzeigen/Verstecken

### Persistierung

Alle Daten werden in `UserDefaults` gespeichert:
- `clocks`: Array von ClockConfig als JSON
- `activeClock`: Aktuelle Uhr als JSON

Beim App-Start werden diese automatisch geladen.

## Tipps & Tricks

💡 **Best Practices:**
- Verwende große Schriftgrößen (48-72) für gute Sichtbarkeit
- Helle Farben auf dunklem Desktop: verwende weiße oder gelbe Text
- Analoge Uhren sehen gut in der rechten unteren oder oberen Ecke aus
- Nutze Semi-transparente Hintergründe für bessere Integration

🎨 **Design-Ideen:**
- Minimalistisch: Digitale Uhr, kleine Größe, weiße Farbe
- Retro: Analoge Uhr mit großer Größe
- Dual-Clock: Eine digitale und eine analoge Uhr an verschiedenen Positionen
- Nach Tageszeit: Nutze verschiedene Farben für verschiedene Uhren

## Bekannte Limitierungen

- Nur System-Fonts werden unterstützt (keine Custom-TTF-Upload im MVP)
- Keine Animation bei Analog-Zeiger-Bewegung (diskret aktualisiert)
- Maximum eine aktive Uhr auf dem Desktop gleichzeitig (kann erweitert werden)

## Zukünftige Verbesserungen

- [ ] Custom-Font-Upload (TTF/OTF)
- [ ] Mehrere aktive Uhren gleichzeitig
- [ ] Analog-Uhr Animation mit CADisplayLink
- [ ] Uhr-Themen speichern
- [ ] Größenänderung per Drag-Handle
- [ ] Position per Drag anpassen

---

**Viel Spaß mit deinen benutzerdefinierten Desktop-Uhren!** ⏰
