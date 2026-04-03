# 🎯 Multi-Desktop Support - QUICK START

## Was ist neu?

Deine Uhren können jetzt auf verschiedenen **Desktops (Spaces)** angezeigt werden!

## 3 Modi zur Auswahl

### 1️⃣ **All Spaces** 🌍
Uhr folgt dir auf **jeden Desktop**
```
Desktop 1: [🕐]
Desktop 2: [🕐]
Desktop 3: [🕐]
```

### 2️⃣ **Current Space** 📍
Uhr nur auf **aktuellem Desktop**
```
Desktop 1: [🕐] ← Nur wenn aktiv
Desktop 2: [ ]
Desktop 3: [🕐] ← Nur wenn aktiv
```

### 3️⃣ **Specific Spaces** 🎯
Du **wählst Desktops aus**
```
Desktop 1: [🕐] ✓ Ausgewählt
Desktop 2: [ ]
Desktop 3: [🕐] ✓ Ausgewählt
```

## So funktioniert's

### In der UI:

1. Öffne **Desktop Clocks** Tab
2. Klicke **"+"** für neue Uhr oder bearbeite existierende
3. Scrolle nach unten zu **"Desktop Configuration"**
4. Wähle einen Modus:
   - `All Spaces` (Standard)
   - `Current Space`
   - `Specific Spaces`
5. Wenn "Specific Spaces", wähle Desktops (1-4)
6. Klicke **Save**

### Im Code (falls du programmierst):

```swift
// Alle Desktops
var clock = ClockConfig()
clock.desktopMode = .allSpaces

// Nur aktueller Desktop
var clock = ClockConfig()
clock.desktopMode = .currentSpace

// Spezifische Desktops
var clock = ClockConfig()
clock.desktopMode = .specificSpaces
clock.visibleSpaces = [0, 2]  // Desktop 1 & 3
```

## Typische Use-Cases

### 📌 Globale Uhr
**Modus:** All Spaces  
**Warum:** Überall sichtbar für Zeitsynchronisation

### 🎯 Arbeits-Uhr
**Modus:** Specific Spaces  
**Warum:** Nur auf Work Desktops (z.B. 1 & 2)

### ⏰ Projekt-Timer
**Modus:** Current Space  
**Warum:** Nur wenn am Projekt arbeitest

## Neue Features

✨ **Automatisches Umschalten**
- Wechselst Desktop? System updatet automatisch

✨ **Multi-Window Support**
- Jede Uhr hat eigenes Fenster
- Mehrere Uhren gleichzeitig

✨ **Speichern & Laden**
- Einstellungen bleiben gespeichert
- Nach App-Neustart gleich wieder da

## FAQs

**F: Was passiert wenn ich "All Spaces" wähle?**  
A: Uhr folgt dir auf alle Desktops. Super für Systemzeit!

**F: Was wenn Desktop 2 & 4 verwenden, aber nur Desktop 1 auswählen?**  
A: Uhr erscheint nur auf Desktop 1. Nicht auf 2 & 4.

**F: Kann ich die Anzahl der Desktops ändern (mehr als 4)?**  
A: Im UI nur bis 4. Aber der Code unterstützt beliebig viele!

**F: Was mit "Current Space" bedeuten?**  
A: Uhr zeigt nur auf Desktop wo du gerade bist. Wenn wechselst → weg!

**F: Werden Einstellungen gespeichert?**  
A: Ja! App-Neustart → alles wie vorher!

## Troubleshooting

**Uhr nicht sichtbar auf Desktop?**
- Prüfe ob Modus korrekt: Desktop Configuration
- Check ob Desktop in "Specific Spaces" ausgewählt

**Uhr verschwindet beim Desktop-Wechsel?**
- Normal wenn "Current Space" eingestellt
- Öffne Edit → Ändere auf "All Spaces"

**Desktop-Modus Option nicht sichtbar?**
- Scrolle in Edit-Menü nach unten
- Sollte vor "Opacity" Slider sein

## Dateien die sich geändert haben

```
📝 ClockConfig.swift          ← Neue Desktop-Properties
📝 ClockManager.swift         ← Space-Monitoring
📝 ClockCustomizer.swift      ← Desktop-UI
📝 ClockManagerView.swift     ← Updates
📄 MULTI_DESKTOP_SUPPORT.md   ← Dokumentation
```

## Nächste Schritte

1. ✅ Builden (sollte 0 Fehler geben)
2. ✅ App starten
3. ✅ Neue Uhr mit "All Spaces" erstellen
4. ✅ Desktop wechseln → Uhr sollte da sein
5. ✅ Spielen mit verschiedenen Modi!

---

**Viel Spaß mit Multi-Desktop Support!** 🎉

Fragen? Lies:
- `MULTI_DESKTOP_SUPPORT.md` - Detaillierte Erklärung
- `MULTI_DESKTOP_IMPLEMENTATION.md` - Technische Details
