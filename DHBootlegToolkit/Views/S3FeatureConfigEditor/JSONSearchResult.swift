import SwiftUI

// MARK: - JSON Search Matches

/// Ordered list of matching paths for navigation
struct JSONSearchMatches {
    let paths: [[String]]
    private(set) var currentIndex: Int = 0

    var count: Int { paths.count }
    var isEmpty: Bool { paths.isEmpty }

    var currentPath: [String]? {
        guard !paths.isEmpty else { return nil }
        return paths[currentIndex]
    }

    /// 1-based index for display
    var displayIndex: Int {
        isEmpty ? 0 : currentIndex + 1
    }

    mutating func next() {
        guard !paths.isEmpty else { return }
        currentIndex = (currentIndex + 1) % paths.count
    }

    mutating func previous() {
        guard !paths.isEmpty else { return }
        currentIndex = (currentIndex - 1 + paths.count) % paths.count
    }

    /// Reset to first match
    mutating func reset() {
        currentIndex = 0
    }

    static let empty = JSONSearchMatches(paths: [])

    /// Build matches from JSON, searching keys and string values
    static func build(from json: [String: Any], query: String) -> JSONSearchMatches {
        guard !query.isEmpty else { return .empty }

        var matchingPaths: [[String]] = []
        let lowercaseQuery = query.lowercased()

        func search(in value: Any, path: [String], key: String) {
            let currentPath = path + [key]
            let keyMatches = key.lowercased().contains(lowercaseQuery)

            if let dict = value as? [String: Any] {
                if keyMatches {
                    matchingPaths.append(currentPath)
                }
                for childKey in dict.keys.sorted() {
                    search(in: dict[childKey]!, path: currentPath, key: childKey)
                }
            } else if let array = value as? [Any] {
                if keyMatches {
                    matchingPaths.append(currentPath)
                }
                for (index, item) in array.enumerated() {
                    search(in: item, path: currentPath, key: "[\(index)]")
                }
            } else if let string = value as? String {
                let valueMatches = string.lowercased().contains(lowercaseQuery)
                if keyMatches || valueMatches {
                    matchingPaths.append(currentPath)
                }
            } else if keyMatches {
                // number, bool, null - only match on key
                matchingPaths.append(currentPath)
            }
        }

        for key in json.keys.sorted() {
            search(in: json[key]!, path: [], key: key)
        }

        return JSONSearchMatches(paths: matchingPaths)
    }
}

