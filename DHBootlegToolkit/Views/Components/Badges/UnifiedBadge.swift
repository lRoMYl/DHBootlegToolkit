import SwiftUI

// MARK: - Badge Content Type

/// Defines the type of content displayed in a badge
enum BadgeContentType {
    /// Fixed square badge with a single letter (e.g., A, M, D)
    case letter(String)
    /// Variable width badge with a label (e.g., str, int, {obj})
    case label(String)
}

// MARK: - Badge Configuration

/// Configuration for a unified badge
struct BadgeConfiguration {
    let contentType: BadgeContentType
    let color: Color
    let tooltip: String?
    let strokeOpacity: Double

    init(
        contentType: BadgeContentType,
        color: Color,
        tooltip: String? = nil,
        strokeOpacity: Double = BadgeStyle.strokeOpacity
    ) {
        self.contentType = contentType
        self.color = color
        self.tooltip = tooltip
        self.strokeOpacity = strokeOpacity
    }
}

// MARK: - Unified Badge

/// Core unified badge component that serves as the single source of truth for all badge styling
/// Provides consistent 18pt minimum height and tooltip support for all badge types
struct UnifiedBadge: View {
    let config: BadgeConfiguration

    var body: some View {
        badgeContent
            .applyTooltip(config.tooltip)
    }

    @ViewBuilder
    private var badgeContent: some View {
        switch config.contentType {
        case .letter(let letter):
            // Fixed square badge (18×18)
            Text(letter)
                .font(BadgeStyle.font)
                .foregroundStyle(config.color)
                .frame(width: BadgeStyle.letterSize, height: BadgeStyle.letterSize)
                .background(
                    RoundedRectangle(cornerRadius: BadgeStyle.cornerRadius, style: .continuous)
                        .stroke(config.color.opacity(config.strokeOpacity), lineWidth: BadgeStyle.strokeWidth)
                )

        case .label(let label):
            // Variable width badge with 18pt minimum height
            Text(label)
                .font(BadgeStyle.font.monospaced())
                .foregroundStyle(config.color)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .frame(minHeight: BadgeStyle.letterSize)
                .background(
                    RoundedRectangle(cornerRadius: BadgeStyle.cornerRadius, style: .continuous)
                        .stroke(config.color.opacity(config.strokeOpacity), lineWidth: BadgeStyle.strokeWidth)
                )
        }
    }
}

// MARK: - Tooltip Helper

extension View {
    @ViewBuilder
    func applyTooltip(_ tooltip: String?) -> some View {
        if let tooltip = tooltip {
            self.fastTooltip(tooltip)
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        Text("Letter Badges (18×18 fixed):")
            .font(.headline)

        HStack(spacing: 8) {
            UnifiedBadge(config: BadgeConfiguration(
                contentType: .letter("A"),
                color: .green,
                tooltip: "Added in current changes"
            ))

            UnifiedBadge(config: BadgeConfiguration(
                contentType: .letter("M"),
                color: .blue,
                tooltip: "Modified in current changes"
            ))

            UnifiedBadge(config: BadgeConfiguration(
                contentType: .letter("D"),
                color: .red,
                tooltip: "Deleted in current changes"
            ))
        }

        Divider()

        Text("Label Badges (variable width, 18pt min height):")
            .font(.headline)

        HStack(spacing: 8) {
            UnifiedBadge(config: BadgeConfiguration(
                contentType: .label("str"),
                color: .green,
                tooltip: "String type"
            ))

            UnifiedBadge(config: BadgeConfiguration(
                contentType: .label("int"),
                color: .purple,
                tooltip: "Integer type"
            ))

            UnifiedBadge(config: BadgeConfiguration(
                contentType: .label("{obj}"),
                color: .blue,
                tooltip: "Object type"
            ))

            UnifiedBadge(config: BadgeConfiguration(
                contentType: .label("[str]"),
                color: .green,
                tooltip: "String array type",
                strokeOpacity: 0.3
            ))
        }

        Divider()

        Text("Height Alignment Test (all 18pt):")
            .font(.headline)

        HStack(alignment: .center, spacing: 8) {
            UnifiedBadge(config: BadgeConfiguration(
                contentType: .letter("A"),
                color: .green
            ))

            UnifiedBadge(config: BadgeConfiguration(
                contentType: .label("str"),
                color: .green
            ))

            UnifiedBadge(config: BadgeConfiguration(
                contentType: .label("{obj}"),
                color: .blue
            ))

            UnifiedBadge(config: BadgeConfiguration(
                contentType: .label("[str]"),
                color: .green,
                strokeOpacity: 0.3
            ))
        }
    }
    .padding()
}
