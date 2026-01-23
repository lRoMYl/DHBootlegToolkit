import Foundation

/// Represents an edit operation on a JSON document.
///
/// This enum encodes all possible JSON editing operations,
/// allowing for undo/redo functionality and operation tracking.
public enum JSONEditOperation: @unchecked Sendable {
    /// Set a value at a specific path
    case setValue(path: [String], value: Any)

    /// Add a new field to an object
    case addField(parentPath: [String], key: String, value: Any)

    /// Delete a field from an object
    case deleteField(path: [String])

    /// Delete an element from an array
    case deleteArrayElement(path: [String])

    /// Insert an element into an array
    case insertArrayElement(path: [String], value: Any, index: Int?)

    /// Move an array element from one index to another
    case moveArrayElement(arrayPath: [String], fromIndex: Int, toIndex: Int)

    /// Human-readable description of the operation
    public var description: String {
        switch self {
        case .setValue(let path, _):
            return "Set value at \(path.joined(separator: "."))"
        case .addField(let parentPath, let key, _):
            let fullPath = parentPath + [key]
            return "Add field at \(fullPath.joined(separator: "."))"
        case .deleteField(let path):
            return "Delete field at \(path.joined(separator: "."))"
        case .deleteArrayElement(let path):
            return "Delete array element at \(path.joined(separator: "."))"
        case .insertArrayElement(let path, _, let index):
            if let idx = index {
                return "Insert array element at \(path.joined(separator: "."))[\(idx)]"
            } else {
                return "Append array element to \(path.joined(separator: "."))"
            }
        case .moveArrayElement(let arrayPath, let from, let to):
            return "Move array element at \(arrayPath.joined(separator: ".")) from [\(from)] to [\(to)]"
        }
    }
}

// MARK: - Operation Application

extension JSONEditOperation {
    /// Applies this operation to a JSON dictionary
    /// - Parameter json: The JSON dictionary to modify
    /// - Returns: The modified JSON dictionary, or nil if the operation failed
    public func apply(to json: [String: Any]) -> [String: Any]? {
        switch self {
        case .setValue(let path, let value):
            return applySetValue(to: json, at: path, value: value)

        case .addField(let parentPath, let key, let value):
            return applyAddField(to: json, at: parentPath, key: key, value: value)

        case .deleteField(let path):
            return applyDeleteField(from: json, at: path)

        case .deleteArrayElement(let path):
            return applyDeleteArrayElement(from: json, at: path)

        case .insertArrayElement(let path, let value, let index):
            return applyInsertArrayElement(to: json, at: path, value: value, index: index)

        case .moveArrayElement(let arrayPath, let fromIndex, let toIndex):
            return applyMoveArrayElement(in: json, at: arrayPath, from: fromIndex, to: toIndex)
        }
    }

    // MARK: - Private Helpers

    private func applySetValue(to json: [String: Any], at path: [String], value: Any) -> [String: Any]? {
        guard !path.isEmpty else { return nil }
        let result = setValue(in: json, at: path, value: value) as? [String: Any]
        return result
    }

    private func applyAddField(to json: [String: Any], at parentPath: [String], key: String, value: Any) -> [String: Any]? {
        let fullPath = parentPath + [key]
        return applySetValue(to: json, at: fullPath, value: value)
    }

    private func applyDeleteField(from json: [String: Any], at path: [String]) -> [String: Any]? {
        guard !path.isEmpty else { return nil }
        let result = deleteValue(in: json, at: path) as? [String: Any]
        return result
    }

    private func applyDeleteArrayElement(from json: [String: Any], at path: [String]) -> [String: Any]? {
        guard path.count >= 2 else { return nil }
        let arrayPath = Array(path.dropLast())
        guard let indexString = path.last,
              let index = Int(indexString) else { return nil }

        guard var array = getValue(in: json, at: arrayPath) as? [Any] else { return nil }
        guard index >= 0 && index < array.count else { return nil }

        array.remove(at: index)
        let result = setValue(in: json, at: arrayPath, value: array) as? [String: Any]
        return result
    }

    private func applyInsertArrayElement(to json: [String: Any], at path: [String], value: Any, index: Int?) -> [String: Any]? {
        guard var array = getValue(in: json, at: path) as? [Any] else { return nil }

        if let idx = index {
            guard idx >= 0 && idx <= array.count else { return nil }
            array.insert(value, at: idx)
        } else {
            array.append(value)
        }

        let result = setValue(in: json, at: path, value: array) as? [String: Any]
        return result
    }

    private func applyMoveArrayElement(in json: [String: Any], at arrayPath: [String], from: Int, to: Int) -> [String: Any]? {
        guard var array = getValue(in: json, at: arrayPath) as? [Any] else { return nil }
        guard from >= 0 && from < array.count && to >= 0 && to < array.count else { return nil }

        let element = array.remove(at: from)
        array.insert(element, at: to)

        let result = setValue(in: json, at: arrayPath, value: array) as? [String: Any]
        return result
    }

    // Recursive helpers
    private func setValue(in dict: Any, at path: [String], value: Any) -> Any {
        guard !path.isEmpty else { return value }
        guard var dictionary = dict as? [String: Any] else { return dict }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        if remainingPath.isEmpty {
            dictionary[key] = value
        } else {
            if let nested = dictionary[key] {
                dictionary[key] = setValue(in: nested, at: remainingPath, value: value)
            }
        }

        return dictionary
    }

    private func deleteValue(in dict: Any, at path: [String]) -> Any {
        guard !path.isEmpty else { return dict }
        guard var dictionary = dict as? [String: Any] else { return dict }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        if remainingPath.isEmpty {
            dictionary.removeValue(forKey: key)
        } else {
            if let nested = dictionary[key] {
                dictionary[key] = deleteValue(in: nested, at: remainingPath)
            }
        }

        return dictionary
    }

    private func getValue(in dict: Any, at path: [String]) -> Any? {
        guard !path.isEmpty else { return dict }
        guard let dictionary = dict as? [String: Any] else { return nil }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        if remainingPath.isEmpty {
            return dictionary[key]
        } else {
            if let nested = dictionary[key] {
                return getValue(in: nested, at: remainingPath)
            }
            return nil
        }
    }
}
