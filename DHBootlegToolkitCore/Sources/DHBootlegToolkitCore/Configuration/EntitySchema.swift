import Foundation

/// Defines the structure of JSON entities in the repository.
///
/// `EntitySchema` specifies which fields are required, which are optional,
/// and the order in which fields should be written to JSON files.
public struct EntitySchema: Sendable, Codable, Equatable {
    /// Fields that must be present for an entity to be valid
    public let requiredFields: [FieldDefinition]

    /// Fields that are optional
    public let optionalFields: [FieldDefinition]

    /// Order of inner keys when writing JSON (for consistent output)
    public let innerKeyOrder: [String]

    public init(
        requiredFields: [FieldDefinition],
        optionalFields: [FieldDefinition] = [],
        innerKeyOrder: [String]
    ) {
        self.requiredFields = requiredFields
        self.optionalFields = optionalFields
        self.innerKeyOrder = innerKeyOrder
    }

    /// Returns all field definitions (required + optional)
    public var allFields: [FieldDefinition] {
        requiredFields + optionalFields
    }

    /// Checks if a field name is defined in the schema
    public func hasField(named name: String) -> Bool {
        allFields.contains { $0.name == name }
    }
}

// MARK: - Standard Schemas

extension EntitySchema {
    /// Standard translation schema for localization files.
    ///
    /// Required fields:
    /// - `translation`: The translated text
    /// - `notes`: Notes for translators
    ///
    /// Optional fields:
    /// - `char_limit`: Maximum character count
    /// - `target_languages`: List of target language codes
    public static let translation = EntitySchema(
        requiredFields: [
            FieldDefinition(name: "translation", type: .string),
            FieldDefinition(name: "notes", type: .string)
        ],
        optionalFields: [
            FieldDefinition(name: "char_limit", type: .int),
            FieldDefinition(name: "target_languages", type: .stringArray)
        ],
        innerKeyOrder: ["translation", "notes", "char_limit", "target_languages"]
    )
}

// MARK: - Field Definition

/// Defines a single field in an entity schema.
public struct FieldDefinition: Sendable, Codable, Equatable {
    /// Field name as it appears in JSON
    public let name: String

    /// Expected data type
    public let type: FieldType

    /// Default value if field is missing (for optional fields)
    public let defaultValue: FieldValue?

    public init(name: String, type: FieldType, defaultValue: FieldValue? = nil) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }
}

// MARK: - Field Type

/// Supported field data types in entity schemas.
public enum FieldType: String, Sendable, Codable, Equatable {
    case string
    case int
    case bool
    case stringArray
    case dictionary
}

// MARK: - Field Value

/// Represents a typed value for default field values.
public enum FieldValue: Sendable, Codable, Equatable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case stringArray([String])
    case null

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "string":
            self = .string(try container.decode(String.self, forKey: .value))
        case "int":
            self = .int(try container.decode(Int.self, forKey: .value))
        case "bool":
            self = .bool(try container.decode(Bool.self, forKey: .value))
        case "stringArray":
            self = .stringArray(try container.decode([String].self, forKey: .value))
        case "null":
            self = .null
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown field value type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .string(let value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .value)
        case .int(let value):
            try container.encode("int", forKey: .type)
            try container.encode(value, forKey: .value)
        case .bool(let value):
            try container.encode("bool", forKey: .type)
            try container.encode(value, forKey: .value)
        case .stringArray(let value):
            try container.encode("stringArray", forKey: .type)
            try container.encode(value, forKey: .value)
        case .null:
            try container.encode("null", forKey: .type)
        }
    }
}
