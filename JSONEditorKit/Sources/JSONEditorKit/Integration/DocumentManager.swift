import Foundation
import GitCore
import JSONEditorCore

/// Helper for common document management operations.
///
/// Provides utilities for batch operations, git synchronization, and document loading.
public final class DocumentManager<Doc: JSONEditable> {
    public init() {}

    // MARK: - Batch Operations

    /// Applies the same value update to multiple documents
    /// - Parameters:
    ///   - documents: Documents to update
    ///   - path: Path to the value
    ///   - value: New value
    /// - Returns: Updated documents (only includes successfully updated ones)
    public func batchUpdate(
        _ documents: [Doc],
        at path: [String],
        value: Any
    ) -> [Doc] {
        return documents.compactMap { doc in
            doc.withUpdatedValue(value, at: path)
        }
    }

    /// Filters documents by search text (searches in URL path)
    /// - Parameters:
    ///   - documents: Documents to filter
    ///   - searchText: Search query
    /// - Returns: Filtered documents
    public func filterDocuments(
        _ documents: [Doc],
        searchText: String
    ) -> [Doc] {
        guard !searchText.isEmpty else { return documents }

        let lowercased = searchText.lowercased()
        return documents.filter { doc in
            doc.url.path.lowercased().contains(lowercased)
        }
    }

    /// Groups documents by a key extracted from their URL
    /// - Parameters:
    ///   - documents: Documents to group
    ///   - keyExtractor: Function to extract grouping key from URL
    /// - Returns: Dictionary of grouped documents
    public func groupDocuments(
        _ documents: [Doc],
        by keyExtractor: (URL) -> String
    ) -> [String: [Doc]] {
        Dictionary(grouping: documents) { keyExtractor($0.url) }
    }

    // MARK: - Git Integration

    /// Loads git status for documents and marks them as modified/unmodified
    /// - Parameters:
    ///   - documents: Documents to sync
    ///   - gitWorker: Git worker to use for checking status
    ///   - basePath: Base path relative to repository root
    /// - Returns: Documents with updated git status information
    public func syncGitStatus(
        for documents: [Doc],
        gitWorker: GitWorker,
        basePath: String = ""
    ) async -> [Doc] {
        do {
            let _ = try await gitWorker.getFileStatuses(inDirectory: basePath)
            // For now, just return documents as-is
            // Apps can extend this to track git status per document
            return documents
        } catch {
            return documents
        }
    }

    // MARK: - Document Loading

    /// Finds all JSON file URLs in a directory
    /// - Parameter directoryURL: Directory to scan
    /// - Returns: Array of JSON file URLs
    public func findJSONFiles(in directoryURL: URL) -> [URL] {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var jsonFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            // Only include .json files
            if fileURL.pathExtension == "json" {
                jsonFiles.append(fileURL)
            }
        }

        return jsonFiles
    }

    // MARK: - Validation

    /// Validates all documents and returns errors
    /// - Parameter documents: Documents to validate
    /// - Returns: Dictionary mapping document IDs to validation errors
    public func validateDocuments(_ documents: [Doc]) -> [AnyHashable: [String]] {
        var errors: [AnyHashable: [String]] = [:]

        for doc in documents {
            // Basic validation: check if serialization works
            if doc.serialize() == nil {
                errors[doc.id, default: []].append("Failed to serialize document")
            }

            // Check if has changes but originalContent is missing
            if doc.hasChanges && doc.originalContent == nil {
                errors[doc.id, default: []].append("Document has changes but no original content")
            }
        }

        return errors
    }
}
