import SwiftUI

extension Color {
    static let watchBackground = Color.black
    static let watchCard = Color(white: 0.12)
    static let watchAccent = Color(red: 0.18, green: 0.78, blue: 0.58)
}

struct WatchCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.watchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
