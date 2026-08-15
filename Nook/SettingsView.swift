import SwiftUI
import AppKit

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case notch = "Notch"
    case appearance = "Appearance"
    case nowPlaying = "Now Playing"
    case about = "About"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .notch: return "macbook.and.iphone"
        case .appearance: return "paintpalette"
        case .nowPlaying: return "play.circle"
        case .about: return "info.circle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .general: return .blue
        case .notch: return .indigo
        case .appearance: return .purple
        case .nowPlaying: return .pink
        case .about: return .gray
        }
    }
}

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label {
                        Text(tab.rawValue)
                    } icon: {
                        Image(systemName: tab.iconName)
                            .foregroundColor(tab.iconColor)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            VStack(spacing: 0) {
                HStack {
                    Text(selectedTab.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 6)
                
                Form {
                    switch selectedTab {
                    case .general:
                        Section {
                            Toggle("Expand on hover", isOn: $settings.expandOnHover)
                            Toggle("Keep open when clicked", isOn: $settings.keepOpenWhenClicked)
                            Toggle("Close when clicking outside", isOn: $settings.closeWhenClickingOutside)
                        } header: {
                            Text("Behaviour")
                        } footer: {
                            Text("Configure how Nook reacts to hovering, clicks, and background interactions.")
                        }
                        
                        Section {
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Hover sensitivity")
                                        Spacer()
                                        Text(sensitivityLabel(settings.hoverSensitivity))
                                            .foregroundColor(.secondary)
                                    }
                                    Slider(value: $settings.hoverSensitivity, in: 1.0...3.0, step: 1.0)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Animation speed")
                                        Spacer()
                                        Text(String(format: "%.1fx", settings.animationSpeed))
                                            .foregroundColor(.secondary)
                                    }
                                    Slider(value: $settings.animationSpeed, in: 0.5...2.0)
                                }
                            }
                            .listRowSeparator(.hidden)
                        } header: {
                            Text("Interaction")
                        } footer: {
                            Text("Adjust hover detection proximity threshold and transition speed.")
                        }
                        
                    case .notch:
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Horizontal Alignment")
                                    Spacer()
                                    Text("\(Int(settings.notchXOffset)) px \(settings.notchXOffset == 0 ? "(Centered)" : settings.notchXOffset < 0 ? "(Left)" : "(Right)")")
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $settings.notchXOffset, in: -150...150)
                                
                                HStack(spacing: 10) {
                                    Button(action: {
                                        settings.notchXOffset = max(-150, settings.notchXOffset - 5)
                                    }) {
                                        Label("Move Left", systemImage: "arrow.left")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button(action: {
                                        settings.notchXOffset = 0
                                    }) {
                                        Text("Center")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(settings.notchXOffset == 0)
                                    
                                    Button(action: {
                                        settings.notchXOffset = min(150, settings.notchXOffset + 5)
                                    }) {
                                        Label("Move Right", systemImage: "arrow.right")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.top, 2)
                            }
                            .listRowSeparator(.hidden)
                        } header: {
                            Text("Position & Alignment")
                        } footer: {
                            Text("Use the buttons or slider to nudge the notch position left or right across your screen in real time.")
                        }
                        
                        Section {
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Notch width offset")
                                        Spacer()
                                        Text("\(Int(settings.notchWidthOffset)) px")
                                            .foregroundColor(.secondary)
                                    }
                                    Slider(value: $settings.notchWidthOffset, in: -100...100)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Notch height offset")
                                        Spacer()
                                        Text("\(Int(settings.notchHeightOffset)) px")
                                            .foregroundColor(.secondary)
                                    }
                                    Slider(value: $settings.notchHeightOffset, in: -20...40)
                                }
                            }
                            .listRowSeparator(.hidden)
                        } header: {
                            Text("Dimensions")
                        } footer: {
                            Text("Fine-tune notch tray geometry and sizing.")
                        }
                        
                    case .appearance:
                        Section {
                            Picker("Appearance Mode", selection: $settings.themeMode) {
                                ForEach(AppThemeMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        } header: {
                            Text("Theme")
                        } footer: {
                            Text("Switch between crisp porcelain Light mode and deep OLED Dark mode.")
                        }
                        
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Accent Palette")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 14) {
                                    ForEach(AppAccentColor.allCases) { accent in
                                        Button(action: {
                                            settings.accentColor = accent
                                        }) {
                                            VStack(spacing: 6) {
                                                ZStack {
                                                    Circle()
                                                        .fill(accent.primaryColor(isDark: settings.isDarkMode))
                                                        .frame(width: 26, height: 26)
                                                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                                                    
                                                    if settings.accentColor == accent {
                                                        Circle()
                                                            .stroke(Color.primary, lineWidth: 2)
                                                            .frame(width: 34, height: 34)
                                                    }
                                                }
                                                .frame(width: 36, height: 36)
                                                
                                                Text(accent.rawValue)
                                                    .font(.system(size: 10, weight: settings.accentColor == accent ? .semibold : .regular))
                                                    .foregroundColor(settings.accentColor == accent ? .primary : .secondary)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                                    .frame(width: 58)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Colors")
                        } footer: {
                            Text("Tint the text, equalizer, media controls, and artwork accents.")
                        }
                        
                        Section {
                            Toggle("Contrast outline", isOn: $settings.contrastOutline)
                        } header: {
                            Text("Borders")
                        } footer: {
                            Text("Adds a subtle high-contrast border around the tray for bright wallpapers.")
                        }
                        
                    case .nowPlaying:
                        Section {
                            Toggle("Show album artwork", isOn: $settings.showAlbumArtwork)
                            Toggle("Show song title", isOn: $settings.showSongTitle)
                            Toggle("Show artist name", isOn: $settings.showArtistName)
                            Toggle("Show playback progress", isOn: $settings.showPlaybackProgress)
                            Toggle("Show media source", isOn: $settings.showMediaSource)
                            Toggle("Show waveform visualizer", isOn: $settings.nowPlayingVisualizer)
                        } header: {
                            Text("Display")
                        } footer: {
                            Text("Media source displays YouTube Music, Spotify, Apple Music, and web players.")
                        }
                        
                        Section {
                            Toggle("Show playback controls", isOn: $settings.showPlaybackControls)
                            Toggle("Show Previous / Next", isOn: $settings.showPreviousNext)
                                .disabled(!settings.showPlaybackControls)
                            Toggle("Show Play / Pause", isOn: $settings.showPlayPause)
                                .disabled(!settings.showPlaybackControls)
                            Toggle("Show headphone battery", isOn: $settings.showHeadphoneBattery)
                        } header: {
                            Text("Controls & Peripherals")
                        } footer: {
                            Text("Customize interactive playback buttons and connected Bluetooth audio battery status.")
                        }
                        
                    case .about:
                        Section {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Nook").font(.title3).bold()
                                Text("Version 1.0 (Build 2026)").font(.subheadline).foregroundColor(.secondary)
                                Divider()
                                    .padding(.vertical, 4)
                                Text("A sleek, native macOS notch utility.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .formStyle(.grouped)
            }
        }
        .frame(minWidth: 640, idealWidth: 700, minHeight: 500, idealHeight: 560)
    }
    
    private func sensitivityLabel(_ value: Double) -> String {
        if value <= 1.25 {
            return "Low"
        } else if value <= 2.25 {
            return "Medium"
        } else {
            return "High"
        }
    }
}
