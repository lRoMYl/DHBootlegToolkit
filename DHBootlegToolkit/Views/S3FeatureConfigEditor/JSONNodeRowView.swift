import SwiftUI

// MARK: - JSON Node Row View

/// Non-recursive row view for a single JSON node in the flattened tree
/// Optimized for use with LazyVStack for virtualized rendering
struct JSONNodeRowView: View {
    let node: FlattenedNode
    let onToggleExpand: () -> Void
    let onValueChange: ([String], Any) -> Void
    var onAddField: (([String]) -> Void)? = nil
    var onDeleteField: (([String]) -> Void)? = nil
    var onInsertArrayElement: (([String]) -> Void)? = nil
    var onDeleteArrayElement: (([String]) -> Void)? = nil
    var onMoveArrayElement: ((_ arrayPath: [String], _ fromIndex: Int, _ toIndex: Int) -> Void)? = nil
    var onSelect: (([String], Any) -> Void)? = nil
    var isSelected: Bool = false
    var isReadOnly: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            // Left icon (type-based) - pre-computed from node
            Image(systemName: node.iconName)
                .foregroundStyle(node.nodeType.iconColor)
                .font(.body)

            // Expand chevron (for objects/arrays)
            if node.isExpandable {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onToggleExpand()
                    }
                } label: {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
            }

            // Key label (monospaced, blue or dimmed if deleted)
            Text(node.key)
                .font(.system(.body, design: .monospaced))
                .strikethrough(node.isDeleted)
                .foregroundColor(node.isDeleted ? Color.secondary : Color.blue)
                .lineLimit(1)

            // Value editor or summary
            valueView

            Spacer()

            // Type badge
            NodeTypeBadge(nodeType: node.nodeType)

            // Change status badge (for leaf nodes with changes, or any deleted node)
            if let status = node.changeStatus, node.isLeafNode || status == .deleted {
                switch status {
                case .added:
                    StatusLetterBadge.added()
                case .modified:
                    StatusLetterBadge.modified()
                case .deleted:
                    StatusLetterBadge.deleted()
                case .unchanged:
                    EmptyView()
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .padding(.leading, node.indentation)
        .background(rowBackground)
        .cornerRadius(4)
        .opacity(node.isDeleted ? 0.7 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            // Single tap selects the node (but not for deleted nodes)
            if !node.isDeleted {
                onSelect?(node.path, node.value)
            }
        }
        .contextMenu {
            // Hide context menu entirely in read-only mode or for deleted nodes
            if !isReadOnly && !node.isDeleted {
                // Add Child Field - only for object nodes (not arrays)
                if node.canAddChildField, let onAdd = onAddField {
                    Button("Add Child Field", systemImage: "plus") {
                        onAdd(node.path)
                    }
                }

                // Add Sibling Field - only when parent is an object (not root, not array)
                if node.canAddSiblingField, let onAdd = onAddField {
                    Button("Add Sibling Field", systemImage: "plus.square") {
                        let parentPath = Array(node.path.dropLast())
                        onAdd(parentPath)
                    }
                }

                // Insert Element - only for array elements
                if node.canInsertArrayElement, let onInsert = onInsertArrayElement {
                    Button("Insert Element Here", systemImage: "plus.square.on.square") {
                        onInsert(node.path)
                    }
                }

                // Delete - show appropriate option based on parent type
                if node.canDeleteField, let onDelete = onDeleteField {
                    Divider()
                    Button("Delete Field", systemImage: "trash", role: .destructive) {
                        onDelete(node.path)
                    }
                } else if node.canDeleteArrayElement, let onDelete = onDeleteArrayElement {
                    Divider()
                    Button("Delete Element", systemImage: "trash", role: .destructive) {
                        onDelete(node.path)
                    }
                }
            }
        }
        .draggable(node.id, preview: {
            // Show a preview of the dragged row
            Text(node.key)
                .padding(8)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(4)
        })
        .dropDestination(for: String.self) { droppedItems, _ in
            guard let droppedId = droppedItems.first,
                  node.isArrayElement,
                  let onMove = onMoveArrayElement,
                  let targetIndex = node.arrayIndex,
                  let targetArrayPath = node.arrayParentPath else {
                return false
            }

            // Parse the dropped item's path to get source index and array path
            let droppedPath = droppedId.split(separator: ".").map(String.init)
            guard droppedPath.count >= 2 else { return false }

            let sourceArrayPath = Array(droppedPath.dropLast())
            guard let sourceIndexStr = droppedPath.last,
                  let sourceIndex = Int(sourceIndexStr),
                  sourceArrayPath == targetArrayPath, // Only allow reordering within same array
                  sourceIndex != targetIndex else {
                return false
            }

            onMove(targetArrayPath, sourceIndex, targetIndex)
            return true
        } isTargeted: { isTargeted in
            // Could add visual feedback here if needed
        }
        .id(node.id)
    }

    // MARK: - Row Background

    private var rowBackground: some View {
        Group {
            if isSelected {
                Color.accentColor.opacity(0.2)
            } else if node.isCurrentMatch {
                Color.yellow.opacity(0.3)
            } else {
                Color.clear
            }
        }
    }

    // MARK: - Value View

    @ViewBuilder
    private var valueView: some View {
        // Deleted nodes always show in read-only mode
        let showReadOnly = isReadOnly || node.isDeleted

        switch node.nodeType {
        case .object, .array:
            if let summary = node.nodeType.summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .string:
            if let stringValue = node.stringValue {
                if showReadOnly {
                    Text("\"\(stringValue)\"")
                        .font(.system(.body, design: .monospaced))
                        .strikethrough(node.isDeleted)
                        .foregroundColor(node.isDeleted ? Color.secondary : Color.green)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    JSONStringRowEditor(
                        value: stringValue,
                        onCommit: { newValue in
                            onValueChange(node.path, newValue)
                        }
                    )
                }
            }

        case .bool:
            if let boolValue = node.boolValue {
                if showReadOnly {
                    Toggle("", isOn: .constant(boolValue))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.7)
                        .disabled(true)
                } else {
                    JSONBoolRowEditor(
                        value: boolValue,
                        onCommit: { newValue in
                            onValueChange(node.path, newValue)
                        }
                    )
                }
            }

        case .int:
            if let numberValue = node.numberValue {
                if showReadOnly {
                    Text(numberValue.stringValue)
                        .font(.system(.body, design: .monospaced))
                        .strikethrough(node.isDeleted)
                        .foregroundColor(node.isDeleted ? Color.secondary : Color.purple)
                } else {
                    JSONNumberRowEditor(
                        value: numberValue,
                        onCommit: { newValue in
                            onValueChange(node.path, newValue)
                        }
                    )
                }
            }

        case .null:
            Text("null")
                .font(.system(.body, design: .monospaced))
                .strikethrough(node.isDeleted)
                .foregroundColor(node.isDeleted ? Color.secondary : Color.orange)

        case .unknown:
            Text(String(describing: node.value))
                .font(.system(.body, design: .monospaced))
                .strikethrough(node.isDeleted)
                .foregroundStyle(.secondary)
        }
    }

}

// MARK: - Node Type Badge

/// Badge displaying the pre-computed type of a JSON node
struct NodeTypeBadge: View {
    let nodeType: JSONNodeType

    var body: some View {
        Text(nodeType.badgeLabel)
            .font(.caption2.weight(.medium).monospaced())
            .foregroundStyle(nodeType.iconColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(nodeType.iconColor.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Row Editors

/// String editor for row view
struct JSONStringRowEditor: View {
    let value: String
    let onCommit: (String) -> Void

    @State private var editedValue: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        if isEditing {
            TextField("Value", text: $editedValue)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .focused($isFocused)
                .onSubmit {
                    if editedValue != value {
                        onCommit(editedValue)
                    }
                    isEditing = false
                }
                .onExitCommand {
                    editedValue = value
                    isEditing = false
                }
        } else {
            Text("\"\(value)\"")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.green)
                .lineLimit(1)
                .truncationMode(.tail)
                .onTapGesture(count: 2) {
                    editedValue = value
                    isEditing = true
                    isFocused = true
                }
                .help("Double-click to edit")
        }
    }
}

/// Boolean editor for row view
struct JSONBoolRowEditor: View {
    let value: Bool
    let onCommit: (Bool) -> Void

    var body: some View {
        Toggle("", isOn: Binding(
            get: { value },
            set: { onCommit($0) }
        ))
        .toggleStyle(.switch)
        .labelsHidden()
        .scaleEffect(0.7)
    }
}

/// Number editor for row view
struct JSONNumberRowEditor: View {
    let value: NSNumber
    let onCommit: (NSNumber) -> Void

    @State private var editedValue: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var isFocused: Bool

    private var isInteger: Bool {
        CFNumberIsFloatType(value) == false
    }

    var body: some View {
        if isEditing {
            TextField("Value", text: $editedValue)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .focused($isFocused)
                .onSubmit {
                    if let newNumber = parseNumber(editedValue) {
                        onCommit(newNumber)
                    }
                    isEditing = false
                }
                .onExitCommand {
                    editedValue = value.stringValue
                    isEditing = false
                }
        } else {
            Text(value.stringValue)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.purple)
                .onTapGesture(count: 2) {
                    editedValue = value.stringValue
                    isEditing = true
                    isFocused = true
                }
                .help("Double-click to edit")
        }
    }

    private func parseNumber(_ string: String) -> NSNumber? {
        if isInteger {
            if let intValue = Int(string) {
                return NSNumber(value: intValue)
            }
        } else {
            if let doubleValue = Double(string) {
                return NSNumber(value: doubleValue)
            }
        }
        return nil
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        JSONNodeRowView(
            node: FlattenedNode(
                id: "features",
                key: "features",
                value: ["darkMode": true, "beta": false],
                path: ["features"],
                depth: 0,
                nodeType: .object(keyCount: 2),
                parentType: .root,
                isExpanded: true,
                isCurrentMatch: false
            ),
            onToggleExpand: {},
            onValueChange: { _, _ in }
        )

        JSONNodeRowView(
            node: FlattenedNode(
                id: "features.darkMode",
                key: "darkMode",
                value: true,
                path: ["features", "darkMode"],
                depth: 1,
                nodeType: .bool,
                parentType: .object,
                isExpanded: false,
                isCurrentMatch: true
            ),
            onToggleExpand: {},
            onValueChange: { _, _ in }
        )

        JSONNodeRowView(
            node: FlattenedNode(
                id: "features.name",
                key: "name",
                value: "Test Feature",
                path: ["features", "name"],
                depth: 1,
                nodeType: .string,
                parentType: .object,
                isExpanded: false,
                isCurrentMatch: false
            ),
            onToggleExpand: {},
            onValueChange: { _, _ in }
        )

        JSONNodeRowView(
            node: FlattenedNode(
                id: "features.count",
                key: "count",
                value: NSNumber(value: 42),
                path: ["features", "count"],
                depth: 1,
                nodeType: .int,
                parentType: .object,
                isExpanded: false,
                isCurrentMatch: false
            ),
            onToggleExpand: {},
            onValueChange: { _, _ in }
        )
    }
    .padding()
    .frame(width: 400)
}
