import Foundation

/// Result of validating a JSON document or value.
public enum ValidationResult: Sendable {
    /// Validation succeeded
    case success

    /// Validation failed with one or more errors
    case failure([SimpleValidationError])

    /// Whether the validation passed
    public var isValid: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    /// Array of validation errors (empty if validation succeeded)
    public var errors: [SimpleValidationError] {
        switch self {
        case .success:
            return []
        case .failure(let errors):
            return errors
        }
    }

    /// Returns a user-friendly description of all errors
    public var errorDescription: String? {
        switch self {
        case .success:
            return nil
        case .failure(let errors):
            return errors.map { $0.description }.joined(separator: "\n")
        }
    }
}

// MARK: - Validation Error

/// Represents a validation error in a JSON document.
public struct SimpleValidationError: Sendable, LocalizedError {
    /// The path to the invalid value (e.g., ["features", "darkMode", "enabled"])
    public let path: [String]

    /// The validation rule that failed
    public let rule: String

    /// Human-readable description of the error
    public let message: String

    public init(path: [String], rule: String, message: String) {
        self.path = path
        self.rule = rule
        self.message = message
    }

    public var description: String {
        let pathString = path.isEmpty ? "root" : path.joined(separator: ".")
        return "\(pathString): \(message) (rule: \(rule))"
    }

    public var errorDescription: String? {
        description
    }
}

// MARK: - Common Validation Errors

extension SimpleValidationError {
    /// Creates an error for a missing required field
    public static func requiredField(path: [String], fieldName: String) -> SimpleValidationError {
        SimpleValidationError(
            path: path,
            rule: "required",
            message: "Missing required field '\(fieldName)'"
        )
    }

    /// Creates an error for an invalid type
    public static func invalidType(path: [String], expected: String, actual: String) -> SimpleValidationError {
        SimpleValidationError(
            path: path,
            rule: "type",
            message: "Expected \(expected), got \(actual)"
        )
    }

    /// Creates an error for an invalid value
    public static func invalidValue(path: [String], message: String) -> SimpleValidationError {
        SimpleValidationError(
            path: path,
            rule: "value",
            message: message
        )
    }

    /// Creates an error for a schema mismatch
    public static func schemaMismatch(path: [String], message: String) -> SimpleValidationError {
        SimpleValidationError(
            path: path,
            rule: "schema",
            message: message
        )
    }
}
