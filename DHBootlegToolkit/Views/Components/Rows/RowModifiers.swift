import SwiftUI

// MARK: - Row View Modifiers

extension View {
    /// Standard hover-triggered visibility for action buttons
    /// Usage: .hoverVisible(isHovering)
    func hoverVisible(_ isHovering: Bool) -> some View {
        self.opacity(isHovering ? 1 : 0)
    }

    /// Standard row selection background (accent color with opacity)
    /// Usage: .rowSelectionBackground(isSelected)
    func rowSelectionBackground(_ isSelected: Bool) -> some View {
        self.listRowBackground(
            isSelected
                ? Color.accentColor.opacity(0.15)
                : Color.clear
        )
    }

    /// Inline selection background for row content (not list row)
    /// Usage: .inlineSelectionBackground(isSelected)
    func inlineSelectionBackground(_ isSelected: Bool) -> some View {
        self.background(
            isSelected
                ? Color.accentColor.opacity(0.15)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 4)
        )
    }

    /// Conditionally applies a modifier to a view
    /// Usage: .if(condition) { view in view.modifier() }
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
