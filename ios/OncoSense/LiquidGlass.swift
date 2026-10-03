import SwiftUI

// The current CI image uses Xcode 16.4 / iOS 18 SDK, so native iOS 26
// glassEffect symbols cannot be compiled yet. Keep one abstraction so the
// visual treatment can be upgraded to native Liquid Glass when the project
// moves to an Xcode 26 SDK without changing the app screens.
struct OncoGlass<Content: View>: View {
    @ViewBuilder let content: Content
    var cornerRadius: CGFloat = 24

    var body: some View {
        content
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

struct OncoGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
