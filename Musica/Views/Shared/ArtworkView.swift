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
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "music.note")
                                .font(.system(size: 34, weight: .bold))
                            Text(title.prefix(1).uppercased())
                                .font(.system(size: 26, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 10)
        .accessibilityHidden(true)
    }
}
