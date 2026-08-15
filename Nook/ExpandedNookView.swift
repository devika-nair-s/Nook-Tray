import SwiftUI

struct ExpandedNookView: View {
    let onClose: () -> Void
    @ObservedObject var musicController: MusicPlayerController
    
    var body: some View {
        ZStack {
            // Background card extending downward from under camera space
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 2, x: 0, y: 8)
            
            // Main content row
            HStack(spacing: 8) {
                // Artwork
                if let artwork = musicController.albumArtwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                // Title & Artist
                VStack(alignment: .leading, spacing: 1) {
                    Text(musicController.hasMedia ? musicController.songTitle : "Not Playing")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(musicController.hasMedia ? musicController.artist : "Nook")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                // Playback controls
                HStack(spacing: 4) {
                    // Previous
                    Button(action: { musicController.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Play / Pause
                    Button(action: { musicController.togglePlayPause() }) {
                        Image(systemName: musicController.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.white.opacity(0.32))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Next
                    Button(action: { musicController.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.trailing, 6)
            }
            .padding(.leading, 8)
            
            // Top-right corner close button
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
