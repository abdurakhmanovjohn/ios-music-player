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
    /// Path relative to the app's Documents folder, e.g. "Music/My Song.mp3".
    /// We store a relative path because the absolute container path can change
    /// after an app update or reinstall.
    var relativeFilePath: String
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
        relativeFilePath: String,
        dateAdded: Date = Date(),
        playCount: Int = 0,
        lastPlayedDate: Date? = nil,
        isFavorite: Bool = false
    ) {
        let fallbackTitle = URL(fileURLWithPath: relativeFilePath)
            .deletingPathExtension()
            .lastPathComponent

        self.id = id
        self.title = title.trimmedMusicText(fallback: fallbackTitle)
        self.artist = artist.trimmedMusicText(fallback: "Unknown Artist")
        self.album = album.trimmedMusicText(fallback: "Unknown Album")
        self.duration = duration
        self.artworkData = artworkData
        self.relativeFilePath = relativeFilePath
        self.dateAdded = dateAdded
        self.playCount = playCount
        self.lastPlayedDate = lastPlayedDate
        self.isFavorite = isFavorite
    }
}

extension Song {
    /// Resolved at access time, so it stays valid if the app container moves.
    var localFileURL: URL {
        URL.documentsDirectory.appending(path: relativeFilePath)
    }

    var displayArtist: String {
        artist.trimmedMusicText(fallback: "Unknown Artist")
    }

    var displayAlbum: String {
        album.trimmedMusicText(fallback: "Unknown Album")
    }

    var fileName: String {
        localFileURL.lastPathComponent
    }

    /// Updates the editable tags. Empty values fall back to the same defaults as import.
    func updateInfo(title: String, artist: String, album: String) {
        let fallbackTitle = URL(fileURLWithPath: relativeFilePath)
            .deletingPathExtension()
            .lastPathComponent

        self.title = title.trimmedMusicText(fallback: fallbackTitle)
        self.artist = artist.trimmedMusicText(fallback: "Unknown Artist")
        self.album = album.trimmedMusicText(fallback: "Unknown Album")
    }
}

private extension String {
    func trimmedMusicText(fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
