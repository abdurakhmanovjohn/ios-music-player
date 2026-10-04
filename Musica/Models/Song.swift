import Foundation
import SwiftData

@Model
final class Song {
    @Attribute(.unique) var id: UUID
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var artworkData: Data?
    var localFileURL: URL
    var dateAdded: Date
    var playCount: Int
    var lastPlayedDate: Date?
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "Unknown Artist",
        album: String = "Unknown Album",
        duration: TimeInterval,
        artworkData: Data? = nil,
        localFileURL: URL,
        dateAdded: Date = Date(),
        playCount: Int = 0,
        lastPlayedDate: Date? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title.trimmedMusicText(fallback: localFileURL.deletingPathExtension().lastPathComponent)
        self.artist = artist.trimmedMusicText(fallback: "Unknown Artist")
        self.album = album.trimmedMusicText(fallback: "Unknown Album")
        self.duration = duration
        self.artworkData = artworkData
        self.localFileURL = localFileURL
        self.dateAdded = dateAdded
        self.playCount = playCount
        self.lastPlayedDate = lastPlayedDate
        self.isFavorite = isFavorite
    }
}

extension Song {
    var displayArtist: String {
        artist.trimmedMusicText(fallback: "Unknown Artist")
    }

    var displayAlbum: String {
        album.trimmedMusicText(fallback: "Unknown Album")
    }

    var fileName: String {
        localFileURL.lastPathComponent
    }
}

private extension String {
    func trimmedMusicText(fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
