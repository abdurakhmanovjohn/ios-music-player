import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @Query(sort: \Song.title) private var songs: [Song]
    @Query(sort: \Playlist.name) private var playlists: [Playlist]
    @StateObject private var viewModel = LibraryViewModel()
    @State private var isImporterPresented = false
    @State private var isPlaylistEditorPresented = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            List {
                if songs.isEmpty {
                    Section {
                        EmptyStateView(
                            systemImage: "tray.and.arrow.down.fill",
                            title: "No songs yet",
                            message: "Import MP3, M4A, AAC, or WAV files from Files to start listening.",
                            actionTitle: "Import Music"
                        ) {
                            isImporterPresented = true
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Songs") {
                    ForEach(songs) { song in
                        SongRowView(song: song, showsAlbum: true) {
                            audioPlayer.load(song, queue: songs)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                song.isFavorite.toggle()
                            } label: {
                                Label(song.isFavorite ? "Unfavorite" : "Favorite", systemImage: "heart.fill")
                            }
                            .tint(Color.musicaAccent)
                        }
                    }
                }

                Section("Albums") {
                    ForEach(viewModel.albums(from: songs)) { album in
                        NavigationLink {
                            SongCollectionView(
                                title: album.title,
                                subtitle: "\(album.artist) - \(album.songCountText)",
                                songs: album.songs
                            )
                        } label: {
                            AlbumRow(album: album)
                        }
                        .listRowBackground(Color.clear)
                    }
                }

                Section("Artists") {
                    ForEach(viewModel.artists(from: songs)) { artist in
                        NavigationLink {
                            SongCollectionView(
                                title: artist.name,
                                subtitle: "\(artist.albumCountText) - \(artist.songCountText)",
                                songs: artist.songs
                            )
                        } label: {
                            ArtistRow(artist: artist)
                        }
                        .listRowBackground(Color.clear)
                    }
                }

                Section("Playlists") {
                    if playlists.isEmpty {
                        Button {
                            isPlaylistEditorPresented = true
                        } label: {
                            Label("Create Playlist", systemImage: "plus")
                                .foregroundStyle(Color.musicaAccent)
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(playlists) { playlist in
                            NavigationLink {
                                PlaylistDetailView(playlist: playlist)
                            } label: {
                                PlaylistRow(playlist: playlist)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deletePlaylists)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.musicaBackground)
            .navigationTitle("Library")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isPlaylistEditorPresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create playlist")

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
                    importFiles(urls)
                }
            }
            .sheet(isPresented: $isPlaylistEditorPresented) {
                PlaylistEditorView()
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

    private func importFiles(_ urls: [URL]) {
        do {
            let importedSongs = try MusicImportService.shared.importFiles(from: urls, modelContext: modelContext)
            if let firstSong = importedSongs.first {
                let importedIDs = Set(importedSongs.map(\.id))
                let updatedQueue = importedSongs + songs.filter { !importedIDs.contains($0.id) }
                audioPlayer.load(firstSong, queue: updatedQueue, autoplay: false)
            }
        } catch {
            importError = error.localizedDescription
        }
    }

    private func deletePlaylists(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(playlists[index])
        }

        do {
            try modelContext.save()
        } catch {
            importError = error.localizedDescription
        }
    }
}

struct SongCollectionView: View {
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    let title: String
    let subtitle: String
    let songs: [Song]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        if let firstSong = songs.first {
                            audioPlayer.load(firstSong, queue: songs)
                        }
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.musicaAccent)
                    .padding(.top, 8)
                    .disabled(songs.isEmpty)
                }
                .padding(.vertical, 10)
                .listRowBackground(Color.clear)
            }

            Section("Songs") {
                ForEach(songs) { song in
                    SongRowView(song: song, showsAlbum: true) {
                        audioPlayer.load(song, queue: songs)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.musicaBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AlbumRow: View {
    let album: AlbumSummary

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(artworkData: album.artworkData, title: album.title, cornerRadius: 9)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(album.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                Text("\(album.artist) - \(album.songCountText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct ArtistRow: View {
    let artist: ArtistSummary

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.musicaElevated)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color.musicaSecondaryAccent)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(artist.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                Text("\(artist.albumCountText) - \(artist.songCountText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(artworkData: playlist.artworkData, title: playlist.name, cornerRadius: 9)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                Text(playlist.songCountText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
