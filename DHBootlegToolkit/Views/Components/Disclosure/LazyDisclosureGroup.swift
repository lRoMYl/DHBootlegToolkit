import SwiftUI

// MARK: - Lazy Disclosure Group

/// A disclosure group that supports lazy loading of content when expanded.
/// The `onExpand` closure is called asynchronously when the group expands.
struct LazyDisclosureGroup<Label: View, Content: View>: View {
    @Binding var isExpanded: Bool
    let onExpand: () async -> Void
    @ViewBuilder let label: () -> Label
    @ViewBuilder let content: () -> Content

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content()
        } label: {
            label()
        }
        .task(id: isExpanded) {
            if isExpanded {
                await onExpand()
            }
        }
    }
}

// MARK: - Convenience Initializers

extension LazyDisclosureGroup {
    /// Creates a lazy disclosure group with a simple text label
    init(
        _ title: String,
        isExpanded: Binding<Bool>,
        onExpand: @escaping () async -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) where Label == Text {
        self._isExpanded = isExpanded
        self.onExpand = onExpand
        self.label = { Text(title) }
        self.content = content
    }
}

// MARK: - Lazy Disclosure Group with Hover

/// A disclosure group with hover state for showing/hiding action buttons
struct HoverableDisclosureGroup<Label: View, Content: View, Actions: View>: View {
    @Binding var isExpanded: Bool
    let onExpand: () async -> Void
    @ViewBuilder let label: (_ isHovering: Bool) -> Label
    @ViewBuilder let actions: () -> Actions
    @ViewBuilder let content: () -> Content

    @State private var isHovering = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content()
        } label: {
            HStack {
                label(isHovering)

                Spacer()

                actions()
                    .hoverVisible(isHovering)
            }
            .onHover { isHovering = $0 }
        }
        .task(id: isExpanded) {
            if isExpanded {
                await onExpand()
            }
        }
    }
}

extension HoverableDisclosureGroup where Actions == EmptyView {
    /// Creates a hoverable disclosure group without action buttons
    init(
        isExpanded: Binding<Bool>,
        onExpand: @escaping () async -> Void,
        @ViewBuilder label: @escaping (_ isHovering: Bool) -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isExpanded = isExpanded
        self.onExpand = onExpand
        self.label = label
        self.actions = { EmptyView() }
        self.content = content
    }
}

#Preview {
    List {
        LazyDisclosureGroup(
            "Simple Lazy Group",
            isExpanded: .constant(true),
            onExpand: { }
        ) {
            Text("Content loaded lazily")
        }

        HoverableDisclosureGroup(
            isExpanded: .constant(false),
            onExpand: { },
            label: { _ in
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                    Text("Hoverable folder")
                }
            },
            actions: {
                Button {} label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.plain)
            },
            content: {
                Text("Child content")
            }
        )
    }
    .listStyle(.sidebar)
    .frame(width: 280, height: 200)
}
