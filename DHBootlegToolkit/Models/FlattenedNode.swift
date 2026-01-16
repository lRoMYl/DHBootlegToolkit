import SwiftUI

// MARK: - JSON Change Status

/// Change status of a JSON node compared to git HEAD
enum JSONChangeStatus: Equatable {
    case unchanged
    case added
    case modified
    case deleted
}

// MARK: - JSON Node Type

/// Pre-computed type information for JSON nodes
/// Computed once during flattening, cached for rendering
enum JSONNodeType: Equatable {
    case object(keyCount: Int)
    case array(itemCount: Int)
    case string
    case int
    case bool
    case null
    case unknown

    // MARK: - Visual Properties

    var iconColor: Color {
        switch self {
        case .object: return .blue
        case .array: return .indigo
        case .string: return .green
        case .bool: return .orange
        case .int: return .purple
        case .null: return .secondary
        case .unknown: return .secondary
        }
    }

    var badgeLabel: String {
        switch self {
        case .object: return "{obj}"
        case .array: return "[arr]"
        case .string: return "str"
        case .int: return "int"
        case .bool: return "bool"
        case .null: return "null"
        case .unknown: return "any"
        }
    }

    var isExpandable: Bool {
        switch self {
        case .object, .array: return true
        default: return false
        }
    }

    var summary: String? {
        switch self {
        case .object(let keyCount):
            return "\(keyCount) keys"
        case .array(let itemCount):
            return "\(itemCount) items"
        default:
            return nil
        }
    }

    /// Base icon name (bool icon depends on value, handled separately)
    func icon(boolValue: Bool? = nil) -> String {
        switch self {
        case .object: return "curlybraces"
        case .array: return "square.stack"
        case .string: return "text.quote"
        case .bool:
            if let value = boolValue {
                return value ? "checkmark.circle" : "xmark.circle"
            }
            return "checkmark.circle"
        case .int: return "number"
        case .null: return "minus.circle"
        case .unknown: return "questionmark.circle"
        }
    }

    // MARK: - Type Inference

    static func infer(from value: Any) -> JSONNodeType {
        // Note: Order matters - Bool check must come before NSNumber
        // because Bool conforms to NSNumber in Objective-C bridging
        if let dict = value as? [String: Any] {
            return .object(keyCount: dict.count)
        } else if let array = value as? [Any] {
            return .array(itemCount: array.count)
        } else if value is String {
            return .string
        } else if value is NSNull {
            return .null
        } else if let number = value as? NSNumber {
            // Check if it's actually a boolean (CFBoolean)
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool
            }
            return .int
        } else {
            return .unknown
        }
    }
}

// MARK: - Parent Type

/// The type of the parent container for a JSON node
enum ParentType {
    case root   // Top-level node with no parent
    case object // Parent is a JSON object (can add sibling fields)
    case array  // Parent is a JSON array (cannot add sibling fields)
}

// MARK: - Flattened Node

/// A flattened representation of a JSON node for virtualized rendering
/// Pre-computes all display properties to minimize work during rendering
struct FlattenedNode: Identifiable {
    /// Unique identifier (path joined with ".")
    let id: String

    /// The key name for this node
    let key: String

    /// The actual value
    let value: Any

    /// Full path to this node
    let path: [String]

    /// Nesting depth (0 = root level)
    let depth: Int

    /// Pre-computed node type with visual properties
    let nodeType: JSONNodeType

    /// The type of parent container (root, object, or array)
    let parentType: ParentType

    /// Whether this node is currently expanded (for expandable nodes)
    var isExpanded: Bool

    /// Whether this is currently the search match
    var isCurrentMatch: Bool

    /// Change status compared to git HEAD (nil = unchanged)
    var changeStatus: JSONChangeStatus?

    // MARK: - Computed Properties

    /// Whether this is a leaf node (not expandable)
    var isLeafNode: Bool {
        !nodeType.isExpandable
    }

    var isExpandable: Bool {
        nodeType.isExpandable
    }

    var isDeleted: Bool {
        changeStatus == .deleted
    }

    var indentation: CGFloat {
        CGFloat(depth) * 20
    }

    /// Get the icon name, handling bool value specially
    var iconName: String {
        if case .bool = nodeType, let boolValue = value as? Bool {
            return nodeType.icon(boolValue: boolValue)
        }
        return nodeType.icon()
    }

    /// Get bool value if this is a bool node
    var boolValue: Bool? {
        value as? Bool
    }

    /// Get string value if this is a string node
    var stringValue: String? {
        value as? String
    }

    /// Get number value if this is a number node
    var numberValue: NSNumber? {
        value as? NSNumber
    }

    /// Get dict value if this is an object node
    var dictValue: [String: Any]? {
        value as? [String: Any]
    }

    /// Get array value if this is an array node
    var arrayValue: [Any]? {
        value as? [Any]
    }

    // MARK: - Context Menu Availability

    /// Whether "Add Child Field" should be shown in context menu
    /// Only available for object nodes (not arrays)
    var canAddChildField: Bool {
        if case .object = nodeType {
            return true
        }
        return false
    }

    /// Whether "Add Sibling Field" should be shown in context menu
    /// Only available when parent is an object (not root, not array)
    var canAddSiblingField: Bool {
        parentType == .object
    }

    /// Whether "Delete Field" should be shown in context menu
    /// Only available when parent is NOT an array (use deleteArrayElement for arrays)
    var canDeleteField: Bool {
        parentType != .array
    }

    // MARK: - Array Element Properties

    /// Whether this node is an element of an array
    var isArrayElement: Bool {
        parentType == .array
    }

    /// Whether "Insert Element" should be shown in context menu
    /// Only available for array elements
    var canInsertArrayElement: Bool {
        parentType == .array
    }

    /// Whether "Delete Element" should be shown in context menu
    /// Only available for array elements
    var canDeleteArrayElement: Bool {
        parentType == .array
    }

    /// Get the array index if this is an array element
    var arrayIndex: Int? {
        guard parentType == .array, let lastComponent = path.last else { return nil }
        return Int(lastComponent)
    }

    /// Get the parent array path (path without the index)
    var arrayParentPath: [String]? {
        guard parentType == .array else { return nil }
        return Array(path.dropLast())
    }
}
