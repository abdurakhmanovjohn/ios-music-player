import SwiftUI

struct MusicaRootView: View {
    @State private var isShowingNowPlaying = false

    var body: some View {
        TabView {
            HomeView()
                .miniPlayerInset(isNowPlayingPresented: $isShowingNowPlaying)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            LibraryView()
                .miniPlayerInset(isNowPlayingPresented: $isShowingNowPlaying)
                .tabItem {
                    Label("Library", systemImage: "rectangle.stack.fill")
                }

            SearchView()
                .miniPlayerInset(isNowPlayingPresented: $isShowingNowPlaying)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
        .tint(Color.musicaAccent)
        .background(Color.musicaBackground)
        .sheet(isPresented: $isShowingNowPlaying) {
            NowPlayingView()
        }
    }
}
