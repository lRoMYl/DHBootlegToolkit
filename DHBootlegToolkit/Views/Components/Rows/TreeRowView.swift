import SwiftUI

// MARK: - Tree Row Style

/// Label styling for tree row text
enum TreeRowLabelStyle {
    case normal          // Primary color
    case secondary       // Secondary color (for dimmed items)
    case strikethrough   // Strikethrough with secondary color (for deleted items)
}

// MARK: - Tree Row View

/// Reusable tree row component with icon, label, actions, and badge
/// Provides consistent styling and behavior for sidebar tree items
struct TreeRowView<ActionContent: View, BadgeContent: View>: View {
    // Required properties
    let icon: Image
    let iconColor: Color
    let label: String
    let onTap: () -> Void

    // Styling options
    var labelStyle: TreeRowLabelStyle = .normal
    var isSelected: Bool = false
    var isDeleted: Bool = false

    // Optional content builders
    @ViewBuilder var actions: () -> ActionContent
    @ViewBuilder var badge: () -> BadgeContent

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                icon
                    .foregroundStyle(effectiveIconColor)
                    .font(.body)

                Text(label)
                    .font(.body)
                    .foregroundStyle(effectiveLabelColor)
                    .strikethrough(shouldStrikethrough)
                    .lineLimit(1)

                Spacer()

                actions()
                    .hoverVisible(isHovering)

                badge()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .rowSelectionBackground(isSelected)
    }

    // MARK: - Computed Styles

    private var effectiveIconColor: Color {
        isDeleted ? .secondary : iconColor
    }

    private var effectiveLabelColor: Color {
        switch labelStyle {
        case .normal:
            return isDeleted ? .secondary : .primary
        case .secondary:
            return .secondary
        case .strikethrough:
            return .secondary
        }
    }

    private var shouldStrikethrough: Bool {
        isDeleted || labelStyle == .strikethrough
    }
}

// MARK: - Convenience Initializers

extension TreeRowView where ActionContent == EmptyView {
    /// Creates a tree row without action buttons
    init(
        icon: Image,
        iconColor: Color,
        label: String,
        labelStyle: TreeRowLabelStyle = .normal,
        isSelected: Bool = false,
        isDeleted: Bool = false,
        @ViewBuilder badge: @escaping () -> BadgeContent,
        onTap: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.labelStyle = labelStyle
        self.isSelected = isSelected
        self.isDeleted = isDeleted
        self.actions = { EmptyView() }
        self.badge = badge
        self.onTap = onTap
    }
}

extension TreeRowView where BadgeContent == EmptyView {
    /// Creates a tree row without a badge
    init(
        icon: Image,
        iconColor: Color,
        label: String,
        labelStyle: TreeRowLabelStyle = .normal,
        isSelected: Bool = false,
        isDeleted: Bool = false,
        @ViewBuilder actions: @escaping () -> ActionContent,
        onTap: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.labelStyle = labelStyle
        self.isSelected = isSelected
        self.isDeleted = isDeleted
        self.actions = actions
        self.badge = { EmptyView() }
        self.onTap = onTap
    }
}

extension TreeRowView where ActionContent == EmptyView, BadgeContent == EmptyView {
    /// Creates a simple tree row without actions or badge
    init(
        icon: Image,
        iconColor: Color,
        label: String,
        labelStyle: TreeRowLabelStyle = .normal,
        isSelected: Bool = false,
        isDeleted: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.labelStyle = labelStyle
        self.isSelected = isSelected
        self.isDeleted = isDeleted
        self.actions = { EmptyView() }
        self.badge = { EmptyView() }
        self.onTap = onTap
    }
}

#Preview {
    List {
        TreeRowView(
            icon: Image(systemName: "folder.fill"),
            iconColor: .blue,
            label: "Normal folder",
            onTap: {}
        )

        TreeRowView(
            icon: Image(systemName: "doc.text"),
            iconColor: .secondary,
            label: "Selected file",
            isSelected: true,
            onTap: {}
        )

        TreeRowView(
            icon: Image(systemName: "photo"),
            iconColor: .purple,
            label: "Deleted image",
            isDeleted: true,
            badge: {
                Text("D")
                    .font(.caption2)
                    .foregroundStyle(.red)
            },
            onTap: {}
        )

        TreeRowView(
            icon: Image(systemName: "doc.text"),
            iconColor: .secondary,
            label: "With action",
            actions: {
                Button {} label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.plain)
            },
            onTap: {}
        )
    }
    .listStyle(.sidebar)
    .frame(width: 280, height: 300)
}
