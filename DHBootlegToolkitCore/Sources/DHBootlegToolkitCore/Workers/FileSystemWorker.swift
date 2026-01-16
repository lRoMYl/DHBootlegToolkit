import Foundation

/// Manages file system operations for a repository.
///
/// FileSystemWorker handles repository validation, feature discovery,
/// and JSON file operations with order preservation.
public actor FileSystemWorker {

    private let configuration: RepositoryConfiguration

    public init(configuration: RepositoryConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Repository Validation

    /// Result of repository validation.
    public struct ValidationResult: Sendable {
        public let isValid: Bool
        public let errorMessage: String?
        public let availablePlatformIds: Set<String>

        public init(isValid: Bool, errorMessage: String?, availablePlatformIds: Set<String>) {
            self.isValid = isValid
            self.errorMessage = errorMessage
            self.availablePlatformIds = availablePlatformIds
        }
    }

    /// Validates that the repository has the expected structure.
    public nonisolated func validateRepository(_ url: URL) -> ValidationResult {
        let fileManager = FileManager.default
        let basePath = url.appendingPathComponent(configuration.basePath)

        // Check if base path exists
        guard fileManager.fileExists(atPath: basePath.path) else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Invalid repository structure.\n\nExpected path not found:\n\(configuration.basePath)\n\nPlease select the root folder of the repository.",
                availablePlatformIds: []
            )
        }

        // Check for configured platforms
        var availablePlatformIds = Set<String>()
        for platform in configuration.platforms {
            let platformPath = basePath.appendingPathComponent(platform.folderName)
            if fileManager.fileExists(atPath: platformPath.path) {
                availablePlatformIds.insert(platform.id)
            }
        }

        if availablePlatformIds.isEmpty {
            let platformNames = configuration.platforms.map { "'\($0.folderName)'" }.joined(separator: " or ")
            return ValidationResult(
                isValid: false,
                errorMessage: "No platform folders found.\n\nExpected \(platformNames) folder in:\n\(configuration.basePath)\n\nPlease select the correct repository.",
                availablePlatformIds: []
            )
        }

        return ValidationResult(
            isValid: true,
            errorMessage: nil,
            availablePlatformIds: availablePlatformIds
        )
    }

    // MARK: - Feature Folder Discovery

    /// Discovers feature folders for a given platform.
    public func discoverFeatures(in repositoryURL: URL, platform: PlatformDefinition) async throws -> [FeatureFolder] {
        let basePath = repositoryURL
            .appendingPathComponent(configuration.basePath)
            .appendingPathComponent(platform.folderName)

        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: basePath.path) else {
            return []
        }

        let contents = try fileManager.contentsOfDirectory(
            at: basePath,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        return contents.compactMap { url -> FeatureFolder? in
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return nil
            }

            // Skip excluded folders
            guard !configuration.excludedFolders.contains(url.lastPathComponent) else {
                return nil
            }

            let primaryFileURL = url.appendingPathComponent(configuration.primaryLanguageFile)
            let assetsFolderURL = url.appendingPathComponent(configuration.assetsFolderName)

            return FeatureFolder(
                name: url.lastPathComponent,
                platform: platform,
                url: url,
                hasPrimaryLanguageFile: fileManager.fileExists(atPath: primaryFileURL.path),
                hasAssetsFolder: fileManager.fileExists(atPath: assetsFolderURL.path),
                configuration: configuration
            )
        }.sorted { $0.name < $1.name }
    }

    // MARK: - Feature File Discovery

    /// Discovers all files and folders within a feature folder.
    ///
    /// Returns a list of `FeatureFileItem` representing the file tree structure.
    /// The primary language file (e.g., en.json) is marked as primary.
    /// Git status is initially set to `.unchanged` - use GitWorker to update statuses.
    public func discoverFilesInFeature(_ feature: FeatureFolder) async throws -> [FeatureFileItem] {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: feature.url.path) else {
            return []
        }

        let contents = try fileManager.contentsOfDirectory(
            at: feature.url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var items: [FeatureFileItem] = []

        for url in contents {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                continue
            }

            let name = url.lastPathComponent

            if isDirectory.boolValue {
                // It's a folder - recursively discover children
                let children = try await discoverFilesInFolder(url)
                let item = FeatureFileItem(
                    id: "\(feature.id)_\(name)",
                    name: name,
                    url: url,
                    type: .folder,
                    children: children,
                    gitStatus: .unchanged
                )
                items.append(item)
            } else {
                // It's a file
                let item = createFileItem(
                    url: url,
                    featureId: feature.id,
                    primaryLanguageFile: feature.primaryLanguageFileName
                )
                items.append(item)
            }
        }

        // Sort: primary JSON first, then folders, then other files
        return items.sorted { item1, item2 in
            let priority1 = sortPriority(for: item1, primaryFile: feature.primaryLanguageFileName)
            let priority2 = sortPriority(for: item2, primaryFile: feature.primaryLanguageFileName)
            if priority1 != priority2 {
                return priority1 < priority2
            }
            return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
        }
    }

    /// Recursively discovers files in a subfolder.
    private func discoverFilesInFolder(_ folderURL: URL) async throws -> [FeatureFileItem] {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: folderURL.path) else {
            return []
        }

        let contents = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var items: [FeatureFileItem] = []
        let folderId = folderURL.lastPathComponent

        for url in contents {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                continue
            }

            let name = url.lastPathComponent

            if isDirectory.boolValue {
                // Nested folder
                let children = try await discoverFilesInFolder(url)
                let item = FeatureFileItem(
                    id: "\(folderId)_\(name)",
                    name: name,
                    url: url,
                    type: .folder,
                    children: children,
                    gitStatus: .unchanged
                )
                items.append(item)
            } else {
                // File in subfolder
                let item = createFileItem(
                    url: url,
                    featureId: folderId,
                    primaryLanguageFile: nil
                )
                items.append(item)
            }
        }

        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Creates a FeatureFileItem for a file based on its extension.
    private func createFileItem(url: URL, featureId: String, primaryLanguageFile: String?) -> FeatureFileItem {
        let name = url.lastPathComponent
        let ext = url.pathExtension.lowercased()

        let fileType: FeatureFileItem.FileItemType
        switch ext {
        case "json":
            let isPrimary = primaryLanguageFile != nil && name == primaryLanguageFile
            fileType = .jsonFile(isPrimary: isPrimary)
        case "png", "jpg", "jpeg", "gif", "webp", "svg":
            fileType = .image
        default:
            fileType = .otherFile(fileExtension: ext)
        }

        return FeatureFileItem(
            id: "\(featureId)_\(name)",
            name: name,
            url: url,
            type: fileType,
            children: [],
            gitStatus: .unchanged
        )
    }

    /// Returns sort priority for file items.
    /// Lower number = higher priority (appears first).
    private func sortPriority(for item: FeatureFileItem, primaryFile: String) -> Int {
        switch item.type {
        case .jsonFile(let isPrimary):
            return isPrimary ? 0 : 2  // Primary JSON first, other JSON after folders
        case .folder:
            return 1  // Folders second
        case .image:
            return 3  // Images after JSON
        case .otherFile:
            return 4  // Other files last
        }
    }

    // MARK: - JSON Operations

    /// Loads translation entities from a JSON file.
    public func loadEntities(from url: URL) async throws -> [TranslationEntity] {
        let data = try Data(contentsOf: url)
        return try await loadEntities(from: data)
    }

    /// Loads translation entities from JSON data.
    public func loadEntities(from data: Data) async throws -> [TranslationEntity] {
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        return jsonObject.compactMap { key, value -> TranslationEntity? in
            guard let dict = value as? [String: Any] else { return nil }
            return TranslationEntity.decode(from: dict, key: key)
        }.sorted { $0.key < $1.key }
    }

    /// Saves translation entities to a JSON file with order preservation.
    public func saveEntities(_ entities: [TranslationEntity], to url: URL) async throws {
        // Get original key order if file exists
        let originalKeyOrder = getOriginalKeyOrder(from: url)
        let originalInnerKeyOrder = getOriginalInnerKeyOrder(from: url)

        // Build key map
        var keyMap: [String: TranslationEntity] = [:]
        for entity in entities {
            keyMap[entity.key] = entity
        }

        // Determine final key order: original keys first (in order), then new keys
        var orderedKeyNames: [String] = []
        for keyName in originalKeyOrder {
            if keyMap[keyName] != nil {
                orderedKeyNames.append(keyName)
            }
        }
        // Add new keys (not in original) at the end
        for entity in entities where !originalKeyOrder.contains(entity.key) {
            orderedKeyNames.append(entity.key)
        }

        // Build JSON string manually to preserve order
        let jsonString = buildOrderedJSON(
            keyNames: orderedKeyNames,
            keyMap: keyMap,
            originalInnerKeyOrder: originalInnerKeyOrder
        )

        try jsonString.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Order-Preserving JSON Helpers

    /// Extracts the order of top-level keys from the original JSON file.
    private func getOriginalKeyOrder(from url: URL) -> [String] {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }

        // Parse key order by finding top-level keys
        var keyOrder: [String] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Match lines like: "KEY_NAME": {
            if trimmed.hasPrefix("\"") && trimmed.contains("\": {") {
                if let endQuote = trimmed.dropFirst().firstIndex(of: "\"") {
                    let keyName = String(trimmed.dropFirst().prefix(upTo: endQuote))
                    keyOrder.append(keyName)
                }
            }
        }

        return keyOrder
    }

    /// Extracts the inner key order for each translation key from the original JSON.
    private func getOriginalInnerKeyOrder(from url: URL) -> [String: [String]] {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return [:]
        }

        var result: [String: [String]] = [:]
        var currentKey: String?
        var currentInnerKeys: [String] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Detect top-level key: "KEY_NAME": {
            if trimmed.hasPrefix("\"") && trimmed.contains("\": {") {
                // Save previous key's inner order
                if let key = currentKey, !currentInnerKeys.isEmpty {
                    result[key] = currentInnerKeys
                }
                // Extract new key name
                if let endQuote = trimmed.dropFirst().firstIndex(of: "\"") {
                    currentKey = String(trimmed.dropFirst().prefix(upTo: endQuote))
                    currentInnerKeys = []
                }
            }
            // Detect inner keys: "translation": or "notes": etc.
            else if currentKey != nil, trimmed.hasPrefix("\"") {
                if let endQuote = trimmed.dropFirst().firstIndex(of: "\"") {
                    let innerKey = String(trimmed.dropFirst().prefix(upTo: endQuote))
                    if !innerKey.isEmpty {
                        currentInnerKeys.append(innerKey)
                    }
                }
            }
            // Detect closing brace (end of translation object)
            else if trimmed == "}," || trimmed == "}" {
                if let key = currentKey, !currentInnerKeys.isEmpty {
                    result[key] = currentInnerKeys
                }
            }
        }

        // Save last key
        if let key = currentKey, !currentInnerKeys.isEmpty {
            result[key] = currentInnerKeys
        }

        return result
    }

    /// Builds a JSON string with keys in the specified order.
    private func buildOrderedJSON(
        keyNames: [String],
        keyMap: [String: TranslationEntity],
        originalInnerKeyOrder: [String: [String]]
    ) -> String {
        var lines: [String] = ["{"]

        for (index, keyName) in keyNames.enumerated() {
            guard let entity = keyMap[keyName] else { continue }

            let isLast = index == keyNames.count - 1
            let innerKeyOrder = originalInnerKeyOrder[keyName] ?? configuration.entitySchema.innerKeyOrder

            let keyBlock = buildEntityJSON(
                keyName: keyName,
                entity: entity,
                innerKeyOrder: innerKeyOrder,
                isLast: isLast
            )
            lines.append(keyBlock)
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }

    /// Builds the JSON block for a single translation entity.
    private func buildEntityJSON(
        keyName: String,
        entity: TranslationEntity,
        innerKeyOrder: [String],
        isLast: Bool
    ) -> String {
        var innerLines: [String] = []

        // Build inner key-value pairs in order
        let allInnerKeys = buildInnerKeySet(entity: entity)

        for innerKey in innerKeyOrder {
            if let value = allInnerKeys[innerKey] {
                innerLines.append("    \"\(innerKey)\": \(value)")
            }
        }

        // Add any keys not in original order (safety net)
        for (innerKey, value) in allInnerKeys where !innerKeyOrder.contains(innerKey) {
            innerLines.append("    \"\(innerKey)\": \(value)")
        }

        let innerContent = innerLines.joined(separator: ",\n")
        let comma = isLast ? "" : ","

        return "  \"\(keyName)\": {\n\(innerContent)\n  }\(comma)"
    }

    /// Returns the inner key-value pairs for an entity as JSON-formatted strings.
    private func buildInnerKeySet(entity: TranslationEntity) -> [String: String] {
        var result: [String: String] = [:]

        result["translation"] = escapeJSONString(entity.translation)
        result["notes"] = escapeJSONString(entity.notes)

        if let charLimit = entity.charLimit {
            result["char_limit"] = "\(charLimit)"
        }

        if let targetLanguages = entity.targetLanguages, !targetLanguages.isEmpty {
            // Format array with newlines for readability
            let escaped = targetLanguages.map { escapeJSONString($0) }
            let arrayContent = escaped.map { "      \($0)" }.joined(separator: ",\n")
            result["target_languages"] = "[\n\(arrayContent)\n    ]"
        }

        return result
    }

    /// Escapes a string for JSON output.
    private func escapeJSONString(_ string: String) -> String {
        let escaped = string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }

    // MARK: - Screenshot Operations

    /// Imports a screenshot to a feature folder.
    public func importScreenshot(from source: URL, to destination: URL) async throws {
        let fileManager = FileManager.default

        // Ensure images folder exists
        let imagesFolder = destination.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: imagesFolder.path) {
            try fileManager.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        }

        // Copy the file
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }

    /// Lists existing screenshots in a feature folder.
    public func listExistingScreenshots(in featureFolder: URL) async throws -> [URL] {
        let imagesFolder = featureFolder.appendingPathComponent(configuration.assetsFolderName)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: imagesFolder.path) else {
            return []
        }

        let contents = try fileManager.contentsOfDirectory(
            at: imagesFolder,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        return contents
            .filter { $0.pathExtension.lowercased() == "png" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return date1 > date2
            }
    }

    // MARK: - File Existence

    /// Checks if a file exists at the given URL.
    public nonisolated func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    /// Creates a directory at the given URL.
    public nonisolated func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    // MARK: - File Hash Operations

    /// Computes a content hash for a file (for change detection).
    ///
    /// Uses a simple hash combining file size and prefix/suffix content hashes.
    /// This is not cryptographically secure but is sufficient for detecting changes.
    public nonisolated func computeFileHash(_ url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return "\(data.count)-\(data.prefix(32).hashValue)-\(data.suffix(32).hashValue)"
    }

    /// Checks if file content has changed since a known hash.
    ///
    /// - Parameters:
    ///   - url: The file URL to check
    ///   - hash: The previously computed hash to compare against
    /// - Returns: `true` if the file has changed, `false` if unchanged or no base hash provided
    public nonisolated func hasFileChanged(at url: URL, since hash: String?) -> Bool {
        guard let hash else { return false }  // No previous hash = no change detection
        let currentHash = computeFileHash(url)
        return currentHash != hash
    }
}
