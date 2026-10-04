import Foundation

struct AlbumSummary: Identifiable {
    let title: String
    let artist: String
    let songs: [Song]
    let artworkData: Data?

    var id: String {
        "\(title.lowercased())|\(artist.lowercased())"
    }

    var duration: TimeInterval {
        songs.reduce(0) { $0 + $1.duration }
    }

    var songCountText: String {
        songs.count == 1 ? "1 song" : "\(songs.count) songs"
    }
}

struct ArtistSummary: Identifiable {
    let name: String
    let songs: [Song]

    var id: String {
        name.lowercased()
    }

    var albums: [AlbumSummary] {
        LibraryOrganizer.albums(from: songs)
    }

    var albumCountText: String {
        albums.count == 1 ? "1 album" : "\(albums.count) albums"
    }

    var songCountText: String {
        songs.count == 1 ? "1 song" : "\(songs.count) songs"
    }
}
