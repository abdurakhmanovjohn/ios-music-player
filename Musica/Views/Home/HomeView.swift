import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @Query(sort: \Song.dateAdded, order: .reverse) private var songs: [Song]
    @Query(sort: \Playlist.creationDate, order: .reverse) private var playlists: [Playlist]
    @StateObject private var viewModel = HomeViewModel()
    @State private var isImporterPresented = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if songs.isEmpty {
                        EmptyStateView(
                            systemImage: "music.note.list",
                            title: "Build your library",
                            message: "Import audio files you own from Files and Musica will keep them ready for offline playback.",
                            actionTitle: "Import Music"
                        ) {
                            isImporterPresented = true
                        }
                    }

                    songShelf(
                        title: "Recently Played",
                        songs: viewModel.recentlyPlayed(from: songs),
                        emptyMessage: "Songs you play will appear here."
                    )

                    songShelf(
                        title: "Recently Added",
                        songs: viewModel.recentlyAdded(from: songs),
                        emptyMessage: "New imports will land here first."
                    )

                    songShelf(
                        title: "Favorites",
                        songs: viewModel.favorites(from: songs),
                        emptyMessage: "Favorite a song to make it easier to find."
                    )

                    playlistShelf
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(LinearGradient.musicaScreenBackground.ignoresSafeArea())
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isImporterPresented = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("Import music")
                }
            }
            .sheet(isPresented: $isImporterPresented) {
                MusicFilePicker { urls in
                    Task { await importFiles(urls) }
                }
            }
            .alert("Import failed", isPresented: importErrorBinding) {
                Button("OK") {
                    importError = nil
                }
            } message: {
                Text(importError ?? "")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Your music, stored locally and ready offline.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var playlistShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Playlists")
                .font(.title2.bold())

            if playlists.isEmpty {
                Text("Playlists you create will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.musicaElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(playlists.prefix(10)) { playlist in
                            NavigationLink {
                                PlaylistDetailView(playlist: playlist)
                            } label: {
                                PlaylistCard(playlist: playlist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, 20)
                }
            }
        }
    }

    private func songShelf(title: String, songs shelfSongs: [Song], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title2.bold())

            if shelfSongs.isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.musicaElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(shelfSongs) { song in
                            SongCard(song: song) {
                                audioPlayer.load(song, queue: songs)
                            }
                        }
                    }
                    .padding(.trailing, 20)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "Late Night Listening"
        }
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { isPresented in
                if !isPresented {
                    importError = nil
                }
            }
        )
    }

    private func importFiles(_ urls: [URL]) async {
        do {
            let importedSongs = try await MusicImportService.shared.importFiles(from: urls, modelContext: modelContext)
            if let firstSong = importedSongs.first {
                let importedIDs = Set(importedSongs.map(\.id))
                let updatedQueue = importedSongs + songs.filter { !importedIDs.contains($0.id) }
                audioPlayer.load(firstSong, queue: updatedQueue, autoplay: false)
            }
        } catch {
            importError = error.localizedDescription
        }
    }
}

private struct SongCard: View {
    let song: Song
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                ArtworkView(artworkData: song.artworkData, title: song.title, cornerRadius: 18)
                    .frame(width: 150, height: 150)

                Text(song.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(song.displayArtist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 150, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ArtworkView(artworkData: playlist.artworkData, title: playlist.name, cornerRadius: 18)
                .frame(width: 150, height: 150)

            Text(playlist.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(playlist.songCountText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 150, alignment: .leading)
    }
}
