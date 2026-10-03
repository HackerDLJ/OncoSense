import SwiftUI

// Keep the visual treatment compatible with the current watchOS SDK used by CI.
// The native watchOS 26 glassEffect API is intentionally not referenced here
// because Xcode 16.4 ships a watchOS 11.x SDK and cannot compile that symbol.
// The material treatment keeps the same translucent visual language and can be
// swapped to native Liquid Glass when the project moves to an Xcode 26 SDK.
struct WatchGlass<Content: View>: View {
    @ViewBuilder let content: Content
    var cornerRadius: CGFloat = 16

    var body: some View {
        content
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

struct WatchGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
