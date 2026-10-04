import SwiftUI

struct MusicaRootView: View {
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @State private var isShowingNowPlaying = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "rectangle.stack.fill")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
        .tint(Color.musicaAccent)
        .background(Color.musicaBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if audioPlayer.currentSong != nil {
                MiniPlayerView(isNowPlayingPresented: $isShowingNowPlaying)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: audioPlayer.currentSong?.id)
        .sheet(isPresented: $isShowingNowPlaying) {
            NowPlayingView()
        }
    }
}
