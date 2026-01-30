import SwiftUI

// MARK: - Control Bar

/// Generic horizontal control bar container with consistent styling
/// Provides standard HStack layout with padding and background
public struct ControlBar<Content: View>: View {
  @ViewBuilder let content: () -> Content

  public init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  public var body: some View {
    HStack(spacing: 8) {
      content()
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 8)
    .background(Color(nsColor: .controlBackgroundColor))
  }
}
