import SwiftUI
import Observation

/// Identifies a unique editable field in the JSON tree
public struct FieldIdentifier: Hashable, Sendable {
    public let nodePath: String
    public let fieldType: FieldType

    public enum FieldType: String, Sendable {
        case string
        case number
        case searchBar
    }

    public init(nodePath: String, fieldType: FieldType) {
        self.nodePath = nodePath
        self.fieldType = fieldType
    }

    public static func field(_ path: [String], type: FieldType) -> FieldIdentifier {
        FieldIdentifier(nodePath: path.joined(separator: "."), fieldType: type)
    }

    public static let searchBar = FieldIdentifier(nodePath: "", fieldType: .searchBar)
}

/// Manages focus state for all editable fields in the JSON editor
@Observable
public final class FieldFocusCoordinator {
    public var focusedField: FieldIdentifier? = nil

    public init() {}

    public func requestFocus(_ field: FieldIdentifier) {
        focusedField = field
    }

    public func clearFocus() {
        focusedField = nil
    }

    public func isFocused(_ field: FieldIdentifier) -> Bool {
        focusedField == field
    }
}
