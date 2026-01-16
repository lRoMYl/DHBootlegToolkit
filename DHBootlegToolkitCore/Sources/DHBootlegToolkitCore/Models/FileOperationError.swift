import Foundation

/// Errors that can occur during file save operations.
public enum FileOperationError: LocalizedError, Sendable, Equatable {
    case noFeatureSelected
    case fileSystemNotInitialized
    case fileDeleted(path: String)
    case externallyModified(path: String)
    case saveFailed(underlying: String)

    public var errorDescription: String? {
        switch self {
        case .noFeatureSelected:
            return "No feature selected. Please select a feature first."
        case .fileSystemNotInitialized:
            return "File system not initialized. Please open a repository first."
        case .fileDeleted(let path):
            return "File was deleted externally: \(path)"
        case .externallyModified(let path):
            return "File was modified externally: \(path)"
        case .saveFailed(let underlying):
            return "Failed to save: \(underlying)"
        }
    }

    /// Whether this error can be resolved by user confirmation (force overwrite)
    public var canForceOverwrite: Bool {
        switch self {
        case .externallyModified: return true
        default: return false
        }
    }
}
