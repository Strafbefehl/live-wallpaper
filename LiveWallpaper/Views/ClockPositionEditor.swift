import SwiftUI

struct ClockPositionEditor: View {
    @Environment(\.dismiss) var dismiss
    @Binding var config: ClockConfig
    @State private var dragPosition: CGPoint = .zero
    @State private var isInitialized = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Edit Clock Position")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Drag the clock preview to position it on your desktop")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
            
            // Screen preview with draggable clock
            ZStack {
                // Desktop preview background
                Rectangle()
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .border(Color.gray, width: 2)
                
                // Position indicator grid
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            }
                        }
                    }
                }
                
                // Draggable clock preview
                VStack {
                    ClockDisplayView(config: config)
                        .frame(width: 220, height: 120)
                        .scaleEffect(1.3)
                        .offset(x: dragPosition.x, y: dragPosition.y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragPosition = CGPoint(
                                        x: value.location.x - 110,
                                        y: value.location.y - 60
                                    )
                                }
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 360)
            
            // Position info
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("X Position")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", dragPosition.x / 2 + 50))
                        .font(.system(size: 18, weight: .bold))
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Y Position")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", dragPosition.y / 1.5 + 50))
                        .font(.system(size: 18, weight: .bold))
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
            }
            
            // Preset positions
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Positions")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                VStack(spacing: 10) {
                    // Row 1
                    HStack(spacing: 10) {
                        ForEach([
                            (ClockPosition.topLeft, "↖\nTop Left"),
                            (ClockPosition.topCenter, "↑\nTop Center"),
                            (ClockPosition.topRight, "↗\nTop Right")
                        ], id: \.0) { position, label in
                            Button(action: {
                                config.position = position
                                config.customPosition = nil
                                let normalized = position.normalized
                                dragPosition = CGPoint(
                                    x: (normalized.x - 0.5) * 220,
                                    y: (normalized.y - 0.5) * 180
                                )
                            }) {
                                Text(label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(config.position == position ? Color.blue : Color(nsColor: .controlBackgroundColor))
                                    .foregroundColor(config.position == position ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Row 2
                    HStack(spacing: 10) {
                        ForEach([
                            (ClockPosition.centerLeft, "←\nCenter Left"),
                            (ClockPosition.center, "◉\nCenter"),
                            (ClockPosition.centerRight, "→\nCenter Right")
                        ], id: \.0) { position, label in
                            Button(action: {
                                config.position = position
                                config.customPosition = nil
                                let normalized = position.normalized
                                dragPosition = CGPoint(
                                    x: (normalized.x - 0.5) * 220,
                                    y: (normalized.y - 0.5) * 180
                                )
                            }) {
                                Text(label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(config.position == position ? Color.blue : Color(nsColor: .controlBackgroundColor))
                                    .foregroundColor(config.position == position ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Row 3
                    HStack(spacing: 10) {
                        ForEach([
                            (ClockPosition.bottomLeft, "↙\nBottom Left"),
                            (ClockPosition.bottomCenter, "↓\nBottom Center"),
                            (ClockPosition.bottomRight, "↘\nBottom Right")
                        ], id: \.0) { position, label in
                            Button(action: {
                                config.position = position
                                config.customPosition = nil
                                let normalized = position.normalized
                                dragPosition = CGPoint(
                                    x: (normalized.x - 0.5) * 220,
                                    y: (normalized.y - 0.5) * 180
                                )
                            }) {
                                Text(label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(config.position == position ? Color.blue : Color(nsColor: .controlBackgroundColor))
                                    .foregroundColor(config.position == position ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            
            Spacer()
            
            HStack(spacing: 14) {
                Button("Cancel") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .foregroundColor(.primary)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
                .font(.system(size: 15, weight: .semibold))
                
                Button("Save Position") {
                    // Convert drag position back to normalized coordinates
                    let normalizedX = dragPosition.x / 220 + 0.5
                    let normalizedY = dragPosition.y / 180 + 0.5
                    
                    config.position = .custom
                    config.customPosition = CGPoint(
                        x: max(0, min(1, normalizedX)),
                        y: max(0, min(1, normalizedY))
                    )
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .buttonStyle(.borderedProminent)
                .font(.system(size: 15, weight: .semibold))
            }
        }
        .padding(20)
        .frame(minWidth: 600, minHeight: 800)
        .onAppear {
            if !isInitialized {
                let position = config.customPosition ?? config.position.normalized
                dragPosition = CGPoint(
                    x: (position.x - 0.5) * 220,
                    y: (position.y - 0.5) * 180
                )
                isInitialized = true
            }
        }
    }
}

#Preview {
    ClockPositionEditor(config: .constant(ClockConfig.preview))
}
