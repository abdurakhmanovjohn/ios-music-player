import SwiftUI
import UIKit

struct ArtworkView: View {
    let artworkData: Data?
    let title: String
    var cornerRadius: CGFloat = 18

    var body: some View {
        ZStack {
            if let artworkData,
               let image = UIImage(data: artworkData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient.musicaArtworkPlaceholder
                    .overlay { PlaceholderContent(title: title) }
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 10)
        .accessibilityHidden(true)
    }
}

/// Icon and letter scale with the tile, so they never overflow small sizes.
private struct PlaceholderContent: View {
    let title: String

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let isSmall = side < 64

            VStack(spacing: side * 0.06) {
                Image(systemName: "music.note")
                    .font(.system(size: isSmall ? side * 0.45 : side * 0.30, weight: .bold))

                if !isSmall {
                    Text(title.prefix(1).uppercased())
                        .font(.system(size: side * 0.22, weight: .black, design: .rounded))
                }
            }
            .foregroundStyle(.white.opacity(0.9))
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
