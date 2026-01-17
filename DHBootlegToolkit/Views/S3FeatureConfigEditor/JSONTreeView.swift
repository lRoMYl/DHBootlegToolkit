import SwiftUI

// MARK: - JSON Tree View

/// Recursive tree view for displaying and editing JSON data
/// Follows the sidebar row pattern from GenericFileRow/ImageFileRow
struct JSONTreeView: View {
    let json: [String: Any]
    let path: [String]
    var currentMatchPath: [String]? = nil
    var expandedPaths: Set<String> = []
    var expandAllByDefault: Bool = false
    @Binding var manuallyCollapsed: Set<String>
    let onValueChange: ([String], Any) -> Void
    var onAddField: (([String]) -> Void)? = nil
    var onDeleteField: (([String]) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(json.keys.sorted(), id: \.self) { key in
                JSONNodeView(
                    key: key,
                    value: json[key]!,
                    path: path + [key],
                    currentMatchPath: currentMatchPath,
                    expandedPaths: expandedPaths,
                    expandAllByDefault: expandAllByDefault,
                    manuallyCollapsed: $manuallyCollapsed,
                    onValueChange: onValueChange,
                    onAddField: onAddField,
                    onDeleteField: onDeleteField
                )
            }
        }
    }
}

// Convenience initializer for backward compatibility (without manuallyCollapsed binding)
extension JSONTreeView {
    init(
        json: [String: Any],
        path: [String],
        currentMatchPath: [String]? = nil,
        expandedPaths: Set<String> = [],
        onValueChange: @escaping ([String], Any) -> Void
    ) {
        self.json = json
        self.path = path
        self.currentMatchPath = currentMatchPath
        self.expandedPaths = expandedPaths
        self.expandAllByDefault = false
        self._manuallyCollapsed = .constant([])
        self.onValueChange = onValueChange
    }
}

// MARK: - JSON Node View

/// View for a single node in the JSON tree
/// Refactored to match GenericFileRow/ImageFileRow pattern with:
/// - Left icon based on type with color
/// - Expand chevron for objects/arrays
/// - Key label (monospaced)
/// - Value editor or summary
/// - Spacer
/// - Hover-visible actions (Phase 3)
/// - Type badge (Phase 2)
struct JSONNodeView: View {
    let key: String
    let value: Any
    let path: [String]
    var currentMatchPath: [String]? = nil
    var expandedPaths: Set<String> = []
    var expandAllByDefault: Bool = false
    @Binding var manuallyCollapsed: Set<String>
    let onValueChange: ([String], Any) -> Void
    var onAddField: (([String]) -> Void)? = nil
    var onDeleteField: (([String]) -> Void)? = nil

    @State private var isHovering: Bool = false

    private var pathString: String {
        path.joined(separator: ".")
    }

    private var isCurrentMatch: Bool {
        currentMatchPath == path
    }

    /// Determines if node should be expanded based on:
    /// 1. Search-driven expansion (highest priority)
    /// 2. User manually collapsed it (respect user choice)
    /// 3. expandAllByDefault flag
    private var shouldExpand: Bool {
        // Search expansion takes priority
        if expandedPaths.contains(pathString) {
            return true
        }
        // User manually collapsed - respect their choice
        if manuallyCollapsed.contains(pathString) {
            return false
        }
        // Default expansion
        return expandAllByDefault
    }

    private var isExpandable: Bool {
        value is [String: Any] || value is [Any]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Node row - matches sidebar pattern
            HStack(spacing: 6) {
                // Left icon (type-based) - matches GenericFileRow pattern
                typeIcon
                    .foregroundStyle(typeIconColor)
                    .font(.body)

                // Expand chevron (for objects/arrays)
                if isExpandable {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            toggleExpansion()
                        }
                    } label: {
                        Image(systemName: shouldExpand ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)
                }

                // Key label (monospaced, blue) - matches sidebar pattern
                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.blue)
                    .lineLimit(1)

                // Value editor or summary
                valueView

                Spacer()

                // Context menu (hover-visible) - matches sidebar pattern
                if onAddField != nil || onDeleteField != nil {
                    Menu {
                        if value is [String: Any], let onAdd = onAddField {
                            Button("Add Child Field", systemImage: "plus") {
                                onAdd(path)
                            }
                        }

                        if let onAdd = onAddField {
                            Button("Add Sibling Field", systemImage: "plus.square") {
                                // Add to parent path (remove last component)
                                let parentPath = Array(path.dropLast())
                                onAdd(parentPath)
                            }
                        }

                        if let onDelete = onDeleteField {
                            Divider()
                            Button("Delete Field", systemImage: "trash", role: .destructive) {
                                onDelete(path)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 20)
                    .opacity(isHovering ? 1 : 0)
                }

                // Type badge (inferred from value)
                TypeBadge.from(value: value)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(isCurrentMatch ? Color.yellow.opacity(0.3) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .id(pathString)

            // Children (if expanded)
            if shouldExpand {
                childrenView
                    .padding(.leading, 20)
            }
        }
    }

    // MARK: - Toggle Expansion

    private func toggleExpansion() {
        if shouldExpand {
            // Collapsing - add to manually collapsed set
            manuallyCollapsed.insert(pathString)
        } else {
            // Expanding - remove from manually collapsed set
            manuallyCollapsed.remove(pathString)
        }
    }

    // MARK: - Type Icon

    private var typeIcon: Image {
        if value is [String: Any] {
            return Image(systemName: "curlybraces")
        } else if value is [Any] {
            return Image(systemName: "square.stack")
        } else if value is String {
            return Image(systemName: "text.quote")
        } else if value is Bool {
            let boolValue = value as! Bool
            return Image(systemName: boolValue ? "checkmark.circle" : "xmark.circle")
        } else if value is NSNumber {
            return Image(systemName: "number")
        } else if value is NSNull {
            return Image(systemName: "minus.circle")
        } else {
            return Image(systemName: "questionmark.circle")
        }
    }

    private var typeIconColor: Color {
        if value is [String: Any] {
            return .blue
        } else if value is [Any] {
            return .indigo
        } else if value is String {
            return .green
        } else if value is Bool {
            return .orange
        } else if value is NSNumber {
            return .purple
        } else if value is NSNull {
            return .secondary
        } else {
            return .secondary
        }
    }

    // MARK: - Value View

    @ViewBuilder
    private var valueView: some View {
        if let dict = value as? [String: Any] {
            // Object summary
            Text("\(dict.count) keys")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let array = value as? [Any] {
            // Array summary
            Text("\(array.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let string = value as? String {
            JSONStringEditor(
                value: string,
                onCommit: { newValue in
                    onValueChange(path, newValue)
                }
            )
        } else if let bool = value as? Bool {
            JSONBoolEditor(
                value: bool,
                onCommit: { newValue in
                    onValueChange(path, newValue)
                }
            )
        } else if let number = value as? NSNumber {
            JSONNumberEditor(
                value: number,
                onCommit: { newValue in
                    onValueChange(path, newValue)
                }
            )
        } else if value is NSNull {
            Text("null")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.orange)
        } else {
            Text("\(String(describing: value))")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Children View

    @ViewBuilder
    private var childrenView: some View {
        if let dict = value as? [String: Any] {
            JSONTreeView(
                json: dict,
                path: path,
                currentMatchPath: currentMatchPath,
                expandedPaths: expandedPaths,
                expandAllByDefault: expandAllByDefault,
                manuallyCollapsed: $manuallyCollapsed,
                onValueChange: onValueChange,
                onAddField: onAddField,
                onDeleteField: onDeleteField
            )
        } else if let array = value as? [Any] {
            JSONArrayView(
                array: array,
                path: path,
                currentMatchPath: currentMatchPath,
                expandedPaths: expandedPaths,
                expandAllByDefault: expandAllByDefault,
                manuallyCollapsed: $manuallyCollapsed,
                onValueChange: onValueChange,
                onAddField: onAddField,
                onDeleteField: onDeleteField
            )
        }
    }
}

// MARK: - JSON Array View

/// View for displaying array items
struct JSONArrayView: View {
    let array: [Any]
    let path: [String]
    var currentMatchPath: [String]? = nil
    var expandedPaths: Set<String> = []
    var expandAllByDefault: Bool = false
    @Binding var manuallyCollapsed: Set<String>
    let onValueChange: ([String], Any) -> Void
    var onAddField: (([String]) -> Void)? = nil
    var onDeleteField: (([String]) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(array.indices, id: \.self) { index in
                JSONNodeView(
                    key: "[\(index)]",
                    value: array[index],
                    path: path + ["[\(index)]"],
                    currentMatchPath: currentMatchPath,
                    expandedPaths: expandedPaths,
                    expandAllByDefault: expandAllByDefault,
                    manuallyCollapsed: $manuallyCollapsed,
                    onValueChange: onValueChange,
                    onAddField: onAddField,
                    onDeleteField: onDeleteField
                )
            }
        }
    }
}

// MARK: - JSON Value Editors

/// Editor for string values
struct JSONStringEditor: View {
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

/// Editor for boolean values
struct JSONBoolEditor: View {
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

/// Editor for number values
struct JSONNumberEditor: View {
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
                    editedValue = value.displayValue
                    isEditing = false
                }
        } else {
            Text(value.displayValue)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.purple)
                .onTapGesture(count: 2) {
                    editedValue = value.displayValue
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
    struct PreviewWrapper: View {
        @State private var manuallyCollapsed: Set<String> = []

        var body: some View {
            ScrollView {
                JSONTreeView(
                    json: [
                        "name": "Test Feature",
                        "enabled": true,
                        "count": 42,
                        "config": [
                            "timeout": 30,
                            "retries": 3
                        ],
                        "tags": ["alpha", "beta", "gamma"]
                    ],
                    path: [],
                    currentMatchPath: ["config", "timeout"],
                    expandedPaths: ["config"],
                    expandAllByDefault: true,
                    manuallyCollapsed: $manuallyCollapsed,
                    onValueChange: { path, value in
                        print("Changed \(path.joined(separator: ".")) to \(value)")
                    }
                )
                .padding()
            }
            .frame(width: 400, height: 400)
        }
    }

    return PreviewWrapper()
}
