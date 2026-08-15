import SwiftUI

struct NookContentView: View {
    let isExpanded: Bool
    let isLocked: Bool
    let onExpand: () -> Void
    let onClose: () -> Void
    @ObservedObject var musicController: MusicPlayerController
    
    var body: some View {
        ZStack {
            if isExpanded || isLocked {
                NookUnifiedBarView(
                    musicController: musicController,
                    showCloseButton: isLocked,
                    onExpand: onExpand,
                    onClose: onClose
                )
            } else {
                // Collapsed state - minimal pill right under camera notch
                Capsule()
                    .fill(Color.black.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
            }
        }
    }
}

// Unified bar view for both hover and extended states
struct NookUnifiedBarView: View {
    @ObservedObject var musicController: MusicPlayerController
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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 6)
            
            if musicController.hasMedia {
                HStack(spacing: 6) {
                    // Album art or music icon (30x30)
                    Group {
                        if let artwork = musicController.albumArtwork {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 30, height: 30)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                )
                        }
                    }
                    .onTapGesture {
                        onExpand()
                    }
                    
                    // Song title & artist (click to lock open)
                    VStack(alignment: .leading, spacing: 0.5) {
                        Text(musicController.songTitle)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(musicController.artist)
                            .font(.system(size: 8.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onExpand()
                    }
                    
                    // Playback controls
                    HStack(spacing: 2) {
                        // Previous
                        Button(action: { musicController.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Play / Pause
                        Button(action: { musicController.togglePlayPause() }) {
                            Image(systemName: musicController.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(
                                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                                        .fill(Color.white.opacity(0.32))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Next
                        Button(action: { musicController.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.leading, 6)
                .padding(.trailing, showCloseButton ? 12 : 5)
                .padding(.vertical, 6)
            } else {
                HStack(spacing: 8) {
                    if let photo = appPhoto {
                        Image(nsImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text("Nook")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
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
                                .font(.system(size: 5.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 11, height: 11)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.12))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 3)
                        .padding(.trailing, 4)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct GlassBackground: View {
    let cornerRadius: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.black.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}
