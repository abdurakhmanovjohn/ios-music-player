import SwiftData
import SwiftUI

struct PlaylistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @State private var isEditorPresented = false
    let playlist: Playlist

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    ArtworkView(artworkData: playlist.artworkData, title: playlist.name, cornerRadius: 24)
                        .frame(width: 180, height: 180)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(playlist.name)
                            .font(.largeTitle.bold())
                            .lineLimit(2)

                        Text(playlist.songCountText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        if let firstSong = playlist.songs.first {
                            audioPlayer.load(firstSong, queue: playlist.songs)
                        }
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.musicaAccent)
                    .disabled(playlist.songs.isEmpty)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            Section("Songs") {
                if playlist.songs.isEmpty {
                    Text("This playlist does not have songs yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(playlist.songs) { song in
                        SongRowView(song: song, showsAlbum: true) {
                            audioPlayer.load(song, queue: playlist.songs)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                remove(song)
                            } label: {
                                Label("Remove", systemImage: "minus.circle")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.musicaBackground)
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditorPresented = true
                }
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            PlaylistEditorView(playlist: playlist)
        }
    }

    private func remove(_ song: Song) {
        playlist.songs.removeAll { $0.id == song.id }
        playlist.refreshArtworkFromSongs()

        do {
            try modelContext.save()
        } catch {
            print("Musica could not remove song from playlist: \(error.localizedDescription)")
        }
    }
}

struct PlaylistEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.title) private var songs: [Song]

    private let playlist: Playlist?
    @State private var name: String
    @State private var selectedSongIDs: Set<UUID>

    init(playlist: Playlist? = nil) {
        self.playlist = playlist
        _name = State(initialValue: playlist?.name ?? "")
        _selectedSongIDs = State(initialValue: Set(playlist?.songs.map(\.id) ?? []))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("Playlist Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    if songs.isEmpty {
                        EmptyStateView(
                            systemImage: "music.note.list",
                            title: "No songs to add",
                            message: "Import songs first, then come back to build playlists."
                        )
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(songs) { song in
                            Button {
                                toggle(song)
                            } label: {
                                HStack(spacing: 12) {
                                    ArtworkView(artworkData: song.artworkData, title: song.title, cornerRadius: 8)
                                        .frame(width: 44, height: 44)

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

                                    Spacer()

                                    Image(systemName: selectedSongIDs.contains(song.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(selectedSongIDs.contains(song.id) ? Color.musicaAccent : Color.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    HStack {
                        Text("Songs")
                        Spacer()
                        if !songs.isEmpty {
                            Text("\(selectedSongIDs.count) selected")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.musicaBackground)
            .navigationTitle(playlist == nil ? "New Playlist" : "Edit Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func toggle(_ song: Song) {
        if selectedSongIDs.contains(song.id) {
            selectedSongIDs.remove(song.id)
        } else {
            selectedSongIDs.insert(song.id)
        }
    }

    private func save() {
        let selectedSongs = songs.filter { selectedSongIDs.contains($0.id) }

        if let playlist {
            playlist.name = trimmedName
            playlist.songs = selectedSongs
            playlist.refreshArtworkFromSongs()
        } else {
            let playlist = Playlist(name: trimmedName)
            playlist.songs = selectedSongs
            playlist.refreshArtworkFromSongs()
            modelContext.insert(playlist)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Musica could not save playlist: \(error.localizedDescription)")
        }
    }
}
