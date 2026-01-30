import Foundation

// MARK: - S3 Country Configuration

/// Represents a country's S3 feature configuration
public struct S3CountryConfig: Identifiable, Sendable, Equatable {
    /// Unique identifier (country code)
    public let id: String

    /// Two-letter country code (e.g., "sg", "my", "th")
    public let countryCode: String

    /// URL to the config.json file
    public let configURL: URL

    /// Parsed JSON configuration data (stored as Data for Sendable compliance)
    public var configData: Data?

    /// Original file content (for preserving key order during saves)
    public var originalContent: String?

    /// Whether this config has unsaved changes
    public var hasChanges: Bool

    /// Git status of this config file (A/M/D/unchanged)
    public var gitStatus: GitFileStatus

    /// Whether this is a placeholder for a deleted config (not yet loaded from git)
    public var isDeletedPlaceholder: Bool

    /// Set of paths that have been edited in memory (dot-separated, e.g., "features.darkMode")
    /// Used to track which fields were modified for hybrid badge computation
    public var editedPaths: Set<String>

    /// Human-readable country name (from GEID mapping, fallback to hardcoded)
    public var countryName: String {
        if let mapping = GEIDRegistry.activeGEID(forCountryCode: countryCode) {
            return mapping.countryName
        }
        // Fallback to existing hardcoded dictionary
        return Self.countryNames[countryCode.lowercased()] ?? countryCode.uppercased()
    }

    /// The current active GEID for this country
    public var geid: String? {
        GEIDRegistry.activeGEID(forCountryCode: countryCode)?.geid
    }

    /// Brand name (foodora, foodpanda, yemeksepeti)
    public var brandName: String? {
        GEIDRegistry.activeGEID(forCountryCode: countryCode)?.brandName
    }

    /// Flag emoji for the country
    public var flagEmoji: String {
        GEIDRegistry.flagEmoji(forCountryCode: countryCode)
    }

    /// Deprecated GEID information for this country
    public var deprecatedInfo: DeprecatedInfo? {
        let deprecatedMappings = GEIDRegistry.deprecatedGEIDs(forCountryCode: countryCode)
        guard !deprecatedMappings.isEmpty else { return nil }

        return DeprecatedInfo(
            oldGEIDs: deprecatedMappings.map { $0.geid },
            replacementGEID: geid,
            status: deprecatedMappings.first?.status ?? .deprecated,
            notes: deprecatedMappings.first?.notes
        )
    }

    public struct DeprecatedInfo: Sendable, Equatable {
        public let oldGEIDs: [String]
        public let replacementGEID: String?
        public let status: GEIDMapping.GEIDStatus
        public let notes: String?
    }

    // MARK: - Initialization

    public init(
        countryCode: String,
        configURL: URL,
        configData: Data? = nil,
        originalContent: String? = nil,
        hasChanges: Bool = false,
        gitStatus: GitFileStatus = .unchanged,
        isDeletedPlaceholder: Bool = false,
        editedPaths: Set<String> = []
    ) {
        self.id = countryCode.lowercased()
        self.countryCode = countryCode.lowercased()
        self.configURL = configURL
        self.configData = configData
        self.originalContent = originalContent
        self.hasChanges = hasChanges
        self.gitStatus = gitStatus
        self.isDeletedPlaceholder = isDeletedPlaceholder
        self.editedPaths = editedPaths
    }

    // MARK: - Country Names Mapping

    private static let countryNames: [String: String] = [
        "sg": "Singapore",
        "my": "Malaysia",
        "th": "Thailand",
        "ph": "Philippines",
        "tw": "Taiwan",
        "hk": "Hong Kong",
        "pk": "Pakistan",
        "bd": "Bangladesh",
        "mm": "Myanmar",
        "kh": "Cambodia",
        "la": "Laos",
        "jp": "Japan",
        "kr": "South Korea",
        "vn": "Vietnam",
        "id": "Indonesia",
        "in": "India",
    ]

    // MARK: - Equatable

    public static func == (lhs: S3CountryConfig, rhs: S3CountryConfig) -> Bool {
        lhs.id == rhs.id &&
        lhs.countryCode == rhs.countryCode &&
        lhs.configURL == rhs.configURL &&
        lhs.configData == rhs.configData &&
        lhs.originalContent == rhs.originalContent &&
        lhs.hasChanges == rhs.hasChanges &&
        lhs.gitStatus == rhs.gitStatus &&
        lhs.isDeletedPlaceholder == rhs.isDeletedPlaceholder &&
        lhs.editedPaths == rhs.editedPaths
    }
}

// MARK: - JSON Helpers

extension S3CountryConfig {
    /// Parses the config data as a JSON dictionary
    public func parseConfigJSON() -> [String: Any]? {
        guard let data = configData else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    /// Updates a single value at the given path using targeted replacement.
    /// This ensures minimal git diffs by only changing the specific value.
    /// Falls back to full JSON rebuild if targeted replacement fails.
    /// - Parameters:
    ///   - value: The new value to set
    ///   - path: The path to the value (e.g., ["features", "darkMode", "enabled"])
    /// - Returns: A new config with the updated value, or nil if update fails
    public func withUpdatedValue(_ value: Any, at path: [String]) -> S3CountryConfig? {
        guard let original = originalContent else {
            // No original content, fall back to full JSON rebuild
            #if DEBUG
            print("[S3CountryConfig] WARNING: No originalContent, using full JSON rebuild for path: \(path)")
            #endif
            guard var json = parseConfigJSON() else { return nil }
            setValueInJSON(&json, at: path, value: value)
            return withUpdatedJSON(json)
        }

        // Try targeted replacement first
        if let updatedContent = S3JSONSerializer.replaceValue(in: original, at: path, with: value) {
            guard let data = updatedContent.data(using: .utf8) else {
                #if DEBUG
                print("[S3CountryConfig] ERROR: Failed to encode updated content as UTF8")
                #endif
                return nil
            }

            #if DEBUG
            print("[S3CountryConfig] SUCCESS: Targeted replacement for path: \(path)")
            #endif
            var updated = self
            updated.configData = data
            updated.originalContent = updatedContent
            updated.hasChanges = true

            // Track this path as edited
            let pathString = path.joined(separator: ".")
            updated.editedPaths.insert(pathString)

            return updated
        }

        // Fall back to full JSON rebuild if targeted replacement fails
        #if DEBUG
        print("[S3CountryConfig] WARNING: Targeted replacement failed for path: \(path), using full JSON rebuild")
        #endif
        guard var json = parseConfigJSON() else { return nil }
        setValueInJSON(&json, at: path, value: value)

        // Track path before calling withUpdatedJSON
        if var updated = withUpdatedJSON(json) {
            let pathString = path.joined(separator: ".")
            updated.editedPaths.insert(pathString)
            return updated
        }
        return nil
    }

    /// Deletes a field at the given path using targeted deletion.
    public func withDeletedField(at path: [String]) -> S3CountryConfig? {
        guard !path.isEmpty else { return nil }

        // Try targeted deletion if original content exists
        if let original = originalContent {
            if let updatedContent = S3JSONSerializer.deleteValue(in: original, at: path) {
                guard let data = updatedContent.data(using: .utf8) else { return nil }

                var updated = self
                updated.configData = data
                updated.originalContent = updatedContent
                updated.hasChanges = true
                updated.editedPaths.insert(path.joined(separator: "."))
                return updated
            }
        }

        // Fallback to full JSON rebuild
        guard var json = parseConfigJSON() else { return nil }
        deleteValueInJSON(&json, at: path)

        if var updated = withUpdatedJSON(json) {
            updated.editedPaths.insert(path.joined(separator: "."))
            return updated
        }

        return nil
    }

    /// Recursively deletes a value at the given path in a JSON dictionary
    private func deleteValueInJSON(_ json: inout [String: Any], at path: [String]) {
        guard !path.isEmpty else { return }

        if path.count == 1 {
            json.removeValue(forKey: path[0])
            return
        }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        if var nested = json[key] as? [String: Any] {
            deleteValueInJSON(&nested, at: remainingPath)
            json[key] = nested
        }
    }

    /// Helper to set a value in a nested JSON dictionary at the given path
    private func setValueInJSON(_ json: inout [String: Any], at path: [String], value: Any) {
        guard !path.isEmpty else { return }

        if path.count == 1 {
            json[path[0]] = value
            return
        }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        if var nested = json[key] as? [String: Any] {
            setValueInJSON(&nested, at: remainingPath, value: value)
            json[key] = nested
        } else if var nestedArray = json[key] as? [Any] {
            // Strip brackets from array index
            let stripped = remainingPath[0]
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")

            if let index = Int(stripped), index < nestedArray.count {
                if remainingPath.count == 1 {
                    nestedArray[index] = value
                } else if var nestedDict = nestedArray[index] as? [String: Any] {
                    setValueInJSON(&nestedDict, at: Array(remainingPath.dropFirst()), value: value)
                    nestedArray[index] = nestedDict
                }
                json[key] = nestedArray
            }
        } else {
            // Parent path doesn't exist - create it (handles deleted fields in sparse JSON)
            #if DEBUG
            print("[setValueInJSON] Creating missing parent path: \(key)")
            #endif
            var newNested: [String: Any] = [:]
            setValueInJSON(&newNested, at: remainingPath, value: value)
            json[key] = newNested
        }
    }

    /// Creates a new config with updated JSON data, preserving original key order
    /// NOTE: This rebuilds the entire JSON file. For single value changes, use withUpdatedValue instead.
    public func withUpdatedJSON(_ json: [String: Any]) -> S3CountryConfig? {
        #if DEBUG
        print("[S3CountryConfig] withUpdatedJSON called - FULL JSON REBUILD (this modifies the entire file)")
        #endif

        let jsonString: String

        if let original = originalContent {
            // Preserve key order from original content
            jsonString = S3JSONSerializer.serialize(json, preservingOrderFrom: original)
        } else {
            // Fallback for new files - use standard serialization
            guard let data = try? JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys]
            ) else {
                return nil
            }
            jsonString = String(data: data, encoding: .utf8) ?? ""
        }

        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        var updated = self
        updated.configData = data
        // Update originalContent to match new JSON so future targeted replacements work
        updated.originalContent = jsonString
        updated.hasChanges = true
        return updated
    }

    /// Constructs a sparse JSON containing only edited paths and their required parent structure.
    /// Used when saving deleted files with partial edits to avoid restoring unedited fields.
    /// - Parameters:
    ///   - editedPaths: Set of dot-separated paths that were edited (e.g., "data.subscription.enabled")
    /// - Returns: A new config with sparse JSON data, or nil if construction fails
    public func withSparseJSON(editedPaths: Set<String>) -> S3CountryConfig? {
        guard let fullJSON = parseConfigJSON() else { return nil }

        // Construct sparse JSON with only edited paths
        var sparseJSON: [String: Any] = [:]

        for editedPath in editedPaths {
            let pathComponents = editedPath.split(separator: ".").map(String.init)
            insertValueAtPath(into: &sparseJSON, from: fullJSON, path: pathComponents)
        }

        // Serialize sparse JSON
        guard let data = try? JSONSerialization.data(
            withJSONObject: sparseJSON,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return nil
        }

        let jsonString = String(data: data, encoding: .utf8) ?? ""

        var updated = self
        updated.configData = data
        updated.originalContent = jsonString
        return updated
    }

    /// Helper to insert a value from source JSON into destination JSON at the given path
    private func insertValueAtPath(
        into dest: inout [String: Any],
        from source: [String: Any],
        path: [String]
    ) {
        guard !path.isEmpty else { return }

        if path.count == 1 {
            // Leaf node - copy value from source
            dest[path[0]] = source[path[0]]
            return
        }

        // Parent node - ensure parent exists and recurse
        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        if var nested = dest[key] as? [String: Any] {
            // Parent already exists, recurse into it
            if let sourceNested = source[key] as? [String: Any] {
                insertValueAtPath(into: &nested, from: sourceNested, path: remainingPath)
                dest[key] = nested
            }
        } else {
            // Parent doesn't exist, create it
            if let sourceNested = source[key] as? [String: Any] {
                var newNested: [String: Any] = [:]
                insertValueAtPath(into: &newNested, from: sourceNested, path: remainingPath)
                dest[key] = newNested
            } else if let sourceArray = source[key] as? [Any] {
                // Handle array elements (e.g., "items.[0]" or "items.[0].name")
                // Strip brackets from array index
                let stripped = remainingPath[0]
                    .replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")

                if let index = Int(stripped), index < sourceArray.count {
                    if remainingPath.count == 1 {
                        // Direct array element - copy entire element
                        // For sparse arrays, we need to include all elements up to the edited index
                        // Use original values from source array to maintain type consistency
                        if var existingArray = dest[key] as? [Any] {
                            // Ensure array is large enough
                            while existingArray.count <= index {
                                existingArray.append(sourceArray[existingArray.count])
                            }
                            existingArray[index] = sourceArray[index]
                            dest[key] = existingArray
                        } else {
                            // First element - create array from source up to edited index
                            var newArray: [Any] = []
                            for i in 0...index {
                                newArray.append(sourceArray[i])
                            }
                            dest[key] = newArray
                        }
                    } else if let sourceElement = sourceArray[index] as? [String: Any] {
                        // Nested path within array element object
                        // Recursively copy only the needed nested values
                        var sparseElement: [String: Any] = [:]
                        insertValueAtPath(
                            into: &sparseElement,
                            from: sourceElement,
                            path: Array(remainingPath.dropFirst())
                        )

                        // Check if dest already has an array at this key
                        if var existingArray = dest[key] as? [[String: Any]] {
                            // Ensure array is large enough
                            while existingArray.count <= index {
                                existingArray.append([:])
                            }
                            // Merge with existing element if present
                            if !existingArray[index].isEmpty {
                                existingArray[index].merge(sparseElement) { _, new in new }
                            } else {
                                existingArray[index] = sparseElement
                            }
                            dest[key] = existingArray
                        } else {
                            // First element - create sparse array with correct index
                            var newArray: [[String: Any]] = []
                            for _ in 0..<index {
                                newArray.append([:])
                            }
                            newArray.append(sparseElement)
                            dest[key] = newArray
                        }
                    }
                }
            }
        }
    }
}
