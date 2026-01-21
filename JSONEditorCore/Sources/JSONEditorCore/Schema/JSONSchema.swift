import Foundation

/// Represents a JSON Schema Draft-07 structure
public struct JSONSchema: Codable, Sendable {
    /// Schema version identifier
    public let schema: String?

    /// The type(s) this schema validates
    public let type: SchemaType?

    /// Properties for object types
    public let properties: [String: JSONSchema]?

    /// Required property names
    public let required: [String]?

    /// Whether additional properties are allowed
    public let additionalProperties: AdditionalProperties?

    /// Human-readable description
    public let description: String?

    /// Format specification (e.g., "uri", "email", "date-time")
    public let format: String?

    /// Pattern for string validation (regex)
    public let pattern: String?

    /// Enum values for validation
    public let enumValues: [JSONValue]?

    /// Schema for array items
    public let items: Box<JSONSchema>?

    /// Whether this field is deprecated
    public let deprecated: Bool?

    /// Minimum value for numbers
    public let minimum: Double?

    /// Maximum value for numbers
    public let maximum: Double?

    /// Minimum length for strings/arrays
    public let minLength: Int?

    /// Maximum length for strings/arrays
    public let maxLength: Int?

    /// Default value
    public let defaultValue: JSONValue?

    /// Title of the schema
    public let title: String?

    public init(
        schema: String? = nil,
        type: SchemaType? = nil,
        properties: [String: JSONSchema]? = nil,
        required: [String]? = nil,
        additionalProperties: AdditionalProperties? = nil,
        description: String? = nil,
        format: String? = nil,
        pattern: String? = nil,
        enumValues: [JSONValue]? = nil,
        items: Box<JSONSchema>? = nil,
        deprecated: Bool? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        defaultValue: JSONValue? = nil,
        title: String? = nil
    ) {
        self.schema = schema
        self.type = type
        self.properties = properties
        self.required = required
        self.additionalProperties = additionalProperties
        self.description = description
        self.format = format
        self.pattern = pattern
        self.enumValues = enumValues
        self.items = items
        self.deprecated = deprecated
        self.minimum = minimum
        self.maximum = maximum
        self.minLength = minLength
        self.maxLength = maxLength
        self.defaultValue = defaultValue
        self.title = title
    }

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case type
        case properties
        case required
        case additionalProperties
        case description
        case format
        case pattern
        case enumValues = "enum"
        case items
        case deprecated
        case minimum
        case maximum
        case minLength
        case maxLength
        case defaultValue = "default"
        case title
    }
}

/// Schema type specification
public enum SchemaType: Codable, Equatable, Sendable {
    case single(String)
    case multiple([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let single = try? container.decode(String.self) {
            self = .single(single)
        } else if let multiple = try? container.decode([String].self) {
            self = .multiple(multiple)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected string or array of strings for type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let type):
            try container.encode(type)
        case .multiple(let types):
            try container.encode(types)
        }
    }

    public var types: [String] {
        switch self {
        case .single(let type):
            return [type]
        case .multiple(let types):
            return types
        }
    }
}

/// Additional properties specification
public enum AdditionalProperties: Codable, Sendable {
    case boolean(Bool)
    case schema(Box<JSONSchema>)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            self = .boolean(bool)
        } else if let schema = try? container.decode(JSONSchema.self) {
            self = .schema(Box(schema))
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected boolean or schema for additionalProperties"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .boolean(let bool):
            try container.encode(bool)
        case .schema(let schema):
            try container.encode(schema.value)
        }
    }
}

/// Generic JSON value for enum and default values
public enum JSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .boolean(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid JSON value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .boolean(let bool):
            try container.encode(bool)
        case .number(let number):
            try container.encode(number)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

/// Box wrapper for recursive schema structures - uses class for indirection
public final class Box<T>: Codable, Sendable where T: Codable & Sendable {
    public let value: T

    public init(_ value: T) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(T.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Helper Extensions

extension JSONSchema {
    /// Returns the schema for a specific property path
    public func schema(at path: [String]) -> JSONSchema? {
        guard !path.isEmpty else { return self }

        var current = self
        for component in path {
            if let properties = current.properties,
               let nextSchema = properties[component] {
                current = nextSchema
            } else if let items = current.items {
                // For arrays, use the items schema
                current = items.value
            } else {
                return nil
            }
        }
        return current
    }

    /// Checks if a field is required at the given path
    public func isRequired(_ fieldName: String, at path: [String] = []) -> Bool {
        guard let schema = schema(at: path) else { return false }
        return schema.required?.contains(fieldName) ?? false
    }

    /// Returns all property names defined in this schema
    public var propertyNames: [String] {
        properties?.keys.sorted() ?? []
    }
}
