import SwiftUI

// MARK: - Counter Badge Type

/// Predefined icon types for counter badges
public enum CounterBadgeType {
    case gitFiles    // folder icon - for git file changes
    case keys        // translate icon - for localization keys
    case custom      // use with custom icon view
}

// MARK: - Counter Badge

/// Badge showing change counts in format: [icon] +added ~modified -deleted
/// Used for showing summary of changes in a folder or file
public struct CounterBadge: View {
    let added: Int
    let modified: Int
    let deleted: Int
    let type: CounterBadgeType
    var tooltip: String? = nil

    public init(added: Int, modified: Int, deleted: Int, type: CounterBadgeType, tooltip: String? = nil) {
        self.added = added
        self.modified = modified
        self.deleted = deleted
        self.type = type
        self.tooltip = tooltip
    }

    private var hasChanges: Bool {
        added > 0 || modified > 0 || deleted > 0
    }

    @ViewBuilder
    private var iconView: some View {
        switch type {
        case .gitFiles:
            Image(systemName: "folder.fill")
                .font(BadgeStyle.font)
        case .keys:
            Image("translate-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 10, height: 10)
        case .custom:
            EmptyView()
        }
    }

    public var body: some View {
        if hasChanges {
            HStack(spacing: BadgeStyle.iconSpacing) {
                iconView
                    .foregroundStyle(.secondary)

                HStack(spacing: BadgeStyle.counterSpacing) {
                    if added > 0 {
                        Text("+\(added)")
                            .foregroundStyle(.green)
                    }
                    if modified > 0 {
                        Text("~\(modified)")
                            .foregroundStyle(.blue)
                    }
                    if deleted > 0 {
                        Text("-\(deleted)")
                            .foregroundStyle(.red)
                    }
                }
            }
            .font(BadgeStyle.font)
            .padding(.horizontal, BadgeStyle.counterPaddingH)
            .padding(.vertical, BadgeStyle.counterPaddingV)
            .frame(minHeight: BadgeStyle.letterSize)
            .background(
                RoundedRectangle(cornerRadius: BadgeStyle.cornerRadius, style: .continuous)
                    .stroke(Color.secondary.opacity(BadgeStyle.strokeOpacity), lineWidth: BadgeStyle.strokeWidth)
            )
            .applyTooltip(tooltip)
        }
    }
}

// MARK: - Generic Counter Badge with Custom Icon

/// Counter badge with a custom icon view
public struct CustomCounterBadge<Icon: View>: View {
    let added: Int
    let modified: Int
    let deleted: Int
    var tooltip: String? = nil
    @ViewBuilder let icon: () -> Icon

    public init(added: Int, modified: Int, deleted: Int, tooltip: String? = nil, @ViewBuilder icon: @escaping () -> Icon) {
        self.added = added
        self.modified = modified
        self.deleted = deleted
        self.tooltip = tooltip
        self.icon = icon
    }

    private var hasChanges: Bool {
        added > 0 || modified > 0 || deleted > 0
    }

    public var body: some View {
        if hasChanges {
            HStack(spacing: BadgeStyle.iconSpacing) {
                icon()
                    .foregroundStyle(.secondary)

                HStack(spacing: BadgeStyle.counterSpacing) {
                    if added > 0 {
                        Text("+\(added)")
                            .foregroundStyle(.green)
                    }
                    if modified > 0 {
                        Text("~\(modified)")
                            .foregroundStyle(.blue)
                    }
                    if deleted > 0 {
                        Text("-\(deleted)")
                            .foregroundStyle(.red)
                    }
                }
            }
            .font(BadgeStyle.font)
            .padding(.horizontal, BadgeStyle.counterPaddingH)
            .padding(.vertical, BadgeStyle.counterPaddingV)
            .frame(minHeight: BadgeStyle.letterSize)
            .background(
                RoundedRectangle(cornerRadius: BadgeStyle.cornerRadius, style: .continuous)
                    .stroke(Color.secondary.opacity(BadgeStyle.strokeOpacity), lineWidth: BadgeStyle.strokeWidth)
            )
            .applyTooltip(tooltip)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CounterBadge(added: 3, modified: 2, deleted: 1, type: .gitFiles, tooltip: "3 added, 2 modified, 1 deleted")
        CounterBadge(added: 5, modified: 0, deleted: 0, type: .keys, tooltip: "5 new translation keys")
        CounterBadge(added: 0, modified: 1, deleted: 0, type: .gitFiles, tooltip: "1 file modified")
        CustomCounterBadge(added: 2, modified: 1, deleted: 0, tooltip: "2 added, 1 modified") {
            Image(systemName: "globe")
                .font(BadgeStyle.font)
        }
    }
    .padding()
}
