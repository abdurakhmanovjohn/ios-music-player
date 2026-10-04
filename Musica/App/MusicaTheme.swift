import SwiftUI

extension Color {
    static let musicaBackground = Color(red: 0.035, green: 0.037, blue: 0.045)
    static let musicaElevated = Color(red: 0.095, green: 0.098, blue: 0.115)
    static let musicaCard = Color(red: 0.13, green: 0.135, blue: 0.155)
    static let musicaAccent = Color(red: 0.98, green: 0.18, blue: 0.36)
    static let musicaSecondaryAccent = Color(red: 0.19, green: 0.78, blue: 0.72)
    static let musicaGold = Color(red: 1.0, green: 0.7, blue: 0.28)
}

extension LinearGradient {
    static var musicaArtworkPlaceholder: LinearGradient {
        LinearGradient(
            colors: [
                .musicaAccent,
                .musicaSecondaryAccent,
                .musicaGold
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var musicaScreenBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.075, green: 0.06, blue: 0.075),
                .musicaBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension TimeInterval {
    var musicaClockString: String {
        guard isFinite, self > 0 else {
            return "0:00"
        }

        let totalSeconds = Int(self.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }
}
