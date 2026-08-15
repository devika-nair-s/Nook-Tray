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
            
            // Island Content (Album Art + Live Equalizer Waveform)
            HStack(spacing: 8) {
                if musicController.hasMedia {
                    // Mini Artwork
                    if settings.showAlbumArtwork {
                        if let artwork = musicController.albumArtwork {
                            Image(nsImage: artwork)
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
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                EqualizerBar(index: index, isPlaying: isPlaying, phase: phase)
            }
        }
        .onAppear {
            if isPlaying {
                withAnimation(Animation.linear(duration: 0.8).repeatForever(autoreverses: true)) {
                    phase = 1
                }
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                withAnimation(Animation.linear(duration: 0.8).repeatForever(autoreverses: true)) {
                    phase = 1
                }
            } else {
                withAnimation {
                    phase = 0
                }
            }
        }
    }
}

struct EqualizerBar: View {
    let index: Int
    let isPlaying: Bool
    let phase: CGFloat
    @ObservedObject private var settings = AppSettings.shared
    
    var height: CGFloat {
        if !isPlaying { return 3 }
        let heights: [CGFloat] = [4, 10, 7, 12]
        let altHeights: [CGFloat] = [11, 5, 12, 4]
        return heights[index] + (altHeights[index] - heights[index]) * phase
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(settings.currentPrimaryColor)
            .frame(width: 2, height: max(2, height))
            .animation(.easeInOut(duration: 0.25 + Double(index) * 0.08).repeatForever(autoreverses: true), value: phase)
    }
}

// MARK: - Hover State (140x45)
struct NookHoverBarView: View {
    @ObservedObject var musicController: MusicPlayerController
    @ObservedObject private var settings = AppSettings.shared
    let onExpand: () -> Void
    
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
                        if let artwork = musicController.albumArtwork {
                            Image(nsImage: artwork)
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
                    
                    Text("Nook")
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
        if let path = Bundle.main.path(forResource: "app_photo", ofType: "jpg"),
           let img = NSImage(contentsOfFile: path) {
            return img
        }
        if let img = NSImage(named: "app_photo") ?? NSImage(named: "AppIcon") {
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
                    // Album art (80x80)
                    if settings.showAlbumArtwork {
                        Group {
                            if let artwork = musicController.albumArtwork {
                                Image(nsImage: artwork)
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
                        
                        // Playback Progress Bar if enabled
                        if settings.showPlaybackProgress {
                            VStack(spacing: 3) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(settings.currentControlBg)
                                            .frame(height: 3.5)
                                        Capsule()
                                            .fill(settings.currentPrimaryColor)
                                            .frame(width: max(3.5, min(geo.size.width, geo.size.width * CGFloat(musicController.playbackProgress))), height: 3.5)
                                    }
                                }
                                .frame(height: 4)
                                
                                HStack {
                                    Text(formatTime(musicController.elapsedTime))
                                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                        .foregroundColor(settings.currentSecondaryColor)
                                    
                                    Spacer()
                                    
                                    if musicController.duration > 0 {
                                        Text(formatTime(musicController.duration))
                                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                            .foregroundColor(settings.currentSecondaryColor)
                                    }
                                }
                            }
                            .frame(maxWidth: 190)
                        }
                        
                        // Playback controls if enabled
                        if settings.showPlaybackControls {
                            HStack {
                                HStack(spacing: 16) {
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
                                                .frame(width: 36, height: 36)
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
                                
                                Spacer()
                                
                                if settings.showHeadphoneBattery {
                                    HeadphoneBatteryView(batteryManager: bluetoothManager)
                                }
                            }
                            .frame(maxWidth: 195)
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
                    
                    Text("Nook")
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
            HStack(spacing: 5) {
                Image(systemName: "headphones")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(settings.currentPrimaryColor)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(settings.currentControlBg)
                    )
                
                if isExpanded {
                    HStack(spacing: 4) {
                        Image(systemName: batteryIcon(for: batteryManager.batteryPercentage ?? 100))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(batteryColor(for: batteryManager.batteryPercentage ?? 100))
                        
                        Text(displayBatteryText)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(settings.currentPrimaryColor)
                    }
                    .padding(.trailing, 8)
                    .transition(.scale(scale: 0.85, anchor: .trailing).combined(with: .opacity))
                }
            }
            .padding(.trailing, isExpanded ? 2 : 0)
            .background(
                Capsule()
                    .fill(isExpanded ? settings.currentControlBg : Color.clear)
            )
            .contentShape(Capsule())
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
