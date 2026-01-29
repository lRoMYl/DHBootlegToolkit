import SwiftUI

// MARK: - JSON Schema Type

/// Represents the type of a JSON field
public enum JSONSchemaType: String, CaseIterable, Sendable {
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
    public var label: String {
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
    public var color: Color {
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

    /// Infers the schema type from a runtime value
    public static func infer(from value: Any) -> JSONSchemaType {
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
public struct TypeBadge: View {
    let type: JSONSchemaType

    /// Whether this type was inferred (not from schema)
    var isInferred: Bool = true

    public init(type: JSONSchemaType, isInferred: Bool = true) {
        self.type = type
        self.isInferred = isInferred
    }

    public var body: some View {
        Text(type.label)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(type.color.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(type.color, lineWidth: isInferred ? 0.5 : 1)
            )
    }
}

// MARK: - Convenience Extensions

extension TypeBadge {
    /// Creates a type badge from a runtime value
    public static func from(value: Any) -> TypeBadge {
        TypeBadge(type: .infer(from: value), isInferred: true)
    }

    /// Creates a type badge for string type
    public static func string() -> TypeBadge {
        TypeBadge(type: .string, isInferred: false)
    }

    /// Creates a type badge for integer type
    public static func int() -> TypeBadge {
        TypeBadge(type: .int, isInferred: false)
    }

    /// Creates a type badge for boolean type
    public static func bool() -> TypeBadge {
        TypeBadge(type: .bool, isInferred: false)
    }

    /// Creates a type badge for object type
    public static func object() -> TypeBadge {
        TypeBadge(type: .object, isInferred: false)
    }

    /// Creates a type badge for array type
    public static func array() -> TypeBadge {
        TypeBadge(type: .array, isInferred: false)
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
