import Foundation

// Re-export all dependencies
@_exported import GitCore
@_exported import JSONEditorCore
@_exported import JSONEditorUI

/// JSONEditorKit combines GitCore, JSONEditorCore, and JSONEditorUI into a single package.
///
/// This package provides:
/// - All exports from GitCore, JSONEditorCore, and JSONEditorUI
/// - `EditorCoordinator`: Base protocol for coordinating Git + JSON editing
/// - `DocumentManager`: Helper for batch operations
/// - Integration helpers for common patterns
public enum JSONEditorKit {
    /// The version of this package
    public static let version = "1.0.0"
}
