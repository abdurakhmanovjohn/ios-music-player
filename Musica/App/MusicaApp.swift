import SwiftData
import SwiftUI

@main
struct MusicaApp: App {
    @StateObject private var audioPlayer = AudioPlayerService()

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
            Playlist.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create Musica model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MusicaRootView()
                .environmentObject(audioPlayer)
        }
        .modelContainer(modelContainer)
    }
}
