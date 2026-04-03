import SwiftUI

struct ClockPreview: View {
    let config: ClockConfig
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                
                ClockDisplayView(config: config)
                    .scaleEffect(1.8)
            }
            .frame(height: 220)
        }
    }
}

#Preview {
    ClockPreview(config: ClockConfig.preview)
}
