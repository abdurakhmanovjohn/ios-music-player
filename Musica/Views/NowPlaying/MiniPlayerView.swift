import SwiftUI

// MARK: - Mini-player card

struct MiniPlayerView: View {
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @Binding var isNowPlayingPresented: Bool

    var body: some View {
        if let song = audioPlayer.currentSong {
            VStack(spacing: 10) {
                row(for: song)
                progressBar
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .modifier(MiniPlayerBackground())
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .onTapGesture { isNowPlayingPresented = true }
            .accessibilityElement(children: .contain)
        }
    }

    private func row(for song: Song) -> some View {
        HStack(spacing: 14) {
            ArtworkView(artworkData: song.artworkData, title: song.title, cornerRadius: 12)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(song.displayArtist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                audioPlayer.togglePlayPause()
            } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2.weight(.bold))
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)

            Button {
                audioPlayer.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2.weight(.semibold))
                    .frame(width: 44, height: 48)
            }
            .buttonStyle(.plain)
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule()
                    .fill(Color.musicaAccent)
                    .frame(width: proxy.size.width * progressFraction)
            }
        }
        .frame(height: 3)
    }

    private var progressFraction: Double {
        guard audioPlayer.duration > 0 else { return 0 }
        return min(max(audioPlayer.progress / audioPlayer.duration, 0), 1)
    }
}

// MARK: - Background (Liquid Glass on iOS 26+, material before that)

private struct MiniPlayerBackground: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 26))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
        }
    }
}

// MARK: - Placement above the tab bar

extension View {
    /// Docks the mini-player above the tab bar. Apply it to each tab's root view.
    func miniPlayerInset(isNowPlayingPresented: Binding<Bool>) -> some View {
        modifier(MiniPlayerInset(isNowPlayingPresented: isNowPlayingPresented))
    }
}

private struct MiniPlayerInset: ViewModifier {
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @Binding var isNowPlayingPresented: Bool

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if audioPlayer.currentSong != nil {
                    MiniPlayerView(isNowPlayingPresented: $isNowPlayingPresented)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: audioPlayer.currentSong?.id)
    }
}
