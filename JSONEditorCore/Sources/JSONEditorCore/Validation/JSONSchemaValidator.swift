import Foundation

/// Validates JSON data against JSON Schema Draft-07
public struct JSONSchemaValidator: Sendable {
    private let schema: JSONSchema

    public init(schema: JSONSchema) {
        self.schema = schema
    }

    /// Validate a JSON value against the schema
    public func validate(_ jsonData: Data) throws -> JSONSchemaValidationResult {
        let json = try JSONSerialization.jsonObject(with: jsonData)
        return validate(json, schema: schema, path: [])
    }

    /// Validate any JSON object with a specific schema
    public func validate(_ json: Any, schema: JSONSchema, path: [String]) -> JSONSchemaValidationResult {
        var errors: [ValidationError] = []

        // Check deprecated
        if schema.deprecated == true {
            errors.append(.deprecated(path: path))
        }

        // Check enum
        if let enumValues = schema.enumValues {
            if !matchesEnum(json, enumValues: enumValues) {
                let allowedStrings = enumValues.compactMap { value -> String? in
                    switch value {
                    case .string(let s): return s
                    case .number(let n): return String(n)
                    case .boolean(let b): return String(b)
                    case .null: return "null"
                    default: return nil
                    }
                }
                errors.append(.enumViolation(path: path, allowedValues: allowedStrings))
            }
        }

        // Type validation
        if let schemaType = schema.type {
            let typeErrors = validateType(json, schemaType: schemaType, path: path)
            errors.append(contentsOf: typeErrors)
        }

        // Type-specific validation
        switch json {
        case let string as String:
            errors.append(contentsOf: validateString(string, schema: schema, path: path))

        case let number as NSNumber:
            // Check if it's a boolean (NSNumber can represent booleans)
            if CFBooleanGetTypeID() == CFGetTypeID(number as CFBoolean) {
                // It's a boolean, no number validation
            } else {
                errors.append(contentsOf: validateNumber(number.doubleValue, schema: schema, path: path))
            }

        case let dict as [String: Any]:
            errors.append(contentsOf: validateObject(dict, schema: schema, path: path))

        case let array as [Any]:
            errors.append(contentsOf: validateArray(array, schema: schema, path: path))

        default:
            break
        }

        return JSONSchemaValidationResult(errors: errors)
    }

    // MARK: - Type Validation

    private func validateType(_ json: Any, schemaType: SchemaType, path: [String]) -> [ValidationError] {
        let allowedTypes = schemaType.types
        let actualType = getJSONType(json)

        // Check if type is compatible
        // In JSON Schema, integers are valid where numbers are expected
        let isCompatible = allowedTypes.contains(actualType) ||
                           (actualType == "integer" && allowedTypes.contains("number"))

        if !isCompatible {
            return [.typeMismatch(
                path: path,
                expected: allowedTypes.joined(separator: " or "),
                actual: actualType
            )]
        }

        return []
    }

    private func getJSONType(_ json: Any) -> String {
        switch json {
        case is String:
            return "string"
        case let number as NSNumber:
            // Check if it's a boolean
            if CFBooleanGetTypeID() == CFGetTypeID(number as CFBoolean) {
                return "boolean"
            }
            // Check if it's a float/double vs integer
            if CFNumberIsFloatType(number) {
                return "number"  // Floating-point numbers
            }
            return "integer"  // Whole numbers (int, int32, int64, etc.)
        case is [String: Any]:
            return "object"
        case is [Any]:
            return "array"
        case is NSNull:
            return "null"
        default:
            return "unknown"
        }
    }

    // MARK: - String Validation

    private func validateString(_ string: String, schema: JSONSchema, path: [String]) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Pattern validation
        if let pattern = schema.pattern {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(string.startIndex..., in: string)
                if regex.firstMatch(in: string, range: range) == nil {
                    errors.append(.patternMismatch(path: path, pattern: pattern))
                }
            }
        }

        // Format validation
        if let format = schema.format {
            if !validateFormat(string, format: format) {
                errors.append(.invalidFormat(path: path, format: format, value: string))
            }
        }

        // Length validation
        if let minLength = schema.minLength, string.count < minLength {
            errors.append(.minLengthViolation(path: path, minLength: minLength, actual: string.count))
        }

        if let maxLength = schema.maxLength, string.count > maxLength {
            errors.append(.maxLengthViolation(path: path, maxLength: maxLength, actual: string.count))
        }

        return errors
    }

    private func validateFormat(_ string: String, format: String) -> Bool {
        switch format {
        case "uri", "url":
            return URL(string: string) != nil
        case "email":
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: string)
        case "date-time":
            return ISO8601DateFormatter().date(from: string) != nil
        case "date":
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: string) != nil
        case "time":
            let timeRegex = "^([01]\\d|2[0-3]):([0-5]\\d):([0-5]\\d)$"
            return NSPredicate(format: "SELF MATCHES %@", timeRegex).evaluate(with: string)
        default:
            return true // Unknown format, pass validation
        }
    }

    // MARK: - Number Validation

    private func validateNumber(_ number: Double, schema: JSONSchema, path: [String]) -> [ValidationError] {
        var errors: [ValidationError] = []

        if let minimum = schema.minimum, number < minimum {
            errors.append(.minimumViolation(path: path, minimum: minimum, actual: number))
        }

        if let maximum = schema.maximum, number > maximum {
            errors.append(.maximumViolation(path: path, maximum: maximum, actual: number))
        }

        return errors
    }

    // MARK: - Object Validation

    private func validateObject(_ object: [String: Any], schema: JSONSchema, path: [String]) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Required fields validation
        if let required = schema.required {
            for requiredField in required {
                if object[requiredField] == nil {
                    errors.append(.requiredFieldMissing(path: path, fieldName: requiredField))
                }
            }
        }

        // Properties validation
        for (key, value) in object {
            if let properties = schema.properties, let propertySchema = properties[key] {
                // Validate against defined property schema
                let result = validate(value, schema: propertySchema, path: path + [key])
                errors.append(contentsOf: result.errors)
            } else {
                // Check additionalProperties
                if let additionalProps = schema.additionalProperties {
                    switch additionalProps {
                    case .boolean(let allowed):
                        if !allowed {
                            errors.append(.additionalPropertyNotAllowed(path: path, propertyName: key))
                        }
                    case .schema(let additionalSchema):
                        // Validate against additional properties schema
                        let result = validate(value, schema: additionalSchema.value, path: path + [key])
                        errors.append(contentsOf: result.errors)
                    }
                }
            }
        }

        return errors
    }

    // MARK: - Array Validation

    private func validateArray(_ array: [Any], schema: JSONSchema, path: [String]) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Length validation
        if let minLength = schema.minLength, array.count < minLength {
            errors.append(.minLengthViolation(path: path, minLength: minLength, actual: array.count))
        }

        if let maxLength = schema.maxLength, array.count > maxLength {
            errors.append(.maxLengthViolation(path: path, maxLength: maxLength, actual: array.count))
        }

        // Items validation
        if let items = schema.items {
            for (index, item) in array.enumerated() {
                let itemPath = path + ["[\(index)]"]
                let result = validate(item, schema: items.value, path: itemPath)
                errors.append(contentsOf: result.errors)
            }
        }

        return errors
    }

    // MARK: - Enum Validation

    private func matchesEnum(_ json: Any, enumValues: [JSONValue]) -> Bool {
        for enumValue in enumValues {
            if compareJSONValue(json, with: enumValue) {
                return true
            }
        }
        return false
    }

    private func compareJSONValue(_ json: Any, with enumValue: JSONValue) -> Bool {
        switch enumValue {
        case .string(let expectedString):
            return (json as? String) == expectedString
        case .number(let expectedNumber):
            if let actualNumber = json as? NSNumber {
                // Avoid boolean comparison
                if CFBooleanGetTypeID() == CFGetTypeID(actualNumber as CFBoolean) {
                    return false
                }
                return actualNumber.doubleValue == expectedNumber
            }
            return false
        case .boolean(let expectedBool):
            if let actualNumber = json as? NSNumber,
               CFBooleanGetTypeID() == CFGetTypeID(actualNumber as CFBoolean) {
                return actualNumber.boolValue == expectedBool
            }
            return false
        case .null:
            return json is NSNull
        case .array(let expectedArray):
            guard let actualArray = json as? [Any] else { return false }
            guard expectedArray.count == actualArray.count else { return false }
            return zip(expectedArray, actualArray).allSatisfy { compareJSONValue($1, with: $0) }
        case .object(let expectedObject):
            guard let actualObject = json as? [String: Any] else { return false }
            guard expectedObject.count == actualObject.count else { return false }
            return expectedObject.allSatisfy { key, value in
                guard let actualValue = actualObject[key] else { return false }
                return compareJSONValue(actualValue, with: value)
            }
        }
    }
}

// MARK: - Convenience Methods

extension JSONSchemaValidator {
    /// Validate a dictionary representation
    public func validate(dictionary: [String: Any]) -> JSONSchemaValidationResult {
        validate(dictionary, schema: schema, path: [])
    }

    /// Quick validation check
    public func isValid(_ jsonData: Data) -> Bool {
        do {
            let result = try validate(jsonData)
            return result.isValid
        } catch {
            return false
        }
    }
}
