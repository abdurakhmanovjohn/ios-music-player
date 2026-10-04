import SwiftUI

struct NowPlayingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @State private var sliderValue: TimeInterval = 0
    @State private var isSeeking = false
    @State private var isShowingQueue = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.musicaScreenBackground
                    .ignoresSafeArea()

                VStack(spacing: 26) {
                    topBar

                    Spacer(minLength: 8)

                    ArtworkView(
                        artworkData: audioPlayer.currentSong?.artworkData,
                        title: audioPlayer.currentSong?.title ?? "Musica",
                        cornerRadius: 28
                    )
                    .frame(maxWidth: 330, maxHeight: 330)
                    .aspectRatio(1, contentMode: .fit)

                    songIdentity

                    progressSection

                    transportControls

                    Spacer(minLength: 12)

                    bottomControls
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
            }
            .onReceive(audioPlayer.$progress) { progress in
                if !isSeeking {
                    sliderValue = progress
                }
            }
            .sheet(isPresented: $isShowingQueue) {
                QueueView()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Now Playing")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                audioPlayer.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var songIdentity: some View {
        VStack(spacing: 7) {
            Text(audioPlayer.currentSong?.title ?? "Nothing Playing")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(audioPlayer.currentSong?.displayArtist ?? "Choose a song from your library")
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: {
                        isSeeking ? sliderValue : audioPlayer.progress
                    },
                    set: { newValue in
                        sliderValue = newValue
                    }
                ),
                in: 0...max(audioPlayer.duration, 1),
                onEditingChanged: { editing in
                    isSeeking = editing
                    if !editing {
                        audioPlayer.seek(to: sliderValue)
                    }
                }
            )
            .tint(Color.musicaAccent)

            HStack {
                Text((isSeeking ? sliderValue : audioPlayer.progress).musicaClockString)
                Spacer()
                Text("-\(remainingTime.musicaClockString)")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    private var transportControls: some View {
        HStack(spacing: 28) {
            Button {
                audioPlayer.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 30, weight: .semibold))
            }
            .buttonStyle(.plain)

            Button {
                audioPlayer.togglePlayPause()
            } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 74, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)

            Button {
                audioPlayer.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 30, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.primary)
    }

    private var bottomControls: some View {
        HStack {
            Button {
                audioPlayer.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(audioPlayer.isShuffleEnabled ? Color.musicaAccent : Color.secondary)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                audioPlayer.toggleRepeatMode()
            } label: {
                Image(systemName: audioPlayer.repeatMode.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(audioPlayer.repeatMode == .off ? Color.secondary : Color.musicaAccent)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                isShowingQueue = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
    }

    private var remainingTime: TimeInterval {
        max(audioPlayer.duration - (isSeeking ? sliderValue : audioPlayer.progress), 0)
    }
}

private struct QueueView: View {
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if audioPlayer.queue.isEmpty {
                    EmptyStateView(
                        systemImage: "list.bullet",
                        title: "Queue is empty",
                        message: "Play a song or album to build a queue."
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(audioPlayer.queue) { song in
                        SongRowView(song: song, showsAlbum: true) {
                            audioPlayer.load(song, queue: audioPlayer.queue)
                            dismiss()
                        }
                        .overlay(alignment: .trailing) {
                            if song.id == audioPlayer.currentSong?.id {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(Color.musicaAccent)
                                    .padding(.trailing, 72)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.musicaBackground)
            .navigationTitle("Queue")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
