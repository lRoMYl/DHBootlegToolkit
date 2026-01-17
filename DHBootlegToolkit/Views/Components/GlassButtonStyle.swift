import SwiftUI

/// A button style that creates a liquid glass effect with material background
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    /// A liquid glass button style with material background
    static var glass: GlassButtonStyle {
        GlassButtonStyle()
    }
}
