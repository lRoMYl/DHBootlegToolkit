import SwiftUI
import Observation

/// Identifies a unique editable field in the JSON tree
struct FieldIdentifier: Hashable {
    let nodePath: String
    let fieldType: FieldType

    enum FieldType: String {
        case string
        case number
        case searchBar
    }

    static func field(_ path: [String], type: FieldType) -> FieldIdentifier {
        FieldIdentifier(nodePath: path.joined(separator: "."), fieldType: type)
    }

    static let searchBar = FieldIdentifier(nodePath: "", fieldType: .searchBar)
}

/// Manages focus state for all editable fields in the S3 editor
@Observable
final class FieldFocusCoordinator {
    var focusedField: FieldIdentifier? = nil

    func requestFocus(_ field: FieldIdentifier) {
        focusedField = field
    }

    func clearFocus() {
        focusedField = nil
    }

    func isFocused(_ field: FieldIdentifier) -> Bool {
        focusedField == field
    }
}
