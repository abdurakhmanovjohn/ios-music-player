import Combine
import Foundation

final class LibraryViewModel: ObservableObject {
    func albums(from songs: [Song]) -> [AlbumSummary] {
        LibraryOrganizer.albums(from: songs)
    }

    func artists(from songs: [Song]) -> [ArtistSummary] {
        LibraryOrganizer.artists(from: songs)
    }
}
