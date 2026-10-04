import SwiftUI

struct SongRowView: View {
    let song: Song
    var showsAlbum = false
    var isCurrent = false
    var action: () -> Void

    @State private var isEditing = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ArtworkView(artworkData: song.artworkData, title: song.title, cornerRadius: 9)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if isCurrent {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.musicaAccent)
                }

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
        .contextMenu {
            Button {
                isEditing = true
            } label: {
                Label("Edit Info", systemImage: "pencil")
            }
        }
        .sheet(isPresented: $isEditing) {
            EditSongView(song: song)
        }
    }

    private var subtitle: String {
        guard showsAlbum, song.displayAlbum != "Unknown Album" else {
            return song.displayArtist
        }
        return "\(song.displayArtist) · \(song.displayAlbum)"
    }
}
