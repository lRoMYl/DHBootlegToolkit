import Foundation
import SwiftUI
import JSONEditorCore

/// JSONEditorUI provides SwiftUI components for displaying and editing JSON.
///
/// This package includes:
/// - `JSONTreeView`: Main tree view component
/// - `JSONTreeViewModel`: State management for tree view
/// - `JSONStringEditor`, `JSONBoolEditor`, `JSONNumberEditor`: Type-specific editors
/// - `TypeBadge`: Visual type indicators
/// - `AddFieldSheet`, `InsertArrayElementSheet`: Modal sheets for editing
public enum JSONEditorUI {
    /// The version of this package
    public static let version = "1.0.0"
}
