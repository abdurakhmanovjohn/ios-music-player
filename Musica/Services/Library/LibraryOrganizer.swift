import Foundation

enum LibraryOrganizer {
    static func albums(from songs: [Song]) -> [AlbumSummary] {
        let groupedSongs = Dictionary(grouping: songs) { song in
            "\(song.displayAlbum.normalizedLibraryKey)|\(song.displayArtist.normalizedLibraryKey)"
        }

        return groupedSongs.values.compactMap { songs in
            guard let firstSong = songs.sorted(by: { $0.dateAdded < $1.dateAdded }).first else {
                return nil
            }

            return AlbumSummary(
                title: firstSong.displayAlbum,
                artist: firstSong.displayArtist,
                songs: songs.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending },
                artworkData: songs.first(where: { $0.artworkData != nil })?.artworkData
            )
        }
        .sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    static func artists(from songs: [Song]) -> [ArtistSummary] {
        let groupedSongs = Dictionary(grouping: songs) { song in
            song.displayArtist.normalizedLibraryKey
        }

        return groupedSongs.values.compactMap { songs in
            guard let firstSong = songs.first else {
                return nil
            }

            return ArtistSummary(
                name: firstSong.displayArtist,
                songs: songs.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            )
        }
        .sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

private extension String {
    var normalizedLibraryKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
