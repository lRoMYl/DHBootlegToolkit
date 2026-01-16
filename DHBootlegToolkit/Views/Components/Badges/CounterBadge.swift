import SwiftUI

// MARK: - Counter Badge Type

/// Predefined icon types for counter badges
enum CounterBadgeType {
    case gitFiles    // folder icon - for git file changes
    case keys        // translate icon - for localization keys
    case custom      // use with custom icon view
}

// MARK: - Counter Badge

/// Badge showing change counts in format: [icon] +added ~modified -deleted
/// Used for showing summary of changes in a folder or file
struct CounterBadge: View {
    let added: Int
    let modified: Int
    let deleted: Int
    let type: CounterBadgeType

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

    var body: some View {
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
            .background(
                RoundedRectangle(cornerRadius: BadgeStyle.cornerRadius, style: .continuous)
                    .stroke(Color.secondary.opacity(BadgeStyle.strokeOpacity), lineWidth: BadgeStyle.strokeWidth)
            )
        }
    }
}

// MARK: - Generic Counter Badge with Custom Icon

/// Counter badge with a custom icon view
struct CustomCounterBadge<Icon: View>: View {
    let added: Int
    let modified: Int
    let deleted: Int
    @ViewBuilder let icon: () -> Icon

    private var hasChanges: Bool {
        added > 0 || modified > 0 || deleted > 0
    }

    var body: some View {
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
            .background(
                RoundedRectangle(cornerRadius: BadgeStyle.cornerRadius, style: .continuous)
                    .stroke(Color.secondary.opacity(BadgeStyle.strokeOpacity), lineWidth: BadgeStyle.strokeWidth)
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CounterBadge(added: 3, modified: 2, deleted: 1, type: .gitFiles)
        CounterBadge(added: 5, modified: 0, deleted: 0, type: .keys)
        CounterBadge(added: 0, modified: 1, deleted: 0, type: .gitFiles)
        CustomCounterBadge(added: 2, modified: 1, deleted: 0) {
            Image(systemName: "globe")
                .font(BadgeStyle.font)
        }
    }
    .padding()
}
