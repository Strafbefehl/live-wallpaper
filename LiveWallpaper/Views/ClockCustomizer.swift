import SwiftUI

struct ClockCustomizer: View {
    @Environment(\.dismiss) var dismiss
    @State var config: ClockConfig
    @State private var showingEditMode = false
    
    let onSave: (ClockConfig) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview - Large
                    VStack(spacing: 12) {
                        Text("Preview")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(nsColor: .controlBackgroundColor))
                            
                            ClockDisplayView(config: config)
                                .scaleEffect(1.5)
                        }
                        .frame(height: 280)
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(12)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Clock Name
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Clock Name")
                            .font(.title3)
                            .fontWeight(.semibold)
                        TextField("My Clock", text: $config.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 16))
                            .padding(.vertical, 6)
                    }
                    
                    // Format Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Format")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Picker("Format", selection: $config.format) {
                            ForEach(ClockFormat.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(height: 36)
                    }
                    
                    // Font Selection - FIXED
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Font Settings")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        // Font Name Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Font Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Picker("Font Name", selection: $config.font.fontName) {
                                ForEach(getAvailableFonts(), id: \.self) { fontName in
                                    Text(fontName).tag(fontName)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(height: 36)
                            .padding(.vertical, 4)
                        }
                        
                        // Font Size
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Font Size")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                Text("\(Int(config.font.fontSize))pt")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            Slider(
                                value: $config.font.fontSize,
                                in: 12...72,
                                step: 2
                            )
                            .frame(height: 24)
                        }
                    }
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Colors")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        // Text Color
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Text Color")
                                .font(.system(size: 14, weight: .semibold))
                            HStack(spacing: 16) {
                                ColorPicker(
                                    "Select",
                                    selection: .init(
                                        get: { config.colors.textSwiftUIColor },
                                        set: { newColor in
                                            config.colors.textColor = newColor.toHex()
                                        }
                                    ),
                                    supportsOpacity: false
                                )
                                .frame(width: 60, height: 60)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hex: \(config.colors.textColor)")
                                        .font(.caption)
                                        .monospaced()
                                    Text("Current color for text")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // Background Color
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Background Color")
                                .font(.system(size: 14, weight: .semibold))
                            HStack(spacing: 16) {
                                ColorPicker(
                                    "Select",
                                    selection: .init(
                                        get: { config.colors.backgroundSwiftUIColor },
                                        set: { newColor in
                                            config.colors.backgroundColor = newColor.toHex()
                                        }
                                    ),
                                    supportsOpacity: true
                                )
                                .frame(width: 60, height: 60)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hex: \(config.colors.backgroundColor)")
                                        .font(.caption)
                                        .monospaced()
                                    Text("Background (with transparency)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // Layout Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Layout")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Picker("Layout", selection: $config.displayOptions.layout) {
                            ForEach(ClockDisplayOptions.TimeLayout.allCases, id: \.self) { layout in
                                Text(layout.rawValue).tag(layout)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(height: 36)
                    }
                    
                    // Display Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Display Options")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 14) {
                            Toggle(isOn: $config.displayOptions.showSeconds) {
                                HStack(spacing: 12) {
                                    Image(systemName: "stopwatch")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Show Seconds")
                                        .font(.system(size: 15))
                                }
                            }
                            .toggleStyle(.checkbox)
                            
                            Toggle(isOn: $config.displayOptions.showDate) {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Show Date")
                                        .font(.system(size: 15))
                                }
                            }
                            .toggleStyle(.checkbox)
                            
                            Toggle(isOn: $config.displayOptions.showWeekday) {
                                HStack(spacing: 12) {
                                    Image(systemName: "book")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Show Weekday")
                                        .font(.system(size: 15))
                                }
                            }
                            .toggleStyle(.checkbox)
                            
                            if config.displayOptions.layout == .dateAbove {
                                Toggle(isOn: $config.displayOptions.showLargeDate) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "text.justify")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Large Date Above")
                                            .font(.system(size: 15))
                                    }
                                }
                                .toggleStyle(.checkbox)
                            }
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // Date Format
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date Format")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Picker("Date Format", selection: $config.displayOptions.dateFormat) {
                            Text("Jan 15").tag("MMM dd")
                            Text("15.01").tag("dd.MM")
                            Text("Jan 15, 2026").tag("MMM dd, yyyy")
                            Text("01/15/2026").tag("MM/dd/yyyy")
                            Text("2026-01-15").tag("yyyy-MM-dd")
                        }
                        .pickerStyle(.menu)
                        .frame(height: 36)
                    }
                    
                    // Position Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Position")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Picker("Position", selection: $config.position) {
                            ForEach(ClockPosition.allCases, id: \.self) { position in
                                Text(position.rawValue).tag(position)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(height: 36)
                        
                        Button(action: { showingEditMode = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Edit Position with Drag")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Opacity
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Opacity")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(Int(config.opacity * 100))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        Slider(value: $config.opacity, in: 0.1...1.0, step: 0.1)
                            .frame(height: 24)
                    }
                    
                    // Desktop/Space Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Desktop Configuration")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        // Desktop Mode Selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Show on Desktops")
                                .font(.system(size: 14, weight: .semibold))
                            Picker("Desktop Mode", selection: $config.desktopMode) {
                                ForEach(DesktopSpaceMode.allCases, id: \.self) { mode in
                                    Text(mode.description).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(height: 36)
                        }
                        
                        // Specific Spaces Selection (only show if specificSpaces mode)
                        if config.desktopMode == .specificSpaces {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Specific Desktops")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 10) {
                                    ForEach(0..<4, id: \.self) { index in
                                        HStack(spacing: 12) {
                                            Toggle(
                                                isOn: .init(
                                                    get: { config.visibleSpaces.contains(index) },
                                                    set: { isSelected in
                                                        if isSelected {
                                                            config.visibleSpaces.append(index)
                                                        } else {
                                                            config.visibleSpaces.removeAll { $0 == index }
                                                        }
                                                    }
                                                )
                                            ) {
                                                HStack(spacing: 10) {
                                                    Image(systemName: "square.grid.2x2")
                                                        .font(.system(size: 16, weight: .semibold))
                                                    Text("Desktop \(index + 1)")
                                                        .font(.system(size: 15))
                                                }
                                            }
                                            .toggleStyle(.checkbox)
                                        }
                                        .padding(10)
                                        .background(Color(nsColor: .controlBackgroundColor))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // Info text
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Desktop Modes:")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("All Spaces: Show on all desktops • Current Space: Show only on current desktop • Specific Spaces: Choose which desktops")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(14)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                    
                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .navigationTitle("Customize Clock")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(config)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .disabled(config.name.isEmpty)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 900)
        .sheet(isPresented: $showingEditMode) {
            ClockPositionEditor(config: $config)
        }
    }
    
    private func getAvailableFonts() -> [String] {
        let systemFonts = [
            "Monaco",
            "Menlo",
            "Courier New",
            "Courier",
            "Helvetica",
            "Helvetica Neue",
            "Arial",
            "Times New Roman",
            "Georgia",
            "Verdana",
            "Trebuchet MS",
            "Comic Sans MS"
        ]
        return systemFonts.filter { NSFont(name: $0, size: 12) != nil }
    }
}

#Preview {
    ClockCustomizer(config: ClockConfig.preview) { _ in }
}
