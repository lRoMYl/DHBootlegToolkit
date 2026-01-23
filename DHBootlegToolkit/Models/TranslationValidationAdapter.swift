import Foundation
import JSONEditorCore
import DHBootlegToolkitCore

/// Adapter converting Localization domain validation to JSONEditorCore format
struct TranslationValidationAdapter {
    /// Convert validation errors to JSONSchemaValidationResult for UI display
    static func createValidationResult(
        editedKey: TranslationKey,
        keyValidationError: String?,
        charLimitError: String?,
        targetLanguagesError: String?
    ) -> JSONSchemaValidationResult {
        var errors: [ValidationError] = []

        // Key validation
        if editedKey.key.isEmpty {
            errors.append(ValidationError(
                path: ["key"],
                message: "Key name is required",
                severity: .error,
                code: .requiredFieldMissing
            ))
        } else if let keyError = keyValidationError {
            errors.append(ValidationError(
                path: ["key"],
                message: keyError,
                severity: .error,
                code: .patternMismatch
            ))
        }

        // Translation validation
        if editedKey.translation.isEmpty {
            errors.append(ValidationError(
                path: ["translation"],
                message: "Translation is required",
                severity: .error,
                code: .requiredFieldMissing
            ))
        }

        // Notes validation
        if editedKey.notes.isEmpty {
            errors.append(ValidationError(
                path: ["notes"],
                message: "Notes for translators is required",
                severity: .error,
                code: .requiredFieldMissing
            ))
        }

        // Character limit validation
        if let charError = charLimitError {
            errors.append(ValidationError(
                path: ["charLimit"],
                message: charError,
                severity: .error,
                code: .maximumViolation
            ))
        }

        // Target languages validation
        if let langError = targetLanguagesError {
            errors.append(ValidationError(
                path: ["targetLanguages"],
                message: langError,
                severity: .warning,
                code: .invalidFormat
            ))
        }

        return JSONSchemaValidationResult(errors: errors)
    }
}
