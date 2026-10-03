import SwiftUI

struct OncoGlass<Content: View>: View {
    @ViewBuilder let content: Content
    var cornerRadius: CGFloat = 24

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                content
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            } else {
                content
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(.primary.opacity(0.08), lineWidth: 1)
                    }
            }
        }
    }
}

struct OncoGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                configuration.label
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .scaleEffect(configuration.isPressed ? 0.97 : 1)
            } else {
                configuration.label
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .scaleEffect(configuration.isPressed ? 0.97 : 1)
            }
        }
    }
}
