import SwiftUI

extension Color {
    static let oncoBackground = Color(uiColor: .systemBackground)
    static let oncoCard = Color(uiColor: .secondarySystemBackground)
    static let oncoSecondaryCard = Color(uiColor: .tertiarySystemBackground)
    static let oncoText = Color.primary
    static let oncoSecondaryText = Color.secondary
    static let oncoAccent = Color(red: 0.15, green: 0.62, blue: 0.48)
    static let oncoWarning = Color.orange
    static let oncoSignal = Color(red: 0.92, green: 0.43, blue: 0.18)
}

struct OncoCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.oncoCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            }
    }
}

struct SignalPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(Color.oncoSecondaryCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
