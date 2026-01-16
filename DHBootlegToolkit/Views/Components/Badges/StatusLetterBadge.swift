import SwiftUI

// MARK: - Status Letter Badge

/// Generic single-letter status badge (A/M/D or custom)
/// Used for displaying file status (Added/Modified/Deleted) or any single-character indicator
struct StatusLetterBadge: View {
    let letter: String
    let color: Color

    var body: some View {
        Text(letter)
            .font(BadgeStyle.font)
            .foregroundStyle(color)
            .frame(width: BadgeStyle.letterSize, height: BadgeStyle.letterSize)
            .background(
                RoundedRectangle(cornerRadius: BadgeStyle.cornerRadius, style: .continuous)
                    .stroke(color.opacity(BadgeStyle.strokeOpacity), lineWidth: BadgeStyle.strokeWidth)
            )
    }
}

// MARK: - Convenience Extensions

extension StatusLetterBadge {
    /// Creates a badge for "Added" status (green A)
    static func added() -> StatusLetterBadge {
        StatusLetterBadge(letter: "A", color: .green)
    }

    /// Creates a badge for "Modified" status (blue M)
    static func modified() -> StatusLetterBadge {
        StatusLetterBadge(letter: "M", color: .blue)
    }

    /// Creates a badge for "Deleted" status (red D)
    static func deleted() -> StatusLetterBadge {
        StatusLetterBadge(letter: "D", color: .red)
    }
}

#Preview {
    HStack(spacing: 8) {
        StatusLetterBadge.added()
        StatusLetterBadge.modified()
        StatusLetterBadge.deleted()
        StatusLetterBadge(letter: "S", color: .orange)
    }
    .padding()
}
