import Foundation

// MARK: - S3 JSON Serializer

/// Handles JSON serialization with key order preservation for S3 configs.
/// This ensures minimal git diffs by maintaining original key ordering.
public enum S3JSONSerializer {

    // MARK: - Public API

    /// Serializes JSON dictionary preserving key order from original content.
    /// - Parameters:
    ///   - json: The JSON dictionary to serialize
    ///   - original: The original JSON string to extract key order from
    /// - Returns: JSON string with preserved key ordering
    public static func serialize(_ json: [String: Any], preservingOrderFrom original: String) -> String {
        let indentUnit = detectIndentation(from: original)
        let keyOrderMap = extractKeyOrderMap(from: original)
        return buildOrderedJSON(json, keyOrderMap: keyOrderMap, currentPath: "", indent: 0, indentUnit: indentUnit)
    }

    /// Replaces a single value at the given path without modifying other parts of the file.
    /// This ensures minimal git diffs by only changing the specific value.
    /// - Parameters:
    ///   - originalContent: The original JSON file content
    ///   - path: The path components to the value (e.g., ["features", "darkMode", "enabled"])
    ///   - newValue: The new value to set
    /// - Returns: The modified JSON content, or nil if the path doesn't exist
    public static func replaceValue(
        in originalContent: String,
        at path: [String],
        with newValue: Any
    ) -> String? {
        guard !path.isEmpty else { return nil }

        // Find the range of the value to replace
        guard let valueRange = findValueRange(in: originalContent, at: path) else {
            return nil
        }

        // Serialize the new value
        let indentUnit = detectIndentation(from: originalContent)
        let depth = path.count
        let serializedValue = serializeValueForReplacement(
            newValue,
            indentUnit: indentUnit,
            depth: depth,
            originalContent: originalContent,
            path: path
        )

        // Replace the value in the original content
        var result = originalContent
        result.replaceSubrange(valueRange, with: serializedValue)

        return result
    }

    /// Deletes a value at the specified path in the original JSON string.
    /// This ensures minimal git diffs by only removing the specific field.
    /// - Parameters:
    ///   - originalContent: The original JSON file content
    ///   - path: The path components to the value (e.g., ["features", "darkMode"])
    /// - Returns: The modified JSON content, or nil if the path doesn't exist
    public static func deleteValue(in originalContent: String, at path: [String]) -> String? {
        guard !path.isEmpty else { return nil }

        // Find the range of the key-value pair to delete
        guard let valueRange = findValueRange(in: originalContent, at: path) else {
            return nil
        }

        // Find the key before the value
        guard let keyRange = findKeyRange(in: originalContent, beforeValue: valueRange, key: path.last!) else {
            return nil
        }

        // Determine the full range to delete (including key, colon, value, and comma/newline)
        let deleteRange = findFullDeletionRange(
            in: originalContent,
            keyRange: keyRange,
            valueRange: valueRange
        )

        // Remove the range
        var result = originalContent
        result.removeSubrange(deleteRange)

        return result
    }

    /// Finds the character range of the key (including quotes) that precedes the value.
    private static func findKeyRange(
        in content: String,
        beforeValue valueRange: Range<String.Index>,
        key: String
    ) -> Range<String.Index>? {
        var searchIndex = valueRange.lowerBound

        // Search backwards for the key
        while searchIndex > content.startIndex {
            searchIndex = content.index(before: searchIndex)
            let char = content[searchIndex]

            // Look for the key pattern: "key"
            if char == "\"" {
                // Check if this might be the closing quote of our key
                guard let keyStart = findKeyStart(in: content, endingAt: searchIndex) else {
                    continue
                }

                let keyContent = String(content[content.index(after: keyStart)..<searchIndex])
                if keyContent == key {
                    // Verify this is followed by a colon and then our value
                    var afterKey = content.index(after: searchIndex)
                    while afterKey < content.endIndex && content[afterKey].isWhitespace {
                        afterKey = content.index(after: afterKey)
                    }
                    if afterKey < content.endIndex && content[afterKey] == ":" {
                        return keyStart..<content.index(after: searchIndex)
                    }
                }
            }
        }

        return nil
    }

    /// Finds the starting quote of a key, searching backwards from the ending quote.
    private static func findKeyStart(in content: String, endingAt endQuote: String.Index) -> String.Index? {
        var index = endQuote
        var escapeNext = false

        while index > content.startIndex {
            index = content.index(before: index)
            let char = content[index]

            if escapeNext {
                escapeNext = false
                continue
            }

            if char == "\\" {
                escapeNext = true
                continue
            }

            if char == "\"" {
                return index
            }
        }

        return nil
    }

    /// Finds the full range to delete, including key, colon, value, and trailing comma/newline.
    private static func findFullDeletionRange(
        in content: String,
        keyRange: Range<String.Index>,
        valueRange: Range<String.Index>
    ) -> Range<String.Index> {
        var start = keyRange.lowerBound
        var end = valueRange.upperBound

        // Check for leading whitespace/newline before the key
        var beforeKey = start
        while beforeKey > content.startIndex {
            let prevIndex = content.index(before: beforeKey)
            let char = content[prevIndex]
            if char.isWhitespace {
                beforeKey = prevIndex
            } else {
                break
            }
        }

        // Check for trailing comma and whitespace after the value
        var afterValue = end
        var foundComma = false
        while afterValue < content.endIndex {
            let char = content[afterValue]
            if char == "," && !foundComma {
                foundComma = true
                afterValue = content.index(after: afterValue)
            } else if char.isWhitespace {
                afterValue = content.index(after: afterValue)
            } else {
                break
            }
        }

        // If we found a trailing comma, include everything up to the next non-whitespace
        if foundComma {
            end = afterValue
            // Also check if we should include the line before
            start = beforeKey
        } else {
            // No trailing comma - might be the last element
            // Check for a comma before the key
            var beforeWhitespace = beforeKey
            while beforeWhitespace > content.startIndex {
                let prevIndex = content.index(before: beforeWhitespace)
                let char = content[prevIndex]
                if char == "," {
                    start = prevIndex
                    break
                } else if char.isWhitespace {
                    beforeWhitespace = prevIndex
                } else {
                    break
                }
            }
            end = afterValue
        }

        return start..<end
    }

    // MARK: - Indentation Detection

    /// Detects the indentation unit used in the original JSON content.
    /// Returns the string used for one level of indentation (e.g., "  ", "    ", "\t")
    public static func detectIndentation(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var minIndentLength = Int.max

        for line in lines {
            // Skip empty lines
            guard !line.isEmpty else { continue }

            // Count leading whitespace
            var leadingWhitespace = ""
            for char in line {
                if char == " " || char == "\t" {
                    leadingWhitespace.append(char)
                } else {
                    break
                }
            }

            // If we found indentation, track the minimum
            if !leadingWhitespace.isEmpty {
                // Check for tabs - if any line uses tabs, assume tab indentation
                if leadingWhitespace.hasPrefix("\t") {
                    return "\t"
                }

                // Track the smallest indentation (which should be one level)
                if leadingWhitespace.count < minIndentLength {
                    minIndentLength = leadingWhitespace.count
                }
            }
        }

        // Return the detected indent unit based on minimum indentation found
        if minIndentLength != Int.max && minIndentLength > 0 {
            return String(repeating: " ", count: minIndentLength)
        }

        // Default to 2 spaces
        return "  "
    }

    // MARK: - Value Range Finding

    /// Finds the character range of a value at the given path in JSON content.
    /// - Parameters:
    ///   - content: The JSON content string
    ///   - pathComponents: The path to the value (e.g., ["features", "enabled"])
    /// - Returns: The range of the value in the string, or nil if not found
    private static func findValueRange(
        in content: String,
        at pathComponents: [String]
    ) -> Range<String.Index>? {
        var currentIndex = content.startIndex
        var currentDepth = 0
        var pathIndex = 0
        var inString = false
        var escapeNext = false

        // State for tracking where we are in the JSON
        var foundKeyAtDepth: Int?

        while currentIndex < content.endIndex && pathIndex < pathComponents.count {
            let char = content[currentIndex]

            // Handle escape sequences in strings
            if escapeNext {
                escapeNext = false
                currentIndex = content.index(after: currentIndex)
                continue
            }

            if char == "\\" && inString {
                escapeNext = true
                currentIndex = content.index(after: currentIndex)
                continue
            }

            // Track string boundaries
            if char == "\"" {
                if !inString {
                    inString = true
                    // Check if this is the key we're looking for
                    if foundKeyAtDepth == nil {
                        let targetKey = pathComponents[pathIndex]
                        let keyEndIndex = findStringEnd(in: content, from: content.index(after: currentIndex))
                        if let keyEnd = keyEndIndex {
                            let keyContent = String(content[content.index(after: currentIndex)..<keyEnd])
                            if keyContent == targetKey {
                                // Check if this key is followed by a colon
                                var afterKey = content.index(after: keyEnd)
                                while afterKey < content.endIndex && content[afterKey].isWhitespace {
                                    afterKey = content.index(after: afterKey)
                                }
                                if afterKey < content.endIndex && content[afterKey] == ":" {
                                    // Found the key at the expected depth
                                    // Check if depth matches expected (accounting for arrays)
                                    let expectedDepth = countObjectDepth(in: pathComponents, upTo: pathIndex)
                                    if currentDepth == expectedDepth {
                                        foundKeyAtDepth = currentDepth
                                        // Move past the colon
                                        var valueStart = content.index(after: afterKey)
                                        while valueStart < content.endIndex && content[valueStart].isWhitespace {
                                            valueStart = content.index(after: valueStart)
                                        }

                                        // If this is the last path component, we found it
                                        if pathIndex == pathComponents.count - 1 {
                                            let valueEnd = findValueEnd(in: content, from: valueStart)
                                            if let end = valueEnd {
                                                return valueStart..<end
                                            }
                                            return nil
                                        } else {
                                            // Need to go deeper - reset inString since we're jumping out of the key
                                            pathIndex += 1
                                            foundKeyAtDepth = nil
                                            currentIndex = valueStart
                                            inString = false
                                            continue
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    inString = false
                }
            }

            // Track object/array depth
            if !inString {
                if char == "{" || char == "[" {
                    // Check if we're entering an array and the next path component is an index
                    if char == "[" && pathIndex < pathComponents.count {
                        // Strip brackets from array index (e.g., "[0]" -> "0")
                        let indexStr = pathComponents[pathIndex]
                            .replacingOccurrences(of: "[", with: "")
                            .replacingOccurrences(of: "]", with: "")
                        if let arrayIndex = Int(indexStr) {
                            // Find the element at this index
                            if let elementRange = findArrayElementRange(in: content, from: currentIndex, index: arrayIndex) {
                                if pathIndex == pathComponents.count - 1 {
                                    // This is the final element we're looking for
                                    return elementRange
                                } else {
                                    // Need to go deeper into this element
                                    currentIndex = elementRange.lowerBound
                                    pathIndex += 1
                                    continue
                                }
                            }
                        }
                    }
                    currentDepth += 1
                } else if char == "}" || char == "]" {
                    currentDepth -= 1
                }
            }

            currentIndex = content.index(after: currentIndex)
        }

        return nil
    }

    /// Counts the expected object depth for a given path index.
    /// Array indices don't increase object depth.
    private static func countObjectDepth(in pathComponents: [String], upTo index: Int) -> Int {
        var depth = 1 // Start at 1 for the root object
        for i in 0..<index {
            // Strip brackets to check if this is an array index
            let stripped = pathComponents[i]
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
            if Int(stripped) == nil {
                // Not an array index, so it's an object key
                depth += 1
            }
        }
        return depth
    }

    /// Finds the end index of a string (after the closing quote).
    private static func findStringEnd(in content: String, from start: String.Index) -> String.Index? {
        var index = start
        var escapeNext = false

        while index < content.endIndex {
            let char = content[index]

            if escapeNext {
                escapeNext = false
                index = content.index(after: index)
                continue
            }

            if char == "\\" {
                escapeNext = true
                index = content.index(after: index)
                continue
            }

            if char == "\"" {
                return index
            }

            index = content.index(after: index)
        }

        return nil
    }

    /// Finds the end of a JSON value starting at the given index.
    private static func findValueEnd(in content: String, from start: String.Index) -> String.Index? {
        guard start < content.endIndex else { return nil }

        let firstChar = content[start]

        // String value
        if firstChar == "\"" {
            if let stringEnd = findStringEnd(in: content, from: content.index(after: start)) {
                return content.index(after: stringEnd)
            }
            return nil
        }

        // Object or array value
        if firstChar == "{" || firstChar == "[" {
            let closingChar: Character = firstChar == "{" ? "}" : "]"
            var depth = 1
            var index = content.index(after: start)
            var inString = false
            var escapeNext = false

            while index < content.endIndex && depth > 0 {
                let char = content[index]

                if escapeNext {
                    escapeNext = false
                    index = content.index(after: index)
                    continue
                }

                if char == "\\" && inString {
                    escapeNext = true
                    index = content.index(after: index)
                    continue
                }

                if char == "\"" {
                    inString.toggle()
                } else if !inString {
                    if char == firstChar {
                        depth += 1
                    } else if char == closingChar {
                        depth -= 1
                    }
                }

                index = content.index(after: index)
            }

            return index
        }

        // Primitive value (number, boolean, null)
        var index = start
        while index < content.endIndex {
            let char = content[index]
            if char == "," || char == "}" || char == "]" || char.isNewline {
                return index
            }
            index = content.index(after: index)
        }

        return index
    }

    /// Finds the range of an array element at the given index.
    private static func findArrayElementRange(
        in content: String,
        from arrayStart: String.Index,
        index targetIndex: Int
    ) -> Range<String.Index>? {
        var currentIndex = content.index(after: arrayStart) // Skip opening bracket
        var elementIndex = 0
        var depth = 0
        var inString = false
        var escapeNext = false

        // Skip whitespace
        while currentIndex < content.endIndex && content[currentIndex].isWhitespace {
            currentIndex = content.index(after: currentIndex)
        }

        var elementStart = currentIndex

        while currentIndex < content.endIndex {
            let char = content[currentIndex]

            if escapeNext {
                escapeNext = false
                currentIndex = content.index(after: currentIndex)
                continue
            }

            if char == "\\" && inString {
                escapeNext = true
                currentIndex = content.index(after: currentIndex)
                continue
            }

            if char == "\"" {
                inString.toggle()
            } else if !inString {
                if char == "{" || char == "[" {
                    depth += 1
                } else if char == "}" || char == "]" {
                    if depth == 0 {
                        // End of array
                        if elementIndex == targetIndex {
                            // Validate range bounds before creating range
                            guard elementStart < currentIndex else {
                                return nil  // Invalid range (empty element or trailing comma)
                            }
                            return elementStart..<currentIndex
                        }
                        return nil
                    }
                    depth -= 1
                } else if char == "," && depth == 0 {
                    // End of current element
                    if elementIndex == targetIndex {
                        // Validate range bounds before creating range
                        guard elementStart < currentIndex else {
                            return nil  // Invalid range (empty element)
                        }
                        return elementStart..<currentIndex
                    }
                    elementIndex += 1
                    // Skip comma and whitespace for next element
                    currentIndex = content.index(after: currentIndex)
                    while currentIndex < content.endIndex && content[currentIndex].isWhitespace {
                        currentIndex = content.index(after: currentIndex)
                    }
                    elementStart = currentIndex
                    continue
                }
            }

            currentIndex = content.index(after: currentIndex)
        }

        return nil
    }

    // MARK: - Value Serialization for Replacement

    /// Serializes a value for targeted replacement, matching the original file's style.
    /// - Parameters:
    ///   - value: The value to serialize
    ///   - indentUnit: The indentation string (e.g., "  " or "\t")
    ///   - depth: Current nesting depth
    ///   - originalContent: Original file content to extract key order from (optional)
    ///   - path: Current path in the JSON structure
    private static func serializeValueForReplacement(
        _ value: Any,
        indentUnit: String,
        depth: Int,
        originalContent: String? = nil,
        path: [String] = []
    ) -> String {
        if let string = value as? String {
            return escapeJSONString(string)
        } else if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            if CFNumberIsFloatType(number) {
                return "\(number.doubleValue)"
            }
            return "\(number.intValue)"
        } else if value is NSNull {
            return "null"
        } else if let dict = value as? [String: Any] {
            if dict.isEmpty { return "{}" }
            let baseIndent = String(repeating: indentUnit, count: depth)
            let childIndent = String(repeating: indentUnit, count: depth + 1)
            var lines = ["{"]

            // Extract key order from original content if available
            var orderedKeys: [String]
            if let original = originalContent {
                let currentPath = path.joined(separator: ".")
                let existingOrder = extractKeyOrderAtPath(from: original, path: currentPath)
                // Use existing order for keys that exist, append new keys at end
                orderedKeys = existingOrder.filter { dict[$0] != nil }
                let newKeys = dict.keys.filter { !existingOrder.contains($0) }.sorted()
                orderedKeys.append(contentsOf: newKeys)
            } else {
                orderedKeys = Array(dict.keys)
            }

            for (index, key) in orderedKeys.enumerated() {
                let childValue = dict[key]!
                let childPath = path + [key]
                let serializedChild = serializeValueForReplacement(
                    childValue,
                    indentUnit: indentUnit,
                    depth: depth + 1,
                    originalContent: originalContent,
                    path: childPath
                )
                let comma = index < orderedKeys.count - 1 ? "," : ""
                lines.append("\(childIndent)\"\(escapeJSONKey(key))\": \(serializedChild)\(comma)")
            }
            lines.append("\(baseIndent)}")
            return lines.joined(separator: "\n")
        } else if let array = value as? [Any] {
            if array.isEmpty { return "[]" }
            // Always format arrays with one element per line for consistency
            let baseIndent = String(repeating: indentUnit, count: depth)
            let childIndent = String(repeating: indentUnit, count: depth + 1)
            var lines = ["["]
            for (index, item) in array.enumerated() {
                let childPath = path + ["\(index)"]
                let serializedItem = serializeValueForReplacement(
                    item,
                    indentUnit: indentUnit,
                    depth: depth + 1,
                    originalContent: originalContent,
                    path: childPath
                )
                let comma = index < array.count - 1 ? "," : ""
                lines.append("\(childIndent)\(serializedItem)\(comma)")
            }
            lines.append("\(baseIndent)]")
            return lines.joined(separator: "\n")
        }
        return "null"
    }

    // MARK: - Key Order Extraction

    /// Extracts the hierarchical key order from JSON content.
    /// Returns a map of JSON path -> ordered keys at that level.
    /// e.g., "" -> ["features", "settings"], "features" -> ["darkMode", "analytics"]
    private static func extractKeyOrderMap(from content: String) -> [String: [String]] {
        var result: [String: [String]] = [:]
        var pathStack: [String] = []
        var currentPathKeys: [String: [String]] = ["": []]

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            guard !trimmed.isEmpty else { continue }

            // Detect key-value pairs: "keyName": value or "keyName": {
            if trimmed.hasPrefix("\"") {
                if let colonIndex = trimmed.firstIndex(of: ":") {
                    let keyPart = trimmed[..<colonIndex]
                    // Extract key name (remove quotes)
                    if keyPart.hasPrefix("\"") && keyPart.hasSuffix("\"") {
                        let keyName = String(keyPart.dropFirst().dropLast())
                        let currentPath = pathStack.joined(separator: ".")

                        // Add key to current path's ordered keys
                        if currentPathKeys[currentPath] == nil {
                            currentPathKeys[currentPath] = []
                        }
                        currentPathKeys[currentPath]?.append(keyName)

                        // Check if this opens an object
                        let afterColon = trimmed[trimmed.index(after: colonIndex)...]
                            .trimmingCharacters(in: .whitespaces)
                        if afterColon.hasPrefix("{") {
                            // Push to path stack
                            pathStack.append(keyName)
                            let newPath = pathStack.joined(separator: ".")
                            currentPathKeys[newPath] = []
                        } else if afterColon.hasPrefix("[") && !afterColon.contains("]") {
                            // Array that spans multiple lines - push to path stack
                            pathStack.append(keyName)
                            let newPath = pathStack.joined(separator: ".")
                            currentPathKeys[newPath] = []
                        }
                    }
                }
            }
            // Detect closing brace/bracket
            else if trimmed.hasPrefix("}") || trimmed.hasPrefix("]") {
                if !pathStack.isEmpty {
                    pathStack.removeLast()
                }
            }
        }

        // Copy to result
        for (path, keys) in currentPathKeys {
            if !keys.isEmpty {
                result[path] = keys
            }
        }

        return result
    }

    /// Extracts the key order at a specific path in the JSON content.
    /// - Parameters:
    ///   - content: The JSON content string
    ///   - path: The dot-separated path (e.g., "address_config" or "features.darkMode")
    /// - Returns: Array of keys in their original order at the specified path
    private static func extractKeyOrderAtPath(from content: String, path: String) -> [String] {
        let keyOrderMap = extractKeyOrderMap(from: content)
        return keyOrderMap[path] ?? []
    }

    // MARK: - JSON Building

    /// Recursively builds JSON string preserving key order.
    private static func buildOrderedJSON(
        _ value: Any,
        keyOrderMap: [String: [String]],
        currentPath: String,
        indent: Int,
        indentUnit: String = "  "
    ) -> String {
        let indentString = String(repeating: indentUnit, count: indent)
        let childIndentString = String(repeating: indentUnit, count: indent + 1)

        if let dict = value as? [String: Any] {
            guard !dict.isEmpty else { return "{}" }

            // Get original key order for this path, or sort alphabetically
            let originalOrder = keyOrderMap[currentPath] ?? []

            // Build ordered key list: original keys first (in order), then new keys
            var orderedKeys: [String] = []
            for key in originalOrder where dict[key] != nil {
                orderedKeys.append(key)
            }
            // Add new keys (not in original) at the end, sorted
            let newKeys = dict.keys.filter { !originalOrder.contains($0) }.sorted()
            orderedKeys.append(contentsOf: newKeys)

            var lines: [String] = ["{"]
            for (index, key) in orderedKeys.enumerated() {
                guard let childValue = dict[key] else { continue }
                let childPath = currentPath.isEmpty ? key : "\(currentPath).\(key)"
                let childJSON = buildOrderedJSON(childValue, keyOrderMap: keyOrderMap, currentPath: childPath, indent: indent + 1, indentUnit: indentUnit)
                let comma = index < orderedKeys.count - 1 ? "," : ""
                lines.append("\(childIndentString)\"\(escapeJSONKey(key))\": \(childJSON)\(comma)")
            }
            lines.append("\(indentString)}")
            return lines.joined(separator: "\n")

        } else if let array = value as? [Any] {
            guard !array.isEmpty else { return "[]" }

            // Always format arrays with one element per line for consistency
            var lines: [String] = ["["]
            for (index, item) in array.enumerated() {
                let itemPath = "\(currentPath).\(index)"
                let itemJSON = buildOrderedJSON(item, keyOrderMap: keyOrderMap, currentPath: itemPath, indent: indent + 1, indentUnit: indentUnit)
                let comma = index < array.count - 1 ? "," : ""
                lines.append("\(childIndentString)\(itemJSON)\(comma)")
            }
            lines.append("\(indentString)]")
            return lines.joined(separator: "\n")

        } else {
            return serializeSimpleValue(value)
        }
    }

    // MARK: - Value Serialization

    /// Checks if a value is simple (can be serialized on one line).
    private static func isSimpleValue(_ value: Any) -> Bool {
        if value is String || value is NSNumber || value is NSNull {
            return true
        }
        if let array = value as? [Any], array.isEmpty {
            return true
        }
        if let dict = value as? [String: Any], dict.isEmpty {
            return true
        }
        return false
    }

    /// Serializes a simple value to JSON string.
    private static func serializeSimpleValue(_ value: Any) -> String {
        if let string = value as? String {
            return escapeJSONString(string)
        } else if let number = value as? NSNumber {
            // Check if it's a boolean
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            // Check if it's a float
            if CFNumberIsFloatType(number) {
                return "\(number.doubleValue)"
            }
            return "\(number.intValue)"
        } else if value is NSNull {
            return "null"
        } else if let array = value as? [Any], array.isEmpty {
            return "[]"
        } else if let dict = value as? [String: Any], dict.isEmpty {
            return "{}"
        }
        // Fallback
        return "null"
    }

    /// Escapes a string for JSON output.
    private static func escapeJSONString(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\")
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        escaped = escaped.replacingOccurrences(of: "\n", with: "\\n")
        escaped = escaped.replacingOccurrences(of: "\r", with: "\\r")
        escaped = escaped.replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }

    /// Escapes a key for JSON output (keys typically don't need escaping but handle edge cases).
    private static func escapeJSONKey(_ key: String) -> String {
        var escaped = key
        escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\")
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        return escaped
    }
}
