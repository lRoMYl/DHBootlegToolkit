import Foundation

/// Result of JSON Schema validation
public struct JSONSchemaValidationResult: Sendable {
    /// List of validation errors/warnings
    public let errors: [ValidationError]

    /// Whether validation passed (no errors, warnings allowed)
    public var isValid: Bool {
        !errors.contains { $0.severity == .error }
    }

    /// Count of errors (not warnings)
    public var errorCount: Int {
        errors.filter { $0.severity == .error }.count
    }

    /// Count of warnings
    public var warningCount: Int {
        errors.filter { $0.severity == .warning }.count
    }

    /// Errors grouped by path
    public var errorsByPath: [String: [ValidationError]] {
        Dictionary(grouping: errors) { $0.pathString }
    }

    public init(errors: [ValidationError]) {
        self.errors = errors
    }

    /// Create a successful validation result with no errors
    public static var success: JSONSchemaValidationResult {
        JSONSchemaValidationResult(errors: [])
    }

    /// Create a validation result with a single error
    public static func failure(path: [String], message: String, severity: ValidationError.Severity = .error) -> JSONSchemaValidationResult {
        JSONSchemaValidationResult(errors: [ValidationError(path: path, message: message, severity: severity)])
    }
}

/// A single validation error or warning
public struct ValidationError: Identifiable, Sendable {
    public let id: UUID
    public let path: [String]
    public let message: String
    public let severity: Severity
    public let code: ErrorCode

    public var pathString: String {
        path.isEmpty ? "(root)" : path.joined(separator: ".")
    }

    public init(
        id: UUID = UUID(),
        path: [String],
        message: String,
        severity: Severity,
        code: ErrorCode = .other
    ) {
        self.id = id
        self.path = path
        self.message = message
        self.severity = severity
        self.code = code
    }

    public enum Severity: String, Sendable {
        case error
        case warning
    }

    public enum ErrorCode: String, Sendable {
        case typeMismatch
        case requiredFieldMissing
        case invalidFormat
        case patternMismatch
        case enumViolation
        case minimumViolation
        case maximumViolation
        case minLengthViolation
        case maxLengthViolation
        case additionalPropertyNotAllowed
        case deprecated
        case other
    }
}

// MARK: - Convenience Initializers

extension ValidationError {
    public static func typeMismatch(path: [String], expected: String, actual: String) -> ValidationError {
        ValidationError(
            path: path,
            message: "Type mismatch: expected \(expected), got \(actual)",
            severity: .error,
            code: .typeMismatch
        )
    }

    public static func requiredFieldMissing(path: [String], fieldName: String) -> ValidationError {
        ValidationError(
            path: path,
            message: "Missing required field: \(fieldName)",
            severity: .error,
            code: .requiredFieldMissing
        )
    }

    public static func invalidFormat(path: [String], format: String, value: String) -> ValidationError {
        ValidationError(
            path: path,
            message: "Invalid \(format) format: \(value)",
            severity: .warning,
            code: .invalidFormat
        )
    }

    public static func patternMismatch(path: [String], pattern: String) -> ValidationError {
        ValidationError(
            path: path,
            message: "Value does not match pattern: \(pattern)",
            severity: .error,
            code: .patternMismatch
        )
    }

    public static func enumViolation(path: [String], allowedValues: [String]) -> ValidationError {
        ValidationError(
            path: path,
            message: "Value must be one of: \(allowedValues.joined(separator: ", "))",
            severity: .error,
            code: .enumViolation
        )
    }

    public static func minimumViolation(path: [String], minimum: Double, actual: Double) -> ValidationError {
        ValidationError(
            path: path,
            message: "Value \(actual) is less than minimum \(minimum)",
            severity: .error,
            code: .minimumViolation
        )
    }

    public static func maximumViolation(path: [String], maximum: Double, actual: Double) -> ValidationError {
        ValidationError(
            path: path,
            message: "Value \(actual) exceeds maximum \(maximum)",
            severity: .error,
            code: .maximumViolation
        )
    }

    public static func minLengthViolation(path: [String], minLength: Int, actual: Int) -> ValidationError {
        ValidationError(
            path: path,
            message: "Length \(actual) is less than minimum \(minLength)",
            severity: .error,
            code: .minLengthViolation
        )
    }

    public static func maxLengthViolation(path: [String], maxLength: Int, actual: Int) -> ValidationError {
        ValidationError(
            path: path,
            message: "Length \(actual) exceeds maximum \(maxLength)",
            severity: .error,
            code: .maxLengthViolation
        )
    }

    public static func additionalPropertyNotAllowed(path: [String], propertyName: String) -> ValidationError {
        ValidationError(
            path: path,
            message: "Additional property not allowed: \(propertyName)",
            severity: .warning,
            code: .additionalPropertyNotAllowed
        )
    }

    public static func deprecated(path: [String]) -> ValidationError {
        ValidationError(
            path: path,
            message: "This field is deprecated",
            severity: .warning,
            code: .deprecated
        )
    }
}
