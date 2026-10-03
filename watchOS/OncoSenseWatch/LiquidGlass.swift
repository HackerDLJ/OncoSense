import SwiftUI

struct WatchGlass<Content: View>: View {
    @ViewBuilder let content: Content
    var cornerRadius: CGFloat = 16

    var body: some View {
        Group {
            if #available(watchOS 26.0, *) {
                content
                    .padding(10)
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            } else {
                content
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
            }
        }
    }
}

struct WatchGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if #available(watchOS 26.0, *) {
                configuration.label
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .scaleEffect(configuration.isPressed ? 0.96 : 1)
            } else {
                configuration.label
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
                    .scaleEffect(configuration.isPressed ? 0.96 : 1)
            }
        }
    }
}
