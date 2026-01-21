import Foundation

/// JSONEditorCore provides order-preserving JSON editing with minimal diffs.
///
/// This package includes:
/// - `JSONSerializer`: Order-preserving JSON serialization
/// - `JSONDocument`: Generic document model
/// - `JSONEditOperation`: Edit operation types
/// - `ValidationResult`: Validation results
/// - `JSONEditable`: Protocol for editable documents
public enum JSONEditorCore {
    /// The version of this package
    public static let version = "1.0.0"
}
