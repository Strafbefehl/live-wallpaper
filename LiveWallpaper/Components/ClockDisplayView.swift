import SwiftUI

struct ClockDisplayView: View {
    let config: ClockConfig
    
    var body: some View {
        ZStack {
            if config.format == .analog {
                AnalogClockView(config: config)
            } else {
                DigitalClockView(config: config)
            }
        }
    }
}

#Preview {
    ClockDisplayView(config: ClockConfig.preview)
}
