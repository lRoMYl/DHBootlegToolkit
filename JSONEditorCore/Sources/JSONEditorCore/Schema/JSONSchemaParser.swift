import Foundation

/// Parser for JSON Schema files
public struct JSONSchemaParser: Sendable {
    public init() {}

    /// Parse a JSON Schema from data
    public func parse(data: Data) throws -> JSONSchema {
        let decoder = JSONDecoder()
        return try decoder.decode(JSONSchema.self, from: data)
    }

    /// Parse a JSON Schema from a file URL
    public func parse(fileURL: URL) throws -> JSONSchema {
        let data = try Data(contentsOf: fileURL)
        return try parse(data: data)
    }

    /// Parse a JSON Schema from a file path
    public func parse(filePath: String) throws -> JSONSchema {
        let url = URL(fileURLWithPath: filePath)
        return try parse(fileURL: url)
    }

    /// Extract all property paths from a schema
    /// Returns a dictionary mapping JSON paths to their schema descriptions
    public func extractPropertyInfo(from schema: JSONSchema, basePath: [String] = []) -> [String: PropertyInfo] {
        var result: [String: PropertyInfo] = [:]

        guard let properties = schema.properties else {
            return result
        }

        for (propertyName, propertySchema) in properties {
            let path = basePath + [propertyName]
            let pathString = path.joined(separator: ".")

            let info = PropertyInfo(
                path: path,
                type: propertySchema.type,
                description: propertySchema.description,
                format: propertySchema.format,
                pattern: propertySchema.pattern,
                enumValues: propertySchema.enumValues,
                isRequired: schema.required?.contains(propertyName) ?? false,
                isDeprecated: propertySchema.deprecated ?? false,
                minimum: propertySchema.minimum,
                maximum: propertySchema.maximum,
                minLength: propertySchema.minLength,
                maxLength: propertySchema.maxLength,
                defaultValue: propertySchema.defaultValue
            )

            result[pathString] = info

            // Recursively extract nested properties
            if let nestedProperties = propertySchema.properties {
                let nestedInfo = extractPropertyInfo(from: propertySchema, basePath: path)
                result.merge(nestedInfo) { _, new in new }
            }
        }

        return result
    }

    /// Extract required fields from a schema at a specific path
    public func requiredFields(in schema: JSONSchema, at path: [String] = []) -> Set<String> {
        guard let targetSchema = schema.schema(at: path) else {
            return []
        }
        return Set(targetSchema.required ?? [])
    }

    /// Check if additional properties are allowed at a specific path
    public func allowsAdditionalProperties(in schema: JSONSchema, at path: [String] = []) -> Bool {
        guard let targetSchema = schema.schema(at: path) else {
            return true // Default to allowing if schema not found
        }

        guard let additionalProps = targetSchema.additionalProperties else {
            return true // Default JSON Schema behavior
        }

        switch additionalProps {
        case .boolean(let allowed):
            return allowed
        case .schema:
            return true // If schema provided, additional properties are allowed
        }
    }
}

/// Information extracted from a schema property
public struct PropertyInfo: Sendable {
    public let path: [String]
    public let type: SchemaType?
    public let description: String?
    public let format: String?
    public let pattern: String?
    public let enumValues: [JSONValue]?
    public let isRequired: Bool
    public let isDeprecated: Bool
    public let minimum: Double?
    public let maximum: Double?
    public let minLength: Int?
    public let maxLength: Int?
    public let defaultValue: JSONValue?

    public var pathString: String {
        path.joined(separator: ".")
    }

    public var typeString: String? {
        guard let type = type else { return nil }
        return type.types.joined(separator: " | ")
    }
}

// MARK: - Error Handling

public enum SchemaParseError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidJSON
    case invalidSchema(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Schema file not found at: \(path)"
        case .invalidJSON:
            return "Invalid JSON in schema file"
        case .invalidSchema(let reason):
            return "Invalid schema: \(reason)"
        }
    }
}
