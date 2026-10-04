import Foundation
import SwiftData

@Model
final class Playlist {
    @Attribute(.unique) var id: UUID
    var name: String
    var artworkData: Data?
    var creationDate: Date

    @Relationship(deleteRule: .nullify)
    var songs: [Song] = []

    init(
        id: UUID = UUID(),
        name: String,
        artworkData: Data? = nil,
        creationDate: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Playlist" : name
        self.artworkData = artworkData
        self.creationDate = creationDate
    }
}

extension Playlist {
    var songCountText: String {
        songs.count == 1 ? "1 song" : "\(songs.count) songs"
    }

    func refreshArtworkFromSongs() {
        artworkData = songs.first(where: { $0.artworkData != nil })?.artworkData
    }
}
