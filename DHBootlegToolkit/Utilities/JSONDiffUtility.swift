import Foundation

/// Utility for computing differences between two JSON structures
enum JSONDiffUtility {

    /// Computes change status for all leaf nodes by comparing current JSON to original JSON
    /// - Parameters:
    ///   - current: The current JSON dictionary
    ///   - original: The original JSON dictionary (from git HEAD)
    /// - Returns: Dictionary mapping path strings to their change status (only includes changed paths)
    static func computeChanges(
        current: [String: Any],
        original: [String: Any]?
    ) -> [String: JSONChangeStatus] {
        guard let original = original else {
            // No original = everything is new (file doesn't exist in git HEAD)
            // Return empty - we don't show badges for brand new files
            return [:]
        }

        var changes: [String: JSONChangeStatus] = [:]
        computeChangesRecursive(
            currentValue: current,
            originalValue: original,
            path: [],
            changes: &changes
        )
        return changes
    }

    private static func computeChangesRecursive(
        currentValue: Any,
        originalValue: Any?,
        path: [String],
        changes: inout [String: JSONChangeStatus]
    ) {
        let pathString = path.joined(separator: ".")

        // Handle dictionaries (objects)
        if let currentDict = currentValue as? [String: Any] {
            let originalDict = originalValue as? [String: Any]

            for key in currentDict.keys.sorted() {
                guard let value = currentDict[key] else { continue }
                let childPath = path + [key]
                let originalChild = originalDict?[key]

                computeChangesRecursive(
                    currentValue: value,
                    originalValue: originalChild,
                    path: childPath,
                    changes: &changes
                )
            }

            // Check for deleted keys (exist in original but not in current)
            if let originalDict = originalDict {
                for key in originalDict.keys where currentDict[key] == nil {
                    let childPath = path + [key]
                    let deletedPathString = childPath.joined(separator: ".")
                    changes[deletedPathString] = .deleted

                    // Recursively mark all nested fields as deleted
                    if let nestedOriginal = originalDict[key] {
                        markAllDeleted(nestedOriginal, path: childPath, changes: &changes)
                    }
                }
            }
            return
        }

        // Handle arrays
        if let currentArray = currentValue as? [Any] {
            let originalArray = originalValue as? [Any]

            for (index, value) in currentArray.enumerated() {
                let childPath = path + ["[\(index)]"]
                let originalChild: Any?
                if let origArray = originalArray, index < origArray.count {
                    originalChild = origArray[index]
                } else {
                    originalChild = nil
                }

                computeChangesRecursive(
                    currentValue: value,
                    originalValue: originalChild,
                    path: childPath,
                    changes: &changes
                )
            }

            // Check for deleted array elements (indices that existed in original but not in current)
            if let originalArray = originalArray, originalArray.count > currentArray.count {
                for index in currentArray.count..<originalArray.count {
                    let childPath = path + ["[\(index)]"]
                    let deletedPathString = childPath.joined(separator: ".")
                    changes[deletedPathString] = .deleted

                    // Recursively mark all nested fields as deleted
                    markAllDeleted(originalArray[index], path: childPath, changes: &changes)
                }
            }
            return
        }

        // Leaf node - compute change status
        guard !path.isEmpty else { return }

        if originalValue == nil {
            // Field doesn't exist in original = added
            changes[pathString] = .added
        } else if !valuesAreEqual(currentValue, originalValue!) {
            // Field exists but value differs = modified
            changes[pathString] = .modified
        }
        // If equal, don't add to dictionary (unchanged)
    }

    /// Recursively marks all nested fields as deleted
    private static func markAllDeleted(
        _ value: Any,
        path: [String],
        changes: inout [String: JSONChangeStatus]
    ) {
        if let dict = value as? [String: Any] {
            for (key, childValue) in dict {
                let childPath = path + [key]
                let childPathString = childPath.joined(separator: ".")
                changes[childPathString] = .deleted
                markAllDeleted(childValue, path: childPath, changes: &changes)
            }
        } else if let array = value as? [Any] {
            for (index, childValue) in array.enumerated() {
                let childPath = path + ["[\(index)]"]
                let childPathString = childPath.joined(separator: ".")
                changes[childPathString] = .deleted
                markAllDeleted(childValue, path: childPath, changes: &changes)
            }
        }
        // Leaf values don't need additional processing - the parent call already marked them
    }

    /// Compares two JSON values for equality
    private static func valuesAreEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        switch (lhs, rhs) {
        case (let l as String, let r as String):
            return l == r
        case (let l as Bool, let r as Bool):
            return l == r
        case (let l as NSNumber, let r as NSNumber):
            // Handle both int and float comparisons
            return l.isEqual(to: r)
        case (is NSNull, is NSNull):
            return true
        case (let l as [String: Any], let r as [String: Any]):
            // For objects, compare all keys and values
            guard l.keys.sorted() == r.keys.sorted() else { return false }
            for key in l.keys {
                guard let lVal = l[key], let rVal = r[key],
                      valuesAreEqual(lVal, rVal) else { return false }
            }
            return true
        case (let l as [Any], let r as [Any]):
            // For arrays, compare length and each element
            guard l.count == r.count else { return false }
            for (lVal, rVal) in zip(l, r) {
                guard valuesAreEqual(lVal, rVal) else { return false }
            }
            return true
        default:
            return false
        }
    }
}
