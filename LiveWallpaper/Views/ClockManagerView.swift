import SwiftUI

struct ClockManagerView: View {
    @ObservedObject var userSetting = UserSetting.shared
    @State private var showingNewClockSheet = false
    @State private var editingClock: ClockConfig?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Desktop Clocks")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Manage your custom desktop clocks")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingNewClockSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                }
                .help("Add a new clock")
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .borderBottom(width: 1, color: Color.gray.opacity(0.2))
            
            if userSetting.clocks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No Clocks Added")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Create your first custom desktop clock")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    
                    Button(action: { showingNewClockSheet = true }) {
                        Text("Create Clock")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: 200)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(userSetting.clocks) { clock in
                        ClockRowView(
                            clock: clock,
                            isActive: userSetting.activeClock?.id == clock.id,
                            onActivate: {
                                userSetting.setActiveClock(clock)
                                ClockManager.shared.showClockWindow(with: clock)
                            },
                            onEdit: {
                                editingClock = clock
                            },
                            onDelete: {
                                userSetting.deleteClock(clock.id)
                                ClockManager.shared.hideClockWindow(for: clock.id)
                            },
                            onDuplicate: {
                                var newClock = clock
                                newClock.id = UUID().uuidString
                                newClock.name = clock.name + " (Copy)"
                                userSetting.addClock(newClock)
                            }
                        )
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let clock = userSetting.clocks[index]
                            userSetting.deleteClock(clock.id)
                            ClockManager.shared.hideClockWindow(for: clock.id)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewClockSheet) {
            ClockCustomizer(config: ClockConfig()) { newClock in
                userSetting.addClock(newClock)
            }
        }
        .sheet(item: $editingClock) { clock in
            ClockCustomizer(config: clock) { updatedClock in
                userSetting.updateClock(updatedClock)
                if userSetting.activeClock?.id == clock.id {
                    userSetting.setActiveClock(updatedClock)
                    ClockManager.shared.updateClockWindow(with: updatedClock)
                }
            }
        }
    }
}

struct ClockRowView: View {
    let clock: ClockConfig
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Status indicator
            Circle()
                .fill(isActive ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(clock.name)
                    .font(.system(size: 16, weight: .semibold))
                
                HStack(spacing: 10) {
                    Label(clock.format.rawValue, systemImage: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Label(clock.position.rawValue, systemImage: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isActive {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                    Text("Active")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            
            Menu {
                if !isActive {
                    Button(action: onActivate) {
                        Label("Show on Desktop", systemImage: "desktopcomputer")
                    }
                } else {
                    Button(role: .destructive, action: { onActivate() }) {
                        Label("Hide from Desktop", systemImage: "xmark.circle")
                    }
                }
                
                Divider()
                
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil.circle")
                }
                
                Button(action: onDuplicate) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                Divider()
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
}

#Preview {
    ClockManagerView()
}
