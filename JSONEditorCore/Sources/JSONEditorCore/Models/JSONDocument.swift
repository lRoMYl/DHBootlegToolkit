import Foundation

/// A generic document representing a JSON file with change tracking.
///
/// JSONDocument provides:
/// - Automatic change detection by comparing against original content
/// - Order-preserving serialization
/// - Path-based value updates
/// - Edited path tracking for UI indicators
public struct JSONDocument: JSONEditable, @unchecked Sendable {
    /// Unique identifier for this document
    public let id: UUID

    /// The file URL for this document
    public let url: URL

    /// Current JSON content as a dictionary
    public var content: [String: Any]

    /// Original content string (for change detection and key order preservation)
    public var originalContent: String?

    /// Set of paths that have been edited (for UI indicators)
    public var editedPaths: Set<String>

    /// Whether this document has unsaved changes
    public var hasChanges: Bool {
        guard let original = originalContent else { return false }
        return serializeContent() != original
    }

    /// The file name without extension
    public var name: String {
        url.deletingPathExtension().lastPathComponent
    }

    /// The file name with extension
    public var fileName: String {
        url.lastPathComponent
    }

    // MARK: - Initialization

    /// Creates a new document from a URL and data
    /// - Parameters:
    ///   - url: The file URL
    ///   - data: The JSON data to parse
    /// - Throws: If the data cannot be parsed as JSON
    public init(url: URL, data: Data) throws {
        self.id = UUID()
        self.url = url
        self.editedPaths = []

        // Parse JSON
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let dictionary = jsonObject as? [String: Any] else {
            throw JSONDocumentError.invalidJSON("Failed to parse JSON from \(url.lastPathComponent)")
        }

        self.content = dictionary

        // Store original content for change tracking
        if let originalString = String(data: data, encoding: .utf8) {
            self.originalContent = originalString
        }
    }

    /// Creates a document with explicit values (for testing or programmatic creation)
    public init(
        id: UUID = UUID(),
        url: URL,
        content: [String: Any],
        originalContent: String? = nil,
        editedPaths: Set<String> = []
    ) {
        self.id = id
        self.url = url
        self.content = content
        self.originalContent = originalContent
        self.editedPaths = editedPaths
    }

    // MARK: - Value Updates

    /// Creates an updated document with a new value at the given path
    /// - Parameters:
    ///   - value: The new value to set
    ///   - path: The path components (e.g., ["features", "darkMode", "enabled"])
    /// - Returns: A new document with the updated value, or nil if the path is invalid
    public func withUpdatedValue(_ value: Any, at path: [String]) -> JSONDocument? {
        // Update the content dictionary
        guard let updatedContent = updateDictionary(content, at: path, with: value) as? [String: Any] else {
            return nil
        }

        // Track edited path
        var newEditedPaths = editedPaths
        newEditedPaths.insert(path.joined(separator: "."))

        return JSONDocument(
            id: id,
            url: url,
            content: updatedContent,
            originalContent: originalContent,
            editedPaths: newEditedPaths
        )
    }

    /// Creates an updated document with entirely new JSON content
    /// - Parameter json: The new JSON dictionary
    /// - Returns: A new document with the updated content
    public func withUpdatedJSON(_ json: [String: Any]) -> JSONDocument {
        return JSONDocument(
            id: id,
            url: url,
            content: json,
            originalContent: originalContent,
            editedPaths: [] // Reset edited paths when replacing entire JSON
        )
    }

    // MARK: - Serialization

    /// Serializes the current content to a string, preserving key order from original
    /// - Returns: JSON string with preserved key ordering
    public func serializeContent() -> String {
        if let original = originalContent {
            return JSONSerializer.serialize(content, preservingOrderFrom: original)
        } else {
            // No original content, serialize normally
            if let data = try? JSONSerialization.data(withJSONObject: content, options: [.prettyPrinted, .sortedKeys]),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return "{}"
        }
    }

    /// Serializes to Data for saving to disk
    /// - Returns: UTF-8 encoded data of the JSON content, or nil if serialization fails
    public func serialize() -> Data? {
        return serializeContent().data(using: .utf8)
    }

    // MARK: - Helper Methods

    /// Recursively updates a dictionary at a given path
    private func updateDictionary(_ dict: Any, at path: [String], with value: Any) -> Any {
        guard !path.isEmpty else { return value }

        guard var dictionary = dict as? [String: Any] else { return dict }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        if remainingPath.isEmpty {
            // Base case: set the value
            dictionary[key] = value
        } else {
            // Recursive case: update nested dictionary or array
            if let nested = dictionary[key] {
                dictionary[key] = updateDictionary(nested, at: remainingPath, with: value)
            }
        }

        return dictionary
    }
}

// MARK: - Errors

public enum JSONDocumentError: LocalizedError, Sendable {
    case invalidJSON(String)
    case serializationFailed

    public var errorDescription: String? {
        switch self {
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        case .serializationFailed:
            return "Failed to serialize JSON document"
        }
    }
}

// MARK: - Hashable & Equatable

extension JSONDocument: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: JSONDocument, rhs: JSONDocument) -> Bool {
        lhs.id == rhs.id
    }
}
