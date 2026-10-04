import Foundation
import SwiftData

enum SongDeletion {
    /// Removes a song everywhere: player queue, playlists, the library, and the audio file on disk.
    @MainActor
    static func delete(_ song: Song, modelContext: ModelContext, audioPlayer: AudioPlayerService) {
        // Capture what we need before the model is deleted.
        let fileURL = song.localFileURL
        let songID = song.id

        audioPlayer.remove(song)

        // Playlists keep their own list of songs, so take the song out of each one first.
        let playlists = (try? modelContext.fetch(FetchDescriptor<Playlist>())) ?? []
        for playlist in playlists where playlist.songs.contains(where: { $0.id == songID }) {
            playlist.songs.removeAll { $0.id == songID }
            playlist.refreshArtworkFromSongs()
        }

        modelContext.delete(song)

        do {
            try modelContext.save()
            // Only remove the file once the library change is saved.
            try? FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Musica could not delete the song: \(error)")
        }
    }
}
