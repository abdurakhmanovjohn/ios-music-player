import SwiftUI

struct SongRowView: View {
    let song: Song
    var showsAlbum = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ArtworkView(artworkData: song.artworkData, title: song.title, cornerRadius: 9)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if song.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.musicaAccent)
                }

                Text(song.duration.musicaClockString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
    }

    private var subtitle: String {
        showsAlbum ? "\(song.displayArtist) - \(song.displayAlbum)" : song.displayArtist
    }
}
