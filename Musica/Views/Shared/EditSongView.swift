import SwiftUI
import SwiftData

struct EditSongView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var audioPlayer: AudioPlayerService

    let song: Song

    @State private var title: String
    @State private var artist: String
    @State private var album: String

    init(song: Song) {
        self.song = song
        _title = State(initialValue: song.title)
        // Show placeholders as empty fields so they're easy to type over.
        _artist = State(initialValue: song.artist == "Unknown Artist" ? "" : song.artist)
        _album = State(initialValue: song.album == "Unknown Album" ? "" : song.album)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $title, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("Details") {
                    TextField("Artist", text: $artist, prompt: Text("Unknown Artist"))
                    TextField("Album", text: $album, prompt: Text("Unknown Album"))
                }

                Section {
                    Text("Only the name shown in Musica changes. Your audio file stays untouched.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Color.musicaBackground)
            .navigationTitle("Edit Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        song.updateInfo(title: title, artist: artist, album: album)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save song info: \(error)")
        }

        // Keep the lock screen / Control Center in sync if this is the playing song.
        if audioPlayer.currentSong?.id == song.id {
            audioPlayer.refreshNowPlayingInfo()
        }

        dismiss()
    }
}
