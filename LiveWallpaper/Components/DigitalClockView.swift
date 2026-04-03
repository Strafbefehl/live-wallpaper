import SwiftUI

struct DigitalClockView: View {
    @ObservedObject var clockManager = ClockManager.shared
    let config: ClockConfig
    
    var timeString: String {
        let formatter = DateFormatter()
        
        switch config.format {
        case .digital12h:
            formatter.dateFormat = config.displayOptions.showSeconds ? "h:mm:ss a" : "h:mm a"
        case .digital24h:
            formatter.dateFormat = config.displayOptions.showSeconds ? "HH:mm:ss" : "HH:mm"
        case .analog:
            return "" // Not used for digital
        }
        
        return formatter.string(from: clockManager.currentTime)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = config.displayOptions.dateFormat
        return formatter.string(from: clockManager.currentTime)
    }
    
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = config.displayOptions.weekdayFormat
        return formatter.string(from: clockManager.currentTime)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Large date above (if enabled)
            if config.displayOptions.showLargeDate && config.displayOptions.layout == .dateAbove {
                VStack(spacing: 2) {
                    if config.displayOptions.showWeekday {
                        Text(weekdayString)
                            .font(config.font.swiftUIFont)
                            .foregroundColor(config.colors.textSwiftUIColor)
                            .opacity(0.8)
                    }
                    Text(dateString)
                        .font(.system(size: config.font.fontSize * 0.6, weight: .bold))
                        .foregroundColor(config.colors.textSwiftUIColor)
                }
                .padding(.bottom, 4)
            }
            
            // Main time display
            Text(timeString)
                .font(config.font.swiftUIFont)
                .foregroundColor(config.colors.textSwiftUIColor)
            
            // Date and weekday (if enabled)
            if (config.displayOptions.showDate || config.displayOptions.showWeekday) && config.displayOptions.layout != .dateAbove {
                VStack(spacing: 2) {
                    if config.displayOptions.showWeekday {
                        Text(weekdayString)
                            .font(.caption)
                            .foregroundColor(config.colors.textSwiftUIColor)
                            .opacity(0.7)
                    }
                    if config.displayOptions.showDate {
                        Text(dateString)
                            .font(.caption)
                            .foregroundColor(config.colors.textSwiftUIColor)
                            .opacity(0.7)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(config.colors.backgroundSwiftUIColor)
        .cornerRadius(8)
    }
}

#Preview {
    DigitalClockView(config: ClockConfig.preview)
}
