import SwiftUI

// MARK: - JSON Schema Type

/// Represents the type of a JSON field as defined in schema
enum JSONSchemaType: String, CaseIterable {
    case string
    case int
    case float
    case bool
    case null
    case stringArray
    case intArray
    case object
    case array
    case any  // Unknown or untyped

    /// Short label for display in badge
    var label: String {
        switch self {
        case .string: return "str"
        case .int: return "int"
        case .float: return "float"
        case .bool: return "bool"
        case .null: return "null"
        case .stringArray: return "[str]"
        case .intArray: return "[int]"
        case .object: return "{obj}"
        case .array: return "[arr]"
        case .any: return "any"
        }
    }

    /// Color for the type badge
    var color: Color {
        switch self {
        case .string: return .green
        case .int: return .purple
        case .float: return .purple
        case .bool: return .orange
        case .null: return .gray
        case .stringArray: return .green
        case .intArray: return .purple
        case .object: return .blue
        case .array: return .indigo
        case .any: return .secondary
        }
    }

    /// Default tooltip text for the type
    var defaultTooltip: String {
        switch self {
        case .string: return BadgeStyle.TypeTooltip.string
        case .int: return BadgeStyle.TypeTooltip.int
        case .float: return BadgeStyle.TypeTooltip.float
        case .bool: return BadgeStyle.TypeTooltip.bool
        case .null: return BadgeStyle.TypeTooltip.null
        case .stringArray: return BadgeStyle.TypeTooltip.stringArray
        case .intArray: return BadgeStyle.TypeTooltip.intArray
        case .object: return BadgeStyle.TypeTooltip.object
        case .array: return BadgeStyle.TypeTooltip.array
        case .any: return BadgeStyle.TypeTooltip.any
        }
    }

    /// Infers the schema type from a runtime value
    static func infer(from value: Any) -> JSONSchemaType {
        if value is [String: Any] {
            return .object
        } else if let array = value as? [Any] {
            // Try to infer array element type
            if let first = array.first {
                if first is String {
                    return .stringArray
                } else if first is NSNumber, !(first is Bool) {
                    return .intArray
                }
            }
            return .array
        } else if value is String {
            return .string
        } else if value is NSNull {
            return .null
        } else if let number = value as? NSNumber {
            // Check if it's a boolean (CFBoolean)
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool
            }
            // Check if it's a float
            if CFNumberIsFloatType(number) {
                return .float
            }
            return .int
        } else {
            return .any
        }
    }
}

// MARK: - Type Badge

/// Badge displaying the type of a JSON field
/// Uses UnifiedBadge for consistent styling and tooltip support
struct TypeBadge: View {
    let type: JSONSchemaType

    /// Whether this type was inferred (not from schema)
    var isInferred: Bool = true

    /// Custom tooltip text (falls back to default type tooltip if nil)
    var tooltip: String?

    init(type: JSONSchemaType, isInferred: Bool = true, tooltip: String? = nil) {
        self.type = type
        self.isInferred = isInferred
        self.tooltip = tooltip
    }

    var body: some View {
        UnifiedBadge(config: BadgeConfiguration(
            contentType: .label(type.label),
            color: type.color,
            tooltip: tooltip ?? type.defaultTooltip,
            strokeOpacity: isInferred ? 0.3 : 0.5
        ))
    }
}

// MARK: - Convenience Extensions

extension TypeBadge {
    /// Creates a type badge from a runtime value
    static func from(value: Any) -> TypeBadge {
        TypeBadge(type: .infer(from: value), isInferred: true)
    }

    /// Creates a type badge for string type
    static func string() -> TypeBadge {
        TypeBadge(type: .string, isInferred: false)
    }

    /// Creates a type badge for integer type
    static func int() -> TypeBadge {
        TypeBadge(type: .int, isInferred: false)
    }

    /// Creates a type badge for boolean type
    static func bool() -> TypeBadge {
        TypeBadge(type: .bool, isInferred: false)
    }

    /// Creates a type badge for object type
    static func object() -> TypeBadge {
        TypeBadge(type: .object, isInferred: false)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        Text("Schema-defined types:")
            .font(.headline)

        HStack(spacing: 8) {
            TypeBadge.string()
            TypeBadge.int()
            TypeBadge.bool()
            TypeBadge.object()
        }

        Divider()

        Text("Inferred types:")
            .font(.headline)

        HStack(spacing: 8) {
            TypeBadge.from(value: "hello")
            TypeBadge.from(value: 42)
            TypeBadge.from(value: true)
            TypeBadge.from(value: ["a", "b"])
        }

        HStack(spacing: 8) {
            TypeBadge.from(value: [1, 2, 3])
            TypeBadge.from(value: ["key": "value"])
            TypeBadge(type: .any)
        }
    }
    .padding()
}
