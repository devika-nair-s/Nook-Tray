import SwiftUI

struct MusicWidgetView: View {
    @ObservedObject var musicController: MusicPlayerController
    
    var body: some View {
        VStack(spacing: 0) {
            if musicController.hasMedia {
                // Playing state
                HStack(spacing: 12) {
                    // Album artwork
                    if let artwork = musicController.albumArtwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: Color.black.opacity(0.32), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.thinMaterial)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                    
                    // Song info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(musicController.songTitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(musicController.artist)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                        
                        // Progress bar
                        VStack(spacing: 4) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(height: 3)
                                    
                                    // Progress
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.6))
                                        .frame(width: geometry.size.width * CGFloat(min(max(musicController.playbackProgress, 0), 1)), height: 3)
                                }
                            }
                            .frame(height: 3)
                            
                            // Time labels
                            HStack {
                                Text(formatTime(musicController.elapsedTime))
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.4))
                                
                                Spacer()
                                
                                Text(formatTime(musicController.duration))
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Playback controls
                HStack(spacing: 20) {
                    // Previous
                    ControlButton(
                        systemImage: "backward.fill",
                        size: 16,
                        disabled: musicController.isBrowserSource,
                        action: { musicController.previousTrack() }
                    )
                    
                    // Play/Pause
                    ControlButton(
                        systemImage: musicController.isPlaying ? "pause.circle.fill" : "play.circle.fill",
                        size: 32,
                        disabled: musicController.isBrowserSource,
                        action: { musicController.togglePlayPause() }
                    )
                    
                    // Next
                    ControlButton(
                        systemImage: "forward.fill",
                        size: 16,
                        disabled: musicController.isBrowserSource,
                        action: { musicController.nextTrack() }
                    )
                }
                .padding(.bottom, 12)
                
                // Show info for browser sources
                if musicController.isBrowserSource {
                    Text("Playing in browser (controls not available)")
                        .font(.system(size: 9, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.bottom, 8)
                }
            } else {
                // Not playing state
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.2))
                    
                    Text("Not Playing")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.16))
                )
        )
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// Control button with hover effect
struct ControlButton: View {
    let systemImage: String
    let size: CGFloat
    let disabled: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size))
                .foregroundColor(foregroundColor)
                .frame(width: size > 20 ? 42 : 30, height: size > 20 ? 42 : 30)
                .background(
                    Circle()
                        .fill(.thinMaterial)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(isHovered && !disabled ? 0.13 : 0.07))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(isHovered && !disabled ? 0.24 : 0.12), lineWidth: 0.7)
                        )
                )
                .scaleEffect(isHovered && !disabled ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var foregroundColor: Color {
        if disabled {
            return .white.opacity(size > 20 ? 0.4 : 0.3)
        }
        return .white.opacity(isHovered ? 1.0 : (size > 20 ? 0.9 : 0.7))
    }
}
