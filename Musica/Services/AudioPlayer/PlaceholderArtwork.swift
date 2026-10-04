import UIKit

enum PlaceholderArtwork {
    static func image(for title: String, size: CGFloat = 600) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        return renderer.image { context in
            let colors = [
                UIColor(red: 0.89, green: 0.33, blue: 0.40, alpha: 1),
                UIColor(red: 0.38, green: 0.78, blue: 0.73, alpha: 1),
                UIColor(red: 0.93, green: 0.70, blue: 0.37, alpha: 1)
            ].map(\.cgColor) as CFArray

            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 0.5, 1]
            ) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size, y: size),
                    options: []
                )
            }

            let symbolConfig = UIImage.SymbolConfiguration(pointSize: size * 0.3, weight: .bold)
            if let note = UIImage(systemName: "music.note", withConfiguration: symbolConfig)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                note.draw(in: CGRect(
                    x: (size - note.size.width) / 2,
                    y: size * 0.22,
                    width: note.size.width,
                    height: note.size.height
                ))
            }

            let letter = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased() as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size * 0.18, weight: .black),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let textSize = letter.size(withAttributes: attributes)
            letter.draw(
                at: CGPoint(x: (size - textSize.width) / 2, y: size * 0.62),
                withAttributes: attributes
            )
        }
    }
}
