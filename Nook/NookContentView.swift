import SwiftUI

struct NookContentView: View {
    let isExpanded: Bool
    let isLocked: Bool
    let onExpand: () -> Void
    let onClose: () -> Void
    @ObservedObject var musicController: MusicPlayerController
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        ZStack {
            if isLocked {
                NookUnifiedBarView(
                    musicController: musicController,
                    showCloseButton: true,
                    onExpand: onExpand,
                    onClose: onClose
                )
            } else if isExpanded {
                NookHoverBarView(
                    musicController: musicController,
                    onExpand: onExpand
                )
            } else {
                // Collapsed Notch Island - mini live activity with album art & equalizer
                NotchIslandCollapsedView(
                    musicController: musicController,
                    onExpand: onExpand
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Collapsed Notch Island View (Matching Screenshot Top Notch)
struct NotchIslandCollapsedView: View {
    @ObservedObject var musicController: MusicPlayerController
    @ObservedObject private var settings = AppSettings.shared
    let onExpand: () -> Void
    
    private var appPhoto: NSImage? {
        if let path = Bundle.main.path(forResource: "app_icon", ofType: "png"),
           let img = NSImage(contentsOfFile: path) {
            return img
        }
        if let img = NSImage(named: "app_icon") ?? NSImage(named: "AppIcon") {
            return img
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Tray Background
            TrayShape(cornerRadius: 8)
                .fill(settings.currentSurfaceColor)
                .overlay(
                    Group {
                        if settings.contrastOutline {
                            TrayShape(cornerRadius: 8)
                                .stroke(settings.currentOutlineColor, lineWidth: 0.75)
                        }
                    }
                )
                .shadow(color: Color.black.opacity(settings.isDarkMode ? 0.5 : 0.35), radius: 4, x: 0, y: 2)
            
            // Island Content (Album Art / App Icon + Live Equalizer Waveform)
            HStack(spacing: 8) {
                if musicController.hasMedia {
                    // Mini Artwork (Album Cover within 1 min of audio playing, else App Icon)
                    if settings.showAlbumArtwork {
                        if musicController.shouldShowAlbumCover, let artwork = musicController.albumArtwork {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 14, height: 14)
                                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                        } else if let appIcon = appPhoto {
                            Image(nsImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 14, height: 14)
                                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(settings.currentPrimaryColor)
                        }
                    }
                    
                    // Live Equalizer / Waveform
                    if settings.nowPlayingVisualizer {
                        NotchWaveformEqualizer(isPlaying: musicController.isPlaying)
                    }
                } else {
                    // Subtle idle indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(settings.currentPrimaryColor.opacity(0.6))
                            .frame(width: 3, height: 3)
                        Circle()
                            .fill(settings.currentPrimaryColor.opacity(0.3))
                            .frame(width: 3, height: 3)
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .clipShape(TrayShape(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            onExpand()
        }
    }
}

// MARK: - Animated Audio Waveform Equalizer
struct NotchWaveformEqualizer: View {
    let isPlaying: Bool
    
    var body: some View {
        if isPlaying {
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { index in
                        LiveEqualizerBar(index: index, time: time)
                    }
                }
            }
        } else {
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { _ in
                    StaticEqualizerBar()
                }
            }
        }
    }
}

struct LiveEqualizerBar: View {
    let index: Int
    let time: Double
    @ObservedObject private var settings = AppSettings.shared
    
    var height: CGFloat {
        let speed: Double = 6.0
        let offset = Double(index) * 1.4
        let wave = (sin(time * speed + offset) + 1.0) / 2.0 // normalized 0...1
        let minH: CGFloat = 3.0
        let maxH: CGFloat = index == 1 ? 12.0 : (index == 2 ? 10.0 : 8.0)
        return minH + CGFloat(wave) * (maxH - minH)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(settings.currentPrimaryColor)
            .frame(width: 2, height: height)
    }
}

struct StaticEqualizerBar: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(settings.currentPrimaryColor.opacity(0.35))
            .frame(width: 2, height: 2.5)
    }
}

// MARK: - Hover State (140x45)
struct NookHoverBarView: View {
    @ObservedObject var musicController: MusicPlayerController
    @ObservedObject private var settings = AppSettings.shared
    let onExpand: () -> Void
    
    private var appPhoto: NSImage? {
        if let path = Bundle.main.path(forResource: "app_icon", ofType: "png"),
           let img = NSImage(contentsOfFile: path) {
            return img
        }
        if let img = NSImage(named: "app_icon") ?? NSImage(named: "AppIcon") {
            return img
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            TrayShape(cornerRadius: 12)
                .fill(settings.currentSurfaceColor)
                .overlay(
                    TrayShape(cornerRadius: 12)
                        .stroke(settings.currentOutlineColor, lineWidth: settings.contrastOutline ? 0.75 : 0.5)
                )
                .shadow(color: Color.black.opacity(settings.isDarkMode ? 0.5 : 0.3), radius: 8, x: 0, y: 4)
            
            HStack(spacing: 8) {
                if musicController.hasMedia {
                    if settings.showAlbumArtwork {
                        if musicController.shouldShowAlbumCover, let artwork = musicController.albumArtwork {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 20, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(settings.currentPrimaryColor.opacity(0.15), lineWidth: 0.5)
                                )
                        } else if let appIcon = appPhoto {
                            Image(nsImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 20, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(settings.currentPrimaryColor.opacity(0.15), lineWidth: 0.5)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(settings.currentControlBg)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(settings.currentPrimaryColor)
                                )
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    if settings.nowPlayingVisualizer {
                        NotchWaveformEqualizer(isPlaying: musicController.isPlaying)
                    }
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(settings.currentPrimaryColor.opacity(0.8))
                    
                    Text("No Audio Playing")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(settings.currentPrimaryColor)
                        
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
        }
        .clipShape(TrayShape(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture {
            onExpand()
        }
    }
}

// MARK: - Unified Bar View for Hover & Extended States
struct NookUnifiedBarView: View {
    @ObservedObject var musicController: MusicPlayerController
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var bluetoothManager = BluetoothBatteryManager.shared
    let showCloseButton: Bool
    let onExpand: () -> Void
    let onClose: () -> Void
    
    private var appPhoto: NSImage? {
        if let path = Bundle.main.path(forResource: "app_icon", ofType: "png"),
           let img = NSImage(contentsOfFile: path) {
            return img
        }
        if let img = NSImage(named: "app_icon") ?? NSImage(named: "AppIcon") {
            return img
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Background card extending downward from under camera space
            TrayShape(cornerRadius: 36)
                .fill(settings.currentSurfaceColor)
                .overlay(
                    TrayShape(cornerRadius: 36)
                        .stroke(
                            settings.contrastOutline ? settings.currentOutlineColor : settings.currentOutlineColor.opacity(0.6),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(settings.isDarkMode ? 0.6 : 0.4), radius: 10, x: 0, y: 6)
            
            if musicController.hasMedia {
                HStack(spacing: 20) {
                    // Album art (shown up to 1 min after audio stops) or App icon (80x80)
                    if settings.showAlbumArtwork {
                        Group {
                            if musicController.shouldShowAlbumCover, let artwork = musicController.albumArtwork {
                                Image(nsImage: artwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: Color.black.opacity(settings.isDarkMode ? 0.4 : 0.15), radius: 8, x: 0, y: 4)
                            } else if let appIcon = appPhoto {
                                Image(nsImage: appIcon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: Color.black.opacity(settings.isDarkMode ? 0.4 : 0.15), radius: 8, x: 0, y: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(settings.currentControlBg)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundColor(settings.currentPrimaryColor.opacity(0.7))
                                    )
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Media Source badge if enabled
                        if settings.showMediaSource {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 9))
                                Text(musicController.formattedMediaSource)
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(settings.currentSecondaryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(settings.currentControlBg)
                            )
                        }
                        
                        // Song title & artist
                        VStack(alignment: .leading, spacing: 2) {
                            if settings.showSongTitle {
                                Text(musicController.songTitle.isEmpty ? "No Track Playing" : musicController.songTitle)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(settings.currentPrimaryColor)
                                    .lineLimit(1)
                            }
                            
                            if settings.showArtistName {
                                Text(musicController.artist.isEmpty ? "Media Player" : musicController.artist)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(settings.currentSecondaryColor)
                                    .lineLimit(1)
                            }
                        }
                        
                        // Playback controls if enabled
                        if settings.showPlaybackControls {
                            HStack(spacing: 12) {
                                HStack(spacing: 14) {
                                    if settings.showPreviousNext {
                                        Button(action: { musicController.previousTrack() }) {
                                            Image(systemName: "backward.fill")
                                                .font(.system(size: 13))
                                                .foregroundColor(settings.currentPrimaryColor.opacity(0.85))
                                                .frame(width: 26, height: 26)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    if settings.showPlayPause {
                                        Button(action: { musicController.togglePlayPause() }) {
                                            Image(systemName: musicController.isPlaying ? "pause.fill" : "play.fill")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(settings.currentPrimaryColor)
                                                .frame(width: 34, height: 34)
                                                .background(
                                                    Circle()
                                                        .fill(settings.currentControlBg)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    if settings.showPreviousNext {
                                        Button(action: { musicController.nextTrack() }) {
                                            Image(systemName: "forward.fill")
                                                .font(.system(size: 13))
                                                .foregroundColor(settings.currentPrimaryColor.opacity(0.85))
                                                .frame(width: 26, height: 26)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                Spacer(minLength: 4)
                                
                                if settings.showHeadphoneBattery {
                                    HeadphoneBatteryView(batteryManager: bluetoothManager)
                                }
                            }
                            .frame(maxWidth: 220)
                        }
                    }
                    Spacer()
                }
                .padding(.leading, 26)
                .padding(.top, 12)
            } else {
                HStack(spacing: 8) {
                    if let photo = appPhoto {
                        Image(nsImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(settings.currentPrimaryColor.opacity(0.7))
                    }
                    
                    Text("No Audio Playing")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(settings.currentPrimaryColor)
                }
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    onExpand()
                }
            }
            
            // Top-right corner close button (only shown when extended/locked)
            if showCloseButton {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(settings.currentSecondaryColor)
                                .frame(width: 16, height: 16)
                                .background(
                                    Circle()
                                        .fill(settings.currentControlBg)
                                    )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 6)
                        .padding(.trailing, 6)
                    }
                    Spacer()
                }
            }
        }
        .clipShape(TrayShape(cornerRadius: 36))
    }
}

private func formatTime(_ seconds: Double) -> String {
    guard !seconds.isNaN && seconds >= 0 else { return "0:00" }
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}

struct TrayShape: Shape {
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at Top-Left (flat)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Line to Top-Right (flat)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Line down to Bottom-Right (before curve)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        
        // Curve to Bottom-Right
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)
        
        // Line left to Bottom-Left (before curve)
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        
        // Curve to Bottom-Left
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Bluetooth Headphone Battery Indicator
struct HeadphoneBatteryView: View {
    @ObservedObject var batteryManager: BluetoothBatteryManager
    @ObservedObject private var settings = AppSettings.shared
    @State private var isExpanded: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "headphones")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(settings.currentPrimaryColor)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(settings.currentControlBg)
                    )
                    .layoutPriority(1)
                
                if isExpanded {
                    HStack(spacing: 4) {
                        Image(systemName: batteryIcon(for: batteryManager.batteryPercentage ?? 100))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(batteryColor(for: batteryManager.batteryPercentage ?? 100))
                            .layoutPriority(1)
                        
                        Text(displayBatteryText)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(settings.currentPrimaryColor)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    .padding(.trailing, 6)
                    .transition(.scale(scale: 0.85, anchor: .trailing).combined(with: .opacity))
                }
            }
            .padding(.trailing, isExpanded ? 4 : 0)
            .background(
                Capsule()
                    .fill(isExpanded ? settings.currentControlBg : Color.clear)
            )
            .contentShape(Capsule())
            .fixedSize(horizontal: true, vertical: true)
        }
        .buttonStyle(PlainButtonStyle())
        .help(batteryManager.isConnected ? (batteryManager.deviceName.isEmpty ? "Bluetooth Headset" : batteryManager.deviceName) : "No Bluetooth Headset Connected")
    }
    
    private var displayBatteryText: String {
        if !batteryManager.batteryFormattedText.isEmpty {
            return batteryManager.batteryFormattedText
        } else if let pct = batteryManager.batteryPercentage {
            return "\(pct)%"
        } else if batteryManager.isConnected {
            return "Connected"
        } else {
            return "No Device"
        }
    }
    
    private func batteryIcon(for level: Int) -> String {
        if level >= 80 {
            return "battery.100"
        } else if level >= 55 {
            return "battery.75"
        } else if level >= 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }
    
    private func batteryColor(for level: Int) -> Color {
        if level <= 20 {
            return .red
        } else {
            return settings.currentPrimaryColor.opacity(0.9)
        }
    }
}
