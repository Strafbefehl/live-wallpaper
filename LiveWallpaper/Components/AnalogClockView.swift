import SwiftUI

struct AnalogClockView: View {
    @ObservedObject var clockManager = ClockManager.shared
    let config: ClockConfig
    let size: CGFloat = 150
    
    var seconds: Double {
        Double(Calendar.current.component(.second, from: clockManager.currentTime))
    }
    
    var minutes: Double {
        Double(Calendar.current.component(.minute, from: clockManager.currentTime))
    }
    
    var hours: Double {
        Double(Calendar.current.component(.hour, from: clockManager.currentTime)) +
        (minutes / 60.0)
    }
    
    var body: some View {
        ZStack {
            // Clock face
            Circle()
                .fill(config.colors.backgroundSwiftUIColor)
                .frame(width: size, height: size)
            
            Circle()
                .stroke(config.colors.textSwiftUIColor, lineWidth: 2)
                .frame(width: size, height: size)
            
            // Hour markers
            ForEach(0..<12, id: \.self) { hour in
                VStack {
                    Text("\(hour == 0 ? 12 : hour)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(config.colors.textSwiftUIColor)
                    Spacer()
                }
                .frame(width: size, height: size)
                .rotationEffect(.degrees(Double(hour) * 30))
            }
            
            // Hour hand
            HStack {
                Spacer()
                VStack {
                    Rectangle()
                        .fill(config.colors.textSwiftUIColor)
                        .frame(width: 4, height: size * 0.25)
                    Spacer()
                }
                .frame(width: 4, height: size * 0.5)
                Spacer()
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(hours * 30))
            
            // Minute hand
            HStack {
                Spacer()
                VStack {
                    Rectangle()
                        .fill(config.colors.textSwiftUIColor)
                        .frame(width: 3, height: size * 0.35)
                    Spacer()
                }
                .frame(width: 3, height: size * 0.5)
                Spacer()
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(minutes * 6))
            
            // Second hand
            if config.displayOptions.showSeconds {
                HStack {
                    Spacer()
                    VStack {
                        Rectangle()
                            .fill(config.colors.textSwiftUIColor.opacity(0.7))
                            .frame(width: 1, height: size * 0.38)
                        Spacer()
                    }
                    .frame(width: 1, height: size * 0.5)
                    Spacer()
                }
                .frame(width: size, height: size)
                .rotationEffect(.degrees(seconds * 6))
            }
            
            // Center dot
            Circle()
                .fill(config.colors.textSwiftUIColor)
                .frame(width: 8, height: 8)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    AnalogClockView(config: ClockConfig.preview)
}
