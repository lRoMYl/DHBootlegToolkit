import Foundation

/// Protocol for documents that can be edited as JSON.
///
/// Types conforming to this protocol can be displayed and edited in JSON tree views.
/// The protocol provides a uniform interface for JSON editing operations regardless
/// of the specific document type.
///
/// ## Example Implementation
/// ```swift
/// struct ConfigFile: JSONEditable {
///     let url: URL
///     var content: [String: Any]
///     var originalContent: String?
///
///     func withUpdatedValue(_ value: Any, at path: [String]) -> ConfigFile? {
///         // Update content and return new instance
///     }
/// }
/// ```
public protocol JSONEditable: Sendable, Identifiable {
    /// The file URL for this document
    var url: URL { get }

    /// Current JSON content as a dictionary
    var content: [String: Any] { get }

    /// Original content string (for change detection and key order preservation)
    var originalContent: String? { get }

    /// Whether this document has unsaved changes
    var hasChanges: Bool { get }

    /// Creates an updated version of this document with a new value at the given path
    /// - Parameters:
    ///   - value: The new value to set
    ///   - path: The path components (e.g., ["features", "darkMode", "enabled"])
    /// - Returns: A new document with the updated value, or nil if the path is invalid
    func withUpdatedValue(_ value: Any, at path: [String]) -> Self?

    /// Creates an updated version with entirely new JSON content
    /// - Parameter json: The new JSON dictionary
    /// - Returns: A new document with the updated content
    func withUpdatedJSON(_ json: [String: Any]) -> Self

    /// Serializes the current content to Data for saving
    /// - Returns: UTF-8 encoded data of the JSON content, or nil if serialization fails
    func serialize() -> Data?
}

// MARK: - Default Implementations

extension JSONEditable {
    /// Default implementation of hasChanges based on comparing serialized content
    public var hasChanges: Bool {
        guard let original = originalContent else { return false }
        guard let data = serialize(),
              let currentString = String(data: data, encoding: .utf8) else {
            return false
        }
        return currentString != original
    }
}
