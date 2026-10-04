import Combine
import Foundation

final class SearchViewModel: ObservableObject {
    @Published var query = ""

    func matchingSongs(in songs: [Song]) -> [Song] {
        let normalizedQuery = query.normalizedSearchQuery
        guard !normalizedQuery.isEmpty else {
            return []
        }

        return songs.filter { song in
            song.title.normalizedSearchQuery.contains(normalizedQuery)
                || song.displayArtist.normalizedSearchQuery.contains(normalizedQuery)
                || song.displayAlbum.normalizedSearchQuery.contains(normalizedQuery)
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func matchingAlbums(in songs: [Song]) -> [AlbumSummary] {
        let normalizedQuery = query.normalizedSearchQuery
        guard !normalizedQuery.isEmpty else {
            return []
        }

        return LibraryOrganizer.albums(from: songs).filter { album in
            album.title.normalizedSearchQuery.contains(normalizedQuery)
                || album.artist.normalizedSearchQuery.contains(normalizedQuery)
        }
    }

    func matchingArtists(in songs: [Song]) -> [ArtistSummary] {
        let normalizedQuery = query.normalizedSearchQuery
        guard !normalizedQuery.isEmpty else {
            return []
        }

        return LibraryOrganizer.artists(from: songs).filter { artist in
            artist.name.normalizedSearchQuery.contains(normalizedQuery)
        }
    }
}

private extension String {
    var normalizedSearchQuery: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
