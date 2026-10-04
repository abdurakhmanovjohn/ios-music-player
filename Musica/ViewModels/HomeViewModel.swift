import Combine
import Foundation

final class HomeViewModel: ObservableObject {
    func recentlyPlayed(from songs: [Song]) -> [Song] {
        let playedSongs = songs
            .filter { $0.lastPlayedDate != nil }
            .sorted {
                ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast)
            }

        return Array(playedSongs.prefix(12))
    }

    func recentlyAdded(from songs: [Song]) -> [Song] {
        Array(
            songs
                .sorted { $0.dateAdded > $1.dateAdded }
                .prefix(12)
        )
    }

    func favorites(from songs: [Song]) -> [Song] {
        Array(
            songs
                .filter(\.isFavorite)
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
                .prefix(12)
        )
    }
}
