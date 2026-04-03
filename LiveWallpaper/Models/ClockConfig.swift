import SwiftUI
import Foundation

// MARK: - Desktop Space Configuration
enum DesktopSpaceMode: String, Codable, CaseIterable {
    case allSpaces = "All Spaces"
    case currentSpace = "Current Space"
    case specificSpaces = "Specific Spaces"
    
    var description: String {
        self.rawValue
    }
}

// MARK: - Clock Format
enum ClockFormat: String, Codable, CaseIterable {
    case digital12h = "Digital 12h"
    case digital24h = "Digital 24h"
    case analog = "Analog"
    
    var id: String {
        self.rawValue
    }
}

// MARK: - Clock Display Options
struct ClockDisplayOptions: Codable, Equatable {
    var showDate: Bool = true
    var showWeekday: Bool = true
    var showSeconds: Bool = false
    var showLargeDate: Bool = false  // Large date above time
    var dateFormat: String = "MMM dd"  // Default date format
    var weekdayFormat: String = "EEEE"  // Full weekday name
    var layout: TimeLayout = .timeOnly
    
    enum TimeLayout: String, Codable, CaseIterable {
        case timeOnly = "Time Only"
        case dateAbove = "Date Above"
        case dateBelow = "Date Below"
        case dateAside = "Date Aside"
    }
}

// MARK: - Clock Position Preset
enum ClockPosition: String, Codable, CaseIterable {
    case topLeft = "Top Left"
    case topCenter = "Top Center"
    case topRight = "Top Right"
    case centerLeft = "Center Left"
    case center = "Center"
    case centerRight = "Center Right"
    case bottomLeft = "Bottom Left"
    case bottomCenter = "Bottom Center"
    case bottomRight = "Bottom Right"
    case custom = "Custom"
    
    var normalized: CGPoint {
        switch self {
        case .topLeft: return CGPoint(x: 0.1, y: 0.9)
        case .topCenter: return CGPoint(x: 0.5, y: 0.9)
        case .topRight: return CGPoint(x: 0.9, y: 0.9)
        case .centerLeft: return CGPoint(x: 0.1, y: 0.5)
        case .center: return CGPoint(x: 0.5, y: 0.5)
        case .centerRight: return CGPoint(x: 0.9, y: 0.5)
        case .bottomLeft: return CGPoint(x: 0.1, y: 0.1)
        case .bottomCenter: return CGPoint(x: 0.5, y: 0.1)
        case .bottomRight: return CGPoint(x: 0.9, y: 0.1)
        case .custom: return CGPoint(x: 0.5, y: 0.5)
        }
    }
}

// MARK: - Clock Font Configuration
struct ClockFont: Codable, Equatable {
    var fontName: String
    var fontSize: CGFloat
    
    static let `default` = ClockFont(fontName: "Monaco", fontSize: 48)
    
    var nsFont: NSFont? {
        NSFont(name: fontName, size: fontSize)
    }
    
    var swiftUIFont: Font {
        Font.custom(fontName, size: fontSize)
    }
}

// MARK: - Clock Color Configuration
struct ClockColors: Codable, Equatable {
    var textColor: String  // Hex color string
    var backgroundColor: String  // Hex color string
    
    static let `default` = ClockColors(textColor: "#FFFFFF", backgroundColor: "#00000000")
    
    var textSwiftUIColor: Color {
        Color(hex: textColor) ?? .white
    }
    
    var backgroundSwiftUIColor: Color {
        Color(hex: backgroundColor) ?? .clear
    }
}

// MARK: - Main Clock Configuration
struct ClockConfig: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var format: ClockFormat
    var font: ClockFont
    var colors: ClockColors
    var position: ClockPosition
    var customPosition: CGPoint?  // Used when position == .custom
    var displayOptions: ClockDisplayOptions
    var opacity: Double
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Desktop/Space Configuration
    var desktopMode: DesktopSpaceMode = .allSpaces
    var visibleSpaces: [Int] = []  // Space indices (0-indexed)
    
    enum CodingKeys: String, CodingKey {
        case id, name, format, font, colors, position, customPosition
        case displayOptions, opacity, isEnabled, createdAt, updatedAt
        case desktopMode, visibleSpaces
    }
    
    init(
        id: String = UUID().uuidString,
        name: String = "My Clock",
        format: ClockFormat = .digital12h,
        font: ClockFont = .default,
        colors: ClockColors = .default,
        position: ClockPosition = .topRight,
        customPosition: CGPoint? = nil,
        displayOptions: ClockDisplayOptions = ClockDisplayOptions(),
        opacity: Double = 1.0,
        isEnabled: Bool = true,
        desktopMode: DesktopSpaceMode = .allSpaces,
        visibleSpaces: [Int] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.format = format
        self.font = font
        self.colors = colors
        self.position = position
        self.customPosition = customPosition
        self.displayOptions = displayOptions
        self.opacity = opacity
        self.isEnabled = isEnabled
        self.desktopMode = desktopMode
        self.visibleSpaces = visibleSpaces
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static let preview = ClockConfig(
        name: "Desktop Clock",
        format: .digital12h,
        position: .topRight
    )
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        
        guard hex.count == 6 || hex.count == 8 else { return nil }
        
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        
        guard scanner.scanHexInt64(&rgbValue) else { return nil }
        
        let r, g, b, a: Double
        if hex.count == 8 {
            r = Double((rgbValue >> 24) & 0xFF) / 255.0
            g = Double((rgbValue >> 16) & 0xFF) / 255.0
            b = Double((rgbValue >> 8) & 0xFF) / 255.0
            a = Double(rgbValue & 0xFF) / 255.0
        } else {
            r = Double((rgbValue >> 16) & 0xFF) / 255.0
            g = Double((rgbValue >> 8) & 0xFF) / 255.0
            b = Double(rgbValue & 0xFF) / 255.0
            a = 1.0
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components else { return "#FFFFFF" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        let a = components.count > 3 ? Int(components[3] * 255) : 255
        
        if a == 255 {
            return String(format: "#%02X%02X%02X", r, g, b)
        } else {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
    }
}

// MARK: - CGPoint Extension for comparison
extension CGPoint {
    func equalWithTolerance(to other: CGPoint, tolerance: CGFloat = 0.01) -> Bool {
        abs(self.x - other.x) < tolerance && abs(self.y - other.y) < tolerance
    }
}
