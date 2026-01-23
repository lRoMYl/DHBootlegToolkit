import Foundation
import GitCore
import JSONEditorCore

/// Base protocol for coordinating Git + JSON editing operations.
///
/// This protocol combines GitPublishable for git operations with document management
/// capabilities, providing a complete editor coordinator pattern.
///
/// ## Example Implementation
/// ```swift
/// @Observable
/// @MainActor
/// final class MyEditorStore: EditorCoordinator {
///     typealias Document = MyDocument
///
///     var gitWorker: GitWorker?
///     var gitStatus: GitStatus = .unconfigured
///     var documents: [MyDocument] = []
///     var selectedDocument: MyDocument?
///     var searchText: String = ""
///     var isLoading: Bool = false
///
///     func generateCommitMessage() -> String {
///         "Update \(documents.filter { $0.hasChanges }.count) files"
///     }
///
///     func generatePRTitle() -> String {
///         "Configuration updates"
///     }
///
///     func generatePRBody() -> String {
///         let modifiedFiles = documents.filter { $0.hasChanges }.map { $0.fileName }
///         return "Modified files:\\n" + modifiedFiles.joined(separator: "\\n")
///     }
/// }
/// ```
@MainActor
public protocol EditorCoordinator: GitPublishable, Observable {
    /// The document type this editor works with (must be JSONEditable)
    associatedtype Document: JSONEditable

    // MARK: - Document Management (Required)

    /// All loaded documents
    var documents: [Document] { get set }

    /// Currently selected document
    var selectedDocument: Document? { get set }

    // MARK: - UI State (Required)

    /// Search text for filtering
    var searchText: String { get set }

    /// Loading state
    var isLoading: Bool { get set }

    // MARK: - Operations (Default Implementations Provided)

    /// Loads documents from a directory
    /// - Parameter url: The directory URL to load from
    func loadDocuments(from url: URL) async throws

    /// Saves a document to disk
    /// - Parameter document: The document to save
    func saveDocument(_ document: Document) async throws

    /// Updates a value in a document at the given path
    /// - Parameters:
    ///   - document: The document to update
    ///   - path: The path to the value
    ///   - value: The new value
    /// - Returns: Updated document, or nil if update failed
    func updateValue(in document: Document, at path: [String], value: Any) -> Document?
}

// MARK: - Default Implementations

extension EditorCoordinator {
    /// Default implementation: delegates to document's withUpdatedValue
    public func updateValue(in document: Document, at path: [String], value: Any) -> Document? {
        return document.withUpdatedValue(value, at: path)
    }

    /// Default implementation: serializes and writes to disk
    public func saveDocument(_ document: Document) async throws {
        guard let data = document.serialize() else {
            throw EditorError.serializationFailed
        }
        try data.write(to: document.url, options: .atomic)
    }

    /// Saves all modified documents
    public func saveAllModifiedDocuments() async throws {
        for document in documents where document.hasChanges {
            try await saveDocument(document)
        }
    }

    /// Replaces a document in the documents array
    /// - Parameter updatedDocument: The updated document
    public func replaceDocument(_ updatedDocument: Document) {
        if let index = documents.firstIndex(where: { $0.id == updatedDocument.id }) {
            documents[index] = updatedDocument
            if selectedDocument?.id == updatedDocument.id {
                selectedDocument = updatedDocument
            }
        }
    }

    /// Updates the selected document with a new value
    /// - Parameters:
    ///   - path: Path to the value
    ///   - value: New value
    public func updateSelectedDocument(at path: [String], value: Any) {
        guard let selected = selectedDocument,
              let updated = updateValue(in: selected, at: path, value: value) else {
            return
        }
        replaceDocument(updated)
    }
}

// MARK: - Editor Error

public enum EditorError: LocalizedError, Sendable {
    case serializationFailed
    case documentNotFound(String)
    case invalidPath([String])

    public var errorDescription: String? {
        switch self {
        case .serializationFailed:
            return "Failed to serialize document"
        case .documentNotFound(let name):
            return "Document not found: \(name)"
        case .invalidPath(let path):
            return "Invalid path: \(path.joined(separator: "."))"
        }
    }
}
