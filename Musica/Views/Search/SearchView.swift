import SwiftData
import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @Query(sort: \Song.title) private var songs: [Song]
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section {
                        EmptyStateView(
                            systemImage: "magnifyingglass",
                            title: "Search your library",
                            message: "Find songs by title, artist, or album."
                        )
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                    }
                    .listRowBackground(Color.clear)
                } else {
                    let matchingSongs = viewModel.matchingSongs(in: songs)
                    let matchingAlbums = viewModel.matchingAlbums(in: songs)
                    let matchingArtists = viewModel.matchingArtists(in: songs)

                    if matchingSongs.isEmpty && matchingAlbums.isEmpty && matchingArtists.isEmpty {
                        Section {
                            EmptyStateView(
                                systemImage: "questionmark.folder.fill",
                                title: "No matches",
                                message: "Try a song title, artist, or album from your local library."
                            )
                            .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section("Songs") {
                        ForEach(matchingSongs) { song in
                            SongRowView(song: song, showsAlbum: true) {
                                audioPlayer.load(song, queue: matchingSongs)
                            }
                        }
                    }

                    Section("Albums") {
                        ForEach(matchingAlbums) { album in
                            NavigationLink {
                                SongCollectionView(
                                    title: album.title,
                                    subtitle: "\(album.artist) - \(album.songCountText)",
                                    songs: album.songs
                                )
                            } label: {
                                HStack(spacing: 12) {
                                    ArtworkView(artworkData: album.artworkData, title: album.title, cornerRadius: 9)
                                        .frame(width: 50, height: 50)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(album.title)
                                            .font(.body.weight(.semibold))

                                        Text(album.artist)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    Section("Artists") {
                        ForEach(matchingArtists) { artist in
                            NavigationLink {
                                SongCollectionView(
                                    title: artist.name,
                                    subtitle: "\(artist.albumCountText) - \(artist.songCountText)",
                                    songs: artist.songs
                                )
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.musicaElevated)
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .foregroundStyle(Color.musicaSecondaryAccent)
                                        }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(artist.name)
                                            .font(.body.weight(.semibold))

                                        Text(artist.songCountText)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.musicaBackground)
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Songs, artists, albums")
        }
    }
}
