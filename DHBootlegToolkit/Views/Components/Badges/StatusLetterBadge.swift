import SwiftUI

// MARK: - Status Letter Badge

/// Generic single-letter status badge (A/M/D or custom)
/// Used for displaying file status (Added/Modified/Deleted) or any single-character indicator
struct StatusLetterBadge: View {
    let letter: String
    let color: Color
    let tooltip: String?

    init(letter: String, color: Color, tooltip: String? = nil) {
        self.letter = letter
        self.color = color
        self.tooltip = tooltip
    }

    var body: some View {
        UnifiedBadge(config: BadgeConfiguration(
            contentType: .letter(letter),
            color: color,
            tooltip: tooltip
        ))
    }
}

// MARK: - Convenience Extensions

extension StatusLetterBadge {
    /// Creates a badge for "Added" status (green A)
    static func added() -> StatusLetterBadge {
        StatusLetterBadge(letter: "A", color: .green, tooltip: BadgeStyle.StatusTooltip.added)
    }

    /// Creates a badge for "Modified" status (blue M)
    static func modified() -> StatusLetterBadge {
        StatusLetterBadge(letter: "M", color: .blue, tooltip: BadgeStyle.StatusTooltip.modified)
    }

    /// Creates a badge for "Deleted" status (red D)
    static func deleted() -> StatusLetterBadge {
        StatusLetterBadge(letter: "D", color: .red, tooltip: BadgeStyle.StatusTooltip.deleted)
    }

    /// Creates a badge for "Required" field indicator (red *)
    static func required() -> StatusLetterBadge {
        StatusLetterBadge(letter: "*", color: .red, tooltip: "Required field")
    }

    /// Creates a badge for "Info" indicator (blue i)
    static func info(tooltip: String) -> StatusLetterBadge {
        StatusLetterBadge(letter: "i", color: .blue, tooltip: tooltip)
    }

    /// Creates a badge for "Error" indicator (red !)
    static func error(tooltip: String) -> StatusLetterBadge {
        StatusLetterBadge(letter: "!", color: .red, tooltip: tooltip)
    }

    /// Creates a badge for "Warning" indicator (orange !)
    static func warning(tooltip: String) -> StatusLetterBadge {
        StatusLetterBadge(letter: "!", color: .orange, tooltip: tooltip)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        Text("Status Badges:")
            .font(.headline)

        HStack(spacing: 8) {
            StatusLetterBadge.added()
            StatusLetterBadge.modified()
            StatusLetterBadge.deleted()
        }

        Divider()

        Text("Indicator Badges:")
            .font(.headline)

        HStack(spacing: 8) {
            StatusLetterBadge.required()
            StatusLetterBadge.info(tooltip: "This is additional information about the field")
            StatusLetterBadge.error(tooltip: "This field has a validation error")
            StatusLetterBadge.warning(tooltip: "This field has a validation warning")
        }

        Divider()

        Text("Custom Badge:")
            .font(.headline)

        HStack(spacing: 8) {
            StatusLetterBadge(letter: "S", color: .orange, tooltip: "Custom status")
        }
    }
    .padding()
}
