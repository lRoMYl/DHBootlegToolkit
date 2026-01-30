import SwiftUI
import DHBootlegToolkitCore
import JSONEditorCore

// MARK: - S3 Store

/// Observable state management for S3 feature configuration editor
@Observable
@MainActor
final class S3Store {
    // MARK: - Repository State

    /// URL to the S3 repository root
    var s3RepositoryURL: URL?

    /// Path within repository to feature-config folder (relative to repo root)
    var featureConfigPath: String = "static.fd-api.com/s3root/feature-config"

    /// Whether the repository is currently loading
    var isLoading: Bool = false

    /// Error message if loading failed
    var errorMessage: String?

    // MARK: - Environment State

    /// Currently selected environment (staging/production)
    var selectedEnvironment: S3Environment = .staging

    // MARK: - Countries State

    /// List of country configurations for the current environment
    var countries: [S3CountryConfig] = []

    /// Search text for filtering countries
    var searchText: String = ""

    /// Filtered countries based on search text
    var filteredCountries: [S3CountryConfig] {
        guard !searchText.isEmpty else { return countries }
        let query = searchText.lowercased()

        return countries.filter { country in
            // Search by country code
            country.countryCode.localizedCaseInsensitiveContains(query) ||
            // Search by country name
            country.countryName.localizedCaseInsensitiveContains(query) ||
            // Search by GEID
            (country.geid?.localizedCaseInsensitiveContains(query) ?? false) ||
            // Search by brand name
            (country.brandName?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    /// Grouped countries by brand (optimized single-pass algorithm)
    var groupedCountries: [BrandGroup] {
        let filtered = filteredCountries

        // Single pass: group countries by brand in one iteration
        var foodpandaCountries: [S3CountryConfig] = []
        var foodoraCountries: [S3CountryConfig] = []
        var yemeksepetiCountries: [S3CountryConfig] = []
        var legacyCountries: [S3CountryConfig] = []

        for country in filtered {
            switch country.brandName {
            case "foodpanda":
                foodpandaCountries.append(country)
            case "foodora":
                foodoraCountries.append(country)
            case "yemeksepeti":
                yemeksepetiCountries.append(country)
            case nil:
                legacyCountries.append(country)
            default:
                // Unknown brand - add to legacy
                legacyCountries.append(country)
            }
        }

        // Build groups only for non-empty brands
        var groups: [BrandGroup] = []

        if !foodpandaCountries.isEmpty {
            groups.append(BrandGroup(name: "foodpanda", countries: foodpandaCountries))
        }

        if !foodoraCountries.isEmpty {
            groups.append(BrandGroup(name: "foodora", countries: foodoraCountries))
        }

        if !yemeksepetiCountries.isEmpty {
            groups.append(BrandGroup(name: "yemeksepeti", countries: yemeksepetiCountries))
        }

        if !legacyCountries.isEmpty {
            groups.append(BrandGroup(name: "Legacy", countries: legacyCountries))
        }

        return groups
    }

    /// Represents a brand group with its countries
    struct BrandGroup: Identifiable {
        let id = UUID()
        let name: String
        let countries: [S3CountryConfig]
    }

    /// Currently selected country for editing
    var selectedCountry: S3CountryConfig?

    /// Countries that have been modified
    var modifiedCountryIds: Set<String> = []

    // MARK: - Schema State

    /// JSON schema data for validation (if available)
    var schemaData: Data?

    /// Parsed JSON Schema
    var parsedSchema: JSONSchema?

    /// Validation results keyed by country code
    var validationResults: [String: JSONSchemaValidationResult] = [:]

    // MARK: - Git Integration

    /// Git worker for repository operations (git restore for discard)
    var gitWorker: GitWorker?

    /// Configuration for git operations
    private let gitConfiguration: RepositoryConfiguration = S3RepositoryConfiguration()

    /// Overall git status for the S3 repository
    var gitStatus: GitStatus = .unconfigured

    /// Available branches for branch switching
    var availableBranches: [String] = []

    /// Whether branches are currently loading
    var isLoadingBranches: Bool = false

    /// Display-friendly current branch name
    var currentBranchDisplayName: String {
        gitStatus.currentBranch ?? "No branch"
    }

    /// Whether currently on a protected branch (main/master)
    var isOnProtectedBranch: Bool {
        gitStatus.isOnProtectedBranch
    }

    /// Checks if a specific branch name is protected
    func isProtectedBranch(_ branchName: String) -> Bool {
        gitConfiguration.isProtectedBranch(branchName)
    }

    // Branch switch confirmation state (required by GitPublishable)
    var pendingBranchSwitch: String?
    var pendingBranchSwitchError: String?
    var showUncommittedChangesConfirmation = false

    // Create branch prompt state (for protected branch banner)
    var showCreateBranchPrompt = false

    // PR creation state (required by GitPublishable)
    var showPublishError = false
    var publishErrorMessage: String?

    // Save error state
    var showSaveError = false
    var saveErrorMessage: String?

    // Repository-wide discard confirmation
    var showDiscardRepositoryConfirmation = false

    // MARK: - Git Status Operations

    /// Refreshes the overall git status for the S3 repository
    /// Performs the actual branch switch (required by GitPublishable protocol)
    /// - Returns: Error message if switch failed, nil on success
    func performBranchSwitch(_ branchName: String) async -> String? {
        guard let gitWorker else { return "Git not configured" }

        do {
            try await gitWorker.switchToBranch(branchName)
            await refreshGitStatus()
            await loadBranches()
            await loadCountries()
            await updateGitStatuses()
            return nil
        } catch {
            await refreshGitStatus()
            return userFriendlyGitError(error)
        }
    }

    /// Updates git status for all loaded countries based on actual git state
    func updateGitStatuses() async {
        guard let gitWorker,
              let repoURL = s3RepositoryURL,
              let envURL = currentEnvironmentURL else {
            return
        }

        // Get relative path from repo root to environment folder
        let envRelativePath = envURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")

        do {
            let statuses = try await gitWorker.getFileStatuses(inDirectory: envRelativePath)

            // Map file paths to country IDs and update gitStatus
            for index in countries.indices {
                let country = countries[index]

                // Skip deleted placeholders - already marked correctly
                if country.isDeletedPlaceholder {
                    continue
                }

                // Config file path pattern: envRelativePath/countryCode/config.json
                let configPath = "\(envRelativePath)/\(country.countryCode)/config.json"

                let gitStatus = statuses[configPath] ?? .unchanged
                if countries[index].gitStatus != gitStatus {
                    countries[index].gitStatus = gitStatus
                }
            }

            // Update selected country if its status changed
            if let selected = selectedCountry,
               let updatedCountry = countries.first(where: { $0.id == selected.id }) {
                selectedCountry = updatedCountry
            }
        } catch {
            // Git status errors are non-fatal - just keep existing status
            #if DEBUG
            print("[S3Store] Failed to update git statuses: \(error)")
            #endif
        }
    }

    // MARK: - Git HEAD Content

    /// Fetches the git HEAD version of a country's config JSON for diff comparison
    /// - Parameter country: The country config to fetch HEAD content for
    /// - Returns: The parsed JSON dictionary from git HEAD, or nil if file is new/not in git
    func fetchHeadJSON(for country: S3CountryConfig) async -> [String: Any]? {
        guard let gitWorker = gitWorker,
              let relativePath = getRelativePath(for: country.configURL) else {
            return nil
        }

        guard let data = await gitWorker.getHeadFileContent(relativePath: relativePath) else {
            return nil  // File doesn't exist in git HEAD (new file)
        }

        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    /// Loads a deleted country's config from git HEAD.
    /// Called when user selects a deleted country placeholder.
    func loadDeletedCountryContent(countryCode: String) async -> S3CountryConfig? {
        guard let gitWorker = gitWorker,
              let repoURL = s3RepositoryURL,
              let envURL = currentEnvironmentURL else {
            return nil
        }

        // Build relative path: envRelativePath/countryCode/config.json
        let envRelativePath = envURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")
        let relativePath = "\(envRelativePath)/\(countryCode.lowercased())/config.json"

        // Fetch content from git HEAD
        guard let data = await gitWorker.getHeadFileContent(relativePath: relativePath) else {
            return nil  // File doesn't exist in git HEAD
        }

        // Verify it's valid JSON
        guard let _ = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let configFileURL = envURL
            .appendingPathComponent(countryCode.lowercased())
            .appendingPathComponent("config.json")

        let originalContent = String(data: data, encoding: .utf8)

        return S3CountryConfig(
            countryCode: countryCode.lowercased(),
            configURL: configFileURL,
            configData: data,
            originalContent: originalContent,
            hasChanges: false,
            gitStatus: .deleted,
            isDeletedPlaceholder: false  // Now loaded
        )
    }

    // MARK: - Field Selection State (for Batch Update)

    /// Currently selected node path in the JSON tree (dot-separated, e.g., "subscription.plans.premium")
    var selectedNodePath: String?

    /// Currently selected node value
    var selectedNodeValue: Any?

    /// Whether the currently selected node is deleted
    var selectedNodeIsDeleted: Bool = false

    /// Number of keys for the currently selected node (only set for objects)
    var selectedNodeKeyCount: Int?

    /// Whether to show the apply field sheet
    var showApplyFieldSheet: Bool = false

    /// Whether to show the inspect field sheet
    var showInspectFieldSheet: Bool = false

    /// Error message when node selection is invalid (e.g., root-level fields)
    var selectionError: String? = nil

    // MARK: - Computed Properties

    /// Whether a repository is loaded
    var hasRepository: Bool {
        s3RepositoryURL != nil
    }

    /// Full path to the feature config directory
    var featureConfigURL: URL? {
        guard let repoURL = s3RepositoryURL else { return nil }
        return repoURL.appendingPathComponent(featureConfigPath)
    }

    /// Full path to the current environment's config directory
    var currentEnvironmentURL: URL? {
        featureConfigURL?.appendingPathComponent(selectedEnvironment.folderName)
    }

    /// Countries with unsaved changes
    var countriesWithChanges: [S3CountryConfig] {
        countries.filter { $0.hasChanges }
    }

    /// Whether any country has unsaved changes
    var hasUnsavedChanges: Bool {
        !modifiedCountryIds.isEmpty
    }

    /// Countries that have uncommitted changes according to git status (for PR creation)
    var uncommittedCountries: [S3CountryConfig] {
        countries.filter { $0.gitStatus != .unchanged }
    }

    // MARK: - Repository Operations

    /// Loads an S3 repository from the given URL
    /// Automatically detects the feature-config folder location
    func loadRepository(at url: URL) async {
        await AppLogger.shared.timedGroup("S3 Config Editor TTI: \(url.lastPathComponent)") { ctx in
            isLoading = true
            defer { isLoading = false }

            errorMessage = nil

            let fileManager = FileManager.default

            // Try to find the feature-config folder
            let configURL = await ctx.time("Find feature-config folder") {
                findFeatureConfigFolder(from: url, fileManager: fileManager)
            }

            guard let configURL else {
                errorMessage = "Could not find feature-config folder. Expected structure with staging/ and production/ subfolders."
                s3RepositoryURL = url
                return
            }

            // Set the repository URL and update the relative path
            s3RepositoryURL = url
            featureConfigPath = configURL.path.replacingOccurrences(of: url.path + "/", with: "")

            // If the selected folder IS the feature-config folder, clear the path
            if configURL.path == url.path {
                featureConfigPath = ""
            }

            // Initialize git worker for discard operations
            await ctx.time("Initialize git worker") {
                gitWorker = GitWorker(repositoryURL: url, configuration: gitConfiguration)
            }

            // Load schema if available
            await ctx.time("Load schema") {
                let schemaURL = configURL.appendingPathComponent("_schema")
                if fileManager.fileExists(atPath: schemaURL.path) {
                    let schemaFileURL = schemaURL.appendingPathComponent("config.json")
                    if fileManager.fileExists(atPath: schemaFileURL.path) {
                        if let data = try? Data(contentsOf: schemaFileURL) {
                            schemaData = data
                            // Parse schema
                            let parser = JSONSchemaParser()
                            do {
                                parsedSchema = try parser.parse(data: data)
                                AppLogger.shared.info("Schema loaded successfully: Draft-07")
                            } catch {
                                AppLogger.shared.error("Failed to parse schema: \(error.localizedDescription)")
                                parsedSchema = nil
                            }
                        }
                    }
                }
            }

            // Load countries for the current environment
            await ctx.time("Load countries") {
                await loadCountries()
            }

            // Update git status for loaded countries and overall repository
            await ctx.time("Update git statuses") {
                await updateGitStatuses()
            }
            await ctx.time("Refresh git status") {
                await refreshGitStatus()
            }
            await ctx.time("Load branches") {
                await loadBranches()
            }
        }
    }

    /// Searches for the feature-config folder from the given URL
    /// Returns the URL if found, nil otherwise
    private func findFeatureConfigFolder(from url: URL, fileManager: FileManager) -> URL? {
        // Check if the selected folder IS the feature-config folder
        // (contains staging/ or production/ subfolders)
        if isFeatureConfigFolder(url, fileManager: fileManager) {
            return url
        }

        // Common paths to search for feature-config
        let searchPaths = [
            "feature-config",
            "s3root/feature-config",
            "static.fd-api.com/s3root/feature-config",
        ]

        for relativePath in searchPaths {
            let candidateURL = url.appendingPathComponent(relativePath)
            if isFeatureConfigFolder(candidateURL, fileManager: fileManager) {
                return candidateURL
            }
        }

        // Try to find any folder named "feature-config" up to 3 levels deep
        if let found = searchForFeatureConfig(in: url, depth: 0, maxDepth: 3, fileManager: fileManager) {
            return found
        }

        return nil
    }

    /// Checks if a folder is a valid feature-config folder
    /// (contains staging/ and/or production/ subfolders)
    private func isFeatureConfigFolder(_ url: URL, fileManager: FileManager) -> Bool {
        let stagingURL = url.appendingPathComponent("staging")
        let productionURL = url.appendingPathComponent("production")

        let hasStagingDir = fileManager.fileExists(atPath: stagingURL.path)
        let hasProductionDir = fileManager.fileExists(atPath: productionURL.path)

        // Must have at least one environment folder
        return hasStagingDir || hasProductionDir
    }

    /// Recursively searches for a folder named "feature-config"
    private func searchForFeatureConfig(in url: URL, depth: Int, maxDepth: Int, fileManager: FileManager) -> URL? {
        guard depth < maxDepth else { return nil }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for item in contents {
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }

                // Check if this folder is named "feature-config" and is valid
                if item.lastPathComponent == "feature-config" && isFeatureConfigFolder(item, fileManager: fileManager) {
                    return item
                }

                // Recurse into subdirectories
                if let found = searchForFeatureConfig(in: item, depth: depth + 1, maxDepth: maxDepth, fileManager: fileManager) {
                    return found
                }
            }
        } catch {
            // Ignore errors and continue
        }

        return nil
    }

    /// Loads countries for the current environment
    func loadCountries() async {
        guard let envURL = currentEnvironmentURL else {
            countries = []
            return
        }

        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: envURL.path) else {
            errorMessage = "Environment folder not found: \(selectedEnvironment.displayName)"
            countries = []
            return
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: envURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            var loadedCountries: [S3CountryConfig] = []

            for folderURL in contents {
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }

                let countryCode = folderURL.lastPathComponent
                let configFileURL = folderURL.appendingPathComponent("config.json")

                guard fileManager.fileExists(atPath: configFileURL.path) else {
                    continue
                }

                // Load the config data and original content
                let configData = try? Data(contentsOf: configFileURL)
                let originalContent = try? String(contentsOf: configFileURL, encoding: .utf8)

                let config = S3CountryConfig(
                    countryCode: countryCode,
                    configURL: configFileURL,
                    configData: configData,
                    originalContent: originalContent,
                    hasChanges: modifiedCountryIds.contains(countryCode.lowercased()),
                    gitStatus: .unchanged,
                    isDeletedPlaceholder: false,
                    editedPaths: []
                )

                loadedCountries.append(config)
            }

            // PART 2: Discover deleted countries from git
            if let gitWorker = gitWorker,
               let repoURL = s3RepositoryURL {

                let envRelativePath = envURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")

                do {
                    // Get all deleted files in this environment directory
                    let deletedPaths = try await gitWorker.getDeletedFiles(inDirectory: envRelativePath)

                    // Filter for config.json files and extract country codes
                    for deletedPath in deletedPaths {
                        guard deletedPath.hasSuffix("/config.json") else { continue }

                        // Extract country code (parent directory of config.json)
                        let pathComponents = deletedPath.split(separator: "/")
                        guard pathComponents.count >= 2,
                              pathComponents.last == "config.json" else {
                            continue
                        }

                        let countryCode = String(pathComponents[pathComponents.count - 2])

                        // Skip if country already exists on disk
                        if loadedCountries.contains(where: { $0.countryCode == countryCode.lowercased() }) {
                            continue
                        }

                        // Create placeholder for deleted country
                        let configFileURL = envURL
                            .appendingPathComponent(countryCode.lowercased())
                            .appendingPathComponent("config.json")

                        let placeholderConfig = S3CountryConfig(
                            countryCode: countryCode.lowercased(),
                            configURL: configFileURL,
                            configData: nil,  // Not loaded yet
                            originalContent: nil,
                            hasChanges: false,
                            gitStatus: .deleted,
                            isDeletedPlaceholder: true,
                            editedPaths: []
                        )

                        loadedCountries.append(placeholderConfig)
                    }
                } catch {
                    // Git errors are non-fatal
                    #if DEBUG
                    print("[S3Store] Failed to load deleted countries: \(error)")
                    #endif
                }
            }

            // Sort by country code
            countries = loadedCountries.sorted { $0.countryCode < $1.countryCode }

            // Update selected country if it's still valid
            if let selected = selectedCountry,
               !countries.contains(where: { $0.id == selected.id }) {
                selectedCountry = nil
            }

        } catch {
            errorMessage = "Failed to load countries: \(error.localizedDescription)"
            countries = []
        }
    }

    /// Selects a country for editing
    func selectCountry(_ country: S3CountryConfig) async {
        // If deleted placeholder, load content from git HEAD
        if country.isDeletedPlaceholder {
            guard let loadedCountry = await loadDeletedCountryContent(countryCode: country.countryCode) else {
                errorMessage = "Could not load deleted config for \(country.countryCode.uppercased()) from git"
                selectedCountry = country
                clearNodeSelection()
                return
            }

            // Replace placeholder with loaded version
            if let index = countries.firstIndex(where: { $0.id == country.id }) {
                countries[index] = loadedCountry
            }

            selectedCountry = loadedCountry
        } else {
            selectedCountry = country
        }

        clearNodeSelection()
    }

    /// Switches to a different environment
    func switchEnvironment(to environment: S3Environment) async {
        guard environment != selectedEnvironment else { return }
        selectedEnvironment = environment
        selectedCountry = nil
        await loadCountries()
        await updateGitStatuses()
    }

    // MARK: - Edit Operations

    /// Updates a value at a specific path in the selected country's config
    func updateValue(at path: [String], value: Any) {
        guard let country = selectedCountry else {
            return
        }

        // Use targeted replacement for minimal git diffs
        if let updated = country.withUpdatedValue(value, at: path) {
            selectedCountry = updated
            modifiedCountryIds.insert(updated.id)

            // Update in the countries array
            if let index = countries.firstIndex(where: { $0.id == updated.id }) {
                countries[index] = updated
            }
        }
    }

    /// Sets a value in a nested JSON dictionary at the given path
    private func setValueInJSON(_ json: inout [String: Any], at path: [String], value: Any) -> Bool {
        guard !path.isEmpty else { return false }

        if path.count == 1 {
            json[path[0]] = value
            return true
        }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        if var nested = json[key] as? [String: Any] {
            if setValueInJSON(&nested, at: remainingPath, value: value) {
                json[key] = nested
                return true
            }
        }

        return false
    }

    /// Gets a value from a nested JSON dictionary at the given path
    /// Supports both dictionary keys and array indices
    func getValue(at path: [String], from json: [String: Any]) -> Any? {
        guard !path.isEmpty else { return json }

        var current: Any = json

        for component in path {
            if let dict = current as? [String: Any] {
                guard let next = dict[component] else { return nil }
                current = next
            } else if let array = current as? [Any] {
                // Strip brackets to handle both "[0]" and "0" formats
                let stripped = component.replacingOccurrences(of: "[", with: "")
                                        .replacingOccurrences(of: "]", with: "")
                guard let index = Int(stripped), index < array.count else { return nil }
                current = array[index]
            } else {
                return nil
            }
        }

        return current
    }

    /// Adds a new field at the specified path
    /// - Parameters:
    ///   - parentPath: Path to the parent object where the field will be added
    ///   - key: The key name for the new field
    ///   - value: The value for the new field
    func addField(at parentPath: [String], key: String, value: Any) {
        guard let country = selectedCountry,
              var json = country.parseConfigJSON() else {
            return
        }

        // Navigate to parent and add the new key
        if parentPath.isEmpty {
            // Adding to root
            json[key] = value
        } else if addFieldInJSON(&json, at: parentPath, key: key, value: value) {
            // Successfully added nested field
        } else {
            return
        }

        if let updated = country.withUpdatedJSON(json) {
            var mutableUpdated = updated
            let newFieldPath = (parentPath + [key]).joined(separator: ".")
            mutableUpdated.editedPaths.insert(newFieldPath)

            selectedCountry = mutableUpdated
            modifiedCountryIds.insert(mutableUpdated.id)

            if let index = countries.firstIndex(where: { $0.id == mutableUpdated.id }) {
                countries[index] = mutableUpdated
            }
        }
    }

    /// Helper to add a field in a nested JSON structure
    private func addFieldInJSON(_ json: inout [String: Any], at path: [String], key: String, value: Any) -> Bool {
        guard !path.isEmpty else { return false }

        if path.count == 1 {
            if var parent = json[path[0]] as? [String: Any] {
                parent[key] = value
                json[path[0]] = parent
                return true
            }
            return false
        }

        let currentKey = path[0]
        let remainingPath = Array(path.dropFirst())

        if var nested = json[currentKey] as? [String: Any] {
            if addFieldInJSON(&nested, at: remainingPath, key: key, value: value) {
                json[currentKey] = nested
                return true
            }
        }

        return false
    }

    /// Deletes a field at the specified path
    /// - Parameter path: Full path to the field to delete (last component is the key to remove)
    func deleteField(at path: [String]) {
        guard !path.isEmpty,
              let country = selectedCountry,
              var json = country.parseConfigJSON() else {
            return
        }

        if path.count == 1 {
            // Deleting from root
            json.removeValue(forKey: path[0])
        } else if !deleteFieldInJSON(&json, at: path) {
            return
        }

        if let updated = country.withUpdatedJSON(json) {
            var mutableUpdated = updated
            let deletedPath = path.joined(separator: ".")
            mutableUpdated.editedPaths.insert(deletedPath)

            selectedCountry = mutableUpdated
            modifiedCountryIds.insert(mutableUpdated.id)

            if let index = countries.firstIndex(where: { $0.id == mutableUpdated.id }) {
                countries[index] = mutableUpdated
            }
        }
    }

    /// Helper to delete a field from a nested JSON structure
    private func deleteFieldInJSON(_ json: inout [String: Any], at path: [String]) -> Bool {
        guard path.count >= 2 else { return false }

        if path.count == 2 {
            // Parent is at path[0], key to delete is path[1]
            if var parent = json[path[0]] as? [String: Any] {
                parent.removeValue(forKey: path[1])
                json[path[0]] = parent
                return true
            }
            return false
        }

        let currentKey = path[0]
        let remainingPath = Array(path.dropFirst())

        if var nested = json[currentKey] as? [String: Any] {
            if deleteFieldInJSON(&nested, at: remainingPath) {
                json[currentKey] = nested
                return true
            }
        }

        return false
    }

    // MARK: - Array Element Operations

    /// Deletes an element from an array at the specified path
    /// - Parameter path: Full path where last component is the array index (as string)
    func deleteArrayElement(at path: [String]) {
        guard path.count >= 2,
              let country = selectedCountry,
              var json = country.parseConfigJSON(),
              let indexString = path.last else {
            return
        }

        // Strip brackets to handle both "[0]" and "0" formats
        let stripped = indexString.replacingOccurrences(of: "[", with: "")
                                  .replacingOccurrences(of: "]", with: "")
        guard let index = Int(stripped) else {
            return
        }

        let arrayPath = Array(path.dropLast())

        if !deleteArrayElementInJSON(&json, arrayPath: arrayPath, index: index) {
            return
        }

        if let updated = country.withUpdatedJSON(json) {
            selectedCountry = updated
            modifiedCountryIds.insert(updated.id)

            if let idx = countries.firstIndex(where: { $0.id == updated.id }) {
                countries[idx] = updated
            }
        }
    }

    /// Helper to delete an element from an array in nested JSON
    private func deleteArrayElementInJSON(
        _ json: inout [String: Any],
        arrayPath: [String],
        index: Int
    ) -> Bool {
        guard !arrayPath.isEmpty else { return false }

        if arrayPath.count == 1 {
            // Array is at root level
            if var array = json[arrayPath[0]] as? [Any], index < array.count {
                array.remove(at: index)
                json[arrayPath[0]] = array
                return true
            }
            return false
        }

        // Navigate to the nested array
        let currentKey = arrayPath[0]
        let remainingPath = Array(arrayPath.dropFirst())

        if var nested = json[currentKey] as? [String: Any] {
            if deleteArrayElementInJSON(&nested, arrayPath: remainingPath, index: index) {
                json[currentKey] = nested
                return true
            }
        } else if var nestedArray = json[currentKey] as? [Any],
                  let nestedIndex = Int(remainingPath[0]),
                  nestedIndex < nestedArray.count {
            // Handle nested array case
            if var nestedDict = nestedArray[nestedIndex] as? [String: Any] {
                let deeperPath = Array(remainingPath.dropFirst())
                if deleteArrayElementInJSON(&nestedDict, arrayPath: deeperPath, index: index) {
                    nestedArray[nestedIndex] = nestedDict
                    json[currentKey] = nestedArray
                    return true
                }
            }
        }

        return false
    }

    /// Inserts an element into an array at the specified index
    /// - Parameters:
    ///   - path: Full path where last component is the insertion index (as string)
    ///   - value: The value to insert
    func insertArrayElement(at path: [String], value: Any) {
        guard path.count >= 2,
              let country = selectedCountry,
              var json = country.parseConfigJSON(),
              let indexString = path.last else {
            return
        }

        // Strip brackets to handle both "[0]" and "0" formats
        let stripped = indexString.replacingOccurrences(of: "[", with: "")
                                  .replacingOccurrences(of: "]", with: "")
        guard let index = Int(stripped) else {
            return
        }

        let arrayPath = Array(path.dropLast())

        if !insertArrayElementInJSON(&json, arrayPath: arrayPath, index: index, value: value) {
            return
        }

        if let updated = country.withUpdatedJSON(json) {
            selectedCountry = updated
            modifiedCountryIds.insert(updated.id)

            if let idx = countries.firstIndex(where: { $0.id == updated.id }) {
                countries[idx] = updated
            }
        }
    }

    /// Helper to insert an element into an array in nested JSON
    private func insertArrayElementInJSON(
        _ json: inout [String: Any],
        arrayPath: [String],
        index: Int,
        value: Any
    ) -> Bool {
        guard !arrayPath.isEmpty else { return false }

        if arrayPath.count == 1 {
            // Array is at root level
            if var array = json[arrayPath[0]] as? [Any] {
                let insertIndex = min(index, array.count)
                array.insert(value, at: insertIndex)
                json[arrayPath[0]] = array
                return true
            }
            return false
        }

        // Navigate to the nested array
        let currentKey = arrayPath[0]
        let remainingPath = Array(arrayPath.dropFirst())

        if var nested = json[currentKey] as? [String: Any] {
            if insertArrayElementInJSON(&nested, arrayPath: remainingPath, index: index, value: value) {
                json[currentKey] = nested
                return true
            }
        } else if var nestedArray = json[currentKey] as? [Any],
                  let nestedIndex = Int(remainingPath[0]),
                  nestedIndex < nestedArray.count {
            if var nestedDict = nestedArray[nestedIndex] as? [String: Any] {
                let deeperPath = Array(remainingPath.dropFirst())
                if insertArrayElementInJSON(&nestedDict, arrayPath: deeperPath, index: index, value: value) {
                    nestedArray[nestedIndex] = nestedDict
                    json[currentKey] = nestedArray
                    return true
                }
            }
        }

        return false
    }

    /// Moves an array element from one index to another
    /// - Parameters:
    ///   - arrayPath: Path to the array (not including index)
    ///   - fromIndex: Source index
    ///   - toIndex: Destination index
    func moveArrayElement(arrayPath: [String], fromIndex: Int, toIndex: Int) {
        guard !arrayPath.isEmpty,
              let country = selectedCountry,
              var json = country.parseConfigJSON() else {
            return
        }

        if !moveArrayElementInJSON(&json, arrayPath: arrayPath, fromIndex: fromIndex, toIndex: toIndex) {
            return
        }

        if let updated = country.withUpdatedJSON(json) {
            selectedCountry = updated
            modifiedCountryIds.insert(updated.id)

            if let idx = countries.firstIndex(where: { $0.id == updated.id }) {
                countries[idx] = updated
            }
        }
    }

    /// Helper to move an array element in nested JSON
    private func moveArrayElementInJSON(
        _ json: inout [String: Any],
        arrayPath: [String],
        fromIndex: Int,
        toIndex: Int
    ) -> Bool {
        guard !arrayPath.isEmpty else { return false }

        if arrayPath.count == 1 {
            // Array is at root level
            if var array = json[arrayPath[0]] as? [Any],
               fromIndex < array.count {
                let element = array.remove(at: fromIndex)
                let insertIndex = min(toIndex, array.count)
                array.insert(element, at: insertIndex)
                json[arrayPath[0]] = array
                return true
            }
            return false
        }

        // Navigate to the nested array
        let currentKey = arrayPath[0]
        let remainingPath = Array(arrayPath.dropFirst())

        if var nested = json[currentKey] as? [String: Any] {
            if moveArrayElementInJSON(&nested, arrayPath: remainingPath, fromIndex: fromIndex, toIndex: toIndex) {
                json[currentKey] = nested
                return true
            }
        } else if var nestedArray = json[currentKey] as? [Any],
                  let nestedIndex = Int(remainingPath[0]),
                  nestedIndex < nestedArray.count {
            if var nestedDict = nestedArray[nestedIndex] as? [String: Any] {
                let deeperPath = Array(remainingPath.dropFirst())
                if moveArrayElementInJSON(&nestedDict, arrayPath: deeperPath, fromIndex: fromIndex, toIndex: toIndex) {
                    nestedArray[nestedIndex] = nestedDict
                    json[currentKey] = nestedArray
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Save Operations

    /// Saves all modified countries
    func saveAllChanges() async throws {
        let fileManager = FileManager.default

        for countryId in modifiedCountryIds {
            guard let country = countries.first(where: { $0.id == countryId }),
                  let data = country.configData else {
                continue
            }

            // For deleted files, recreate parent directory
            let parentDir = country.configURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: parentDir.path) {
                try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
            }

            try data.write(to: country.configURL, options: .atomic)
        }

        // Clear modified state and update originalContent to match saved data
        modifiedCountryIds.removeAll()
        for index in countries.indices {
            // After save, update originalContent to match the saved data for future key order preservation
            let newOriginalContent = countries[index].configData.flatMap { String(data: $0, encoding: .utf8) }
            let newGitStatus: GitFileStatus = countries[index].gitStatus == .deleted ? .added : countries[index].gitStatus
            countries[index] = S3CountryConfig(
                countryCode: countries[index].countryCode,
                configURL: countries[index].configURL,
                configData: countries[index].configData,
                originalContent: newOriginalContent,
                hasChanges: false,
                gitStatus: newGitStatus,
                isDeletedPlaceholder: false,
                editedPaths: []
            )
        }

        // Update selected country
        if let selected = selectedCountry {
            selectedCountry = countries.first(where: { $0.id == selected.id })
        }

        // Refresh git status after save (files now differ from git index)
        await updateGitStatuses()
    }

    /// Saves a specific country's config
    func saveCountry(_ country: S3CountryConfig) async throws {
        guard let originalData = country.configData else {
            throw S3StoreError.noDataToSave
        }

        // Determine what data to write
        let dataToWrite: Data

        // Check if file already exists on disk (to prevent sparse restore on subsequent saves)
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: country.configURL.path)

        // For deleted files with partial edits, construct sparse JSON
        // Only do this on FIRST save (when file doesn't exist yet)
        if country.gitStatus == .deleted && !country.editedPaths.isEmpty && !fileExists {
            // Build sparse JSON containing only edited fields
            if let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths),
               let sparseData = sparseCountry.configData {
                dataToWrite = sparseData
                #if DEBUG
                print("[S3Store] Saving deleted country with sparse JSON (\(country.editedPaths.count) edited fields)")
                #endif
            } else {
                // Fallback to full JSON if sparse construction fails
                dataToWrite = originalData
                #if DEBUG
                print("[S3Store] WARNING: Sparse JSON construction failed, using full JSON")
                #endif
            }
        } else {
            // Normal save: write full JSON
            dataToWrite = originalData
        }

        // For deleted files, recreate parent directory
        let parentDir = country.configURL.deletingLastPathComponent()

        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        // Write the config file
        try dataToWrite.write(to: country.configURL, options: .atomic)

        // Update state - use dataToWrite as new configData
        modifiedCountryIds.remove(country.id)
        if let index = countries.firstIndex(where: { $0.id == country.id }) {
            let newOriginalContent = String(data: dataToWrite, encoding: .utf8)
            let newGitStatus: GitFileStatus = country.gitStatus == .deleted ? .added : country.gitStatus
            countries[index] = S3CountryConfig(
                countryCode: country.countryCode,
                configURL: country.configURL,
                configData: dataToWrite,  // Use sparse data
                originalContent: newOriginalContent,
                hasChanges: false,
                gitStatus: newGitStatus,
                isDeletedPlaceholder: false,
                editedPaths: []
            )
        }

        if selectedCountry?.id == country.id {
            selectedCountry = countries.first(where: { $0.id == country.id })
        }

        // Refresh git status after save (file now differs from git index)
        await updateGitStatuses()
        await refreshGitStatus()
    }

    // MARK: - Field Selection Operations (for Batch Update)

    /// Selects a node in the JSON tree for applying to other countries
    func selectNode(path: [String], value: Any, isDeleted: Bool = false, keyCount: Int? = nil) {
        // Reject empty path (absolute root) which returns entire JSON
        guard !path.isEmpty else {
            selectionError = S3EditorConfiguration.InspectionError.absoluteRoot
            return
        }

        // Clear any previous error
        selectionError = nil

        selectedNodePath = path.joined(separator: ".")
        selectedNodeValue = value
        selectedNodeIsDeleted = isDeleted
        selectedNodeKeyCount = keyCount
    }

    /// Clears the current node selection
    func clearNodeSelection() {
        selectedNodePath = nil
        selectedNodeValue = nil
        selectedNodeIsDeleted = false
        selectedNodeKeyCount = nil
        selectionError = nil
    }

    /// Starts the apply field wizard with the currently selected node
    func startApplyFieldWizard() {
        guard selectedNodePath != nil, selectedNodeValue != nil else { return }
        showApplyFieldSheet = true
    }

    /// Starts the inspect field wizard with the currently selected node
    func startInspectFieldWizard() {
        guard selectedNodePath != nil, selectedNodeValue != nil else { return }
        showInspectFieldSheet = true
    }

    /// Applies the selected field value to target countries and saves to disk immediately
    /// - Parameter targetCountryIds: Set of country IDs to apply the field to
    func applyFieldToCountries(_ targetCountryIds: Set<String>) async throws {
        guard selectedCountry != nil,
              let sourcePath = selectedNodePath,
              let valueToApply = selectedNodeValue,
              !targetCountryIds.isEmpty else {
            throw S3StoreError.invalidWizardState
        }

        let pathComponents = sourcePath.split(separator: ".").map(String.init)

        for targetId in targetCountryIds {
            guard let targetIndex = countries.firstIndex(where: { $0.id == targetId }) else {
                continue
            }

            // Update the JSON value using targeted replacement (minimal git diff)
            if let updated = countries[targetIndex].withUpdatedValue(valueToApply, at: pathComponents) {

                // Write to disk immediately
                guard let data = updated.configData else { continue }
                try data.write(to: updated.configURL, options: .atomic)

                // Update in-memory state with hasChanges = false (already saved)
                let newOriginalContent = String(data: data, encoding: .utf8)
                countries[targetIndex] = S3CountryConfig(
                    countryCode: updated.countryCode,
                    configURL: updated.configURL,
                    configData: updated.configData,
                    originalContent: newOriginalContent,
                    hasChanges: false
                )
            }
        }

        // Refresh git status after applying changes (files now differ from git index)
        await updateGitStatuses()

        // Only dismiss after all saves complete successfully
        showApplyFieldSheet = false
    }

    /// Applies field values to target countries with per-country customization
    /// - Parameter countryValues: Dictionary mapping country ID to the value to apply
    func applyFieldToCountriesWithValues(_ countryValues: [String: Any]) async throws {
        guard selectedCountry != nil,
              let sourcePath = selectedNodePath,
              !countryValues.isEmpty else {
            throw S3StoreError.invalidWizardState
        }

        let pathComponents = sourcePath.split(separator: ".").map(String.init)

        for (countryId, valueToApply) in countryValues {
            guard let targetIndex = countries.firstIndex(where: { $0.id == countryId }) else {
                continue
            }

            // Update the JSON value using targeted replacement (minimal git diff)
            if let updated = countries[targetIndex].withUpdatedValue(valueToApply, at: pathComponents) {

                // Write to disk immediately
                guard let data = updated.configData else { continue }
                try data.write(to: updated.configURL, options: .atomic)

                // Update in-memory state with hasChanges = false (already saved)
                let newOriginalContent = String(data: data, encoding: .utf8)
                countries[targetIndex] = S3CountryConfig(
                    countryCode: updated.countryCode,
                    configURL: updated.configURL,
                    configData: updated.configData,
                    originalContent: newOriginalContent,
                    hasChanges: false
                )
            }
        }

        // Refresh git status after applying changes (files now differ from git index)
        await updateGitStatuses()

        // Only dismiss after all saves complete successfully
        showApplyFieldSheet = false
    }

    /// Sets a value in JSON, creating intermediate objects if needed
    private func setValueCreatingPath(_ json: inout [String: Any], at path: [String], value: Any) -> Bool {
        guard !path.isEmpty else { return false }

        if path.count == 1 {
            json[path[0]] = value
            return true
        }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        // Create intermediate object if it doesn't exist
        if json[key] == nil {
            json[key] = [String: Any]()
        }

        if var nested = json[key] as? [String: Any] {
            if setValueCreatingPath(&nested, at: remainingPath, value: value) {
                json[key] = nested
                return true
            }
        }

        return false
    }

    // MARK: - Discard Operations

    /// Discards changes for a specific country using git restore
    func discardChanges(for countryId: String) async {
        // Show loading state during discard operation
        isLoading = true
        defer { isLoading = false }

        await discardChangesInternal(for: countryId)

        // Refresh git status after discard (file restored to git state)
        await updateGitStatuses()
        await refreshGitStatus()
    }

    /// Gets the relative path for a config file within the repository
    private func getRelativePath(for configURL: URL) -> String? {
        guard let repoURL = s3RepositoryURL else { return nil }
        let fullPath = configURL.path
        let repoPath = repoURL.path
        guard fullPath.hasPrefix(repoPath) else { return nil }
        // Remove the repo path and leading slash
        var relativePath = String(fullPath.dropFirst(repoPath.count))
        if relativePath.hasPrefix("/") {
            relativePath = String(relativePath.dropFirst())
        }
        return relativePath
    }

    /// Internal discard method that doesn't set loading state or refresh git
    /// Used by discardAllChanges to batch operations
    private func discardChangesInternal(for countryId: String) async {
        guard let index = countries.firstIndex(where: { $0.id == countryId }) else {
            return
        }

        let country = countries[index]
        let configURL = country.configURL

        // Check if country has git changes or in-memory changes
        let hasGitChanges = country.gitStatus != .unchanged
        let hasMemoryChanges = modifiedCountryIds.contains(countryId)

        guard hasGitChanges || hasMemoryChanges else {
            return
        }

        // Try git restore if available (restores file on disk from HEAD)
        if hasGitChanges, let gitWorker, let relativePath = getRelativePath(for: configURL) {
            do {
                // Use special restore for deleted files
                if country.gitStatus == .deleted {
                    try await gitWorker.restoreDeletedFile(relativePath: relativePath)
                } else {
                    try await gitWorker.restoreFile(relativePath: relativePath)
                }
            } catch {
                // If git restore fails, log but continue to reload what's on disk
                print("Failed to restore file from git: \(error.localizedDescription)")
            }
        }

        // Reload content from disk (either git-restored or original)
        let configData = try? Data(contentsOf: configURL)
        let originalContent = try? String(contentsOf: configURL, encoding: .utf8)

        countries[index] = S3CountryConfig(
            countryCode: country.countryCode,
            configURL: configURL,
            configData: configData,
            originalContent: originalContent,
            hasChanges: false,
            gitStatus: country.gitStatus,
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Remove from modified set if it was there
        modifiedCountryIds.remove(countryId)

        // Update selectedCountry to the refreshed version
        if selectedCountry?.id == countryId {
            selectedCountry = countries[index]
        }
    }
}

// MARK: - S3 Store Errors

enum S3StoreError: LocalizedError {
    case noDataToSave
    case invalidWizardState
    case valueNotFound
    case fileDeleted(String)

    var errorDescription: String? {
        switch self {
        case .noDataToSave:
            return "No configuration data to save"
        case .invalidWizardState:
            return "Invalid wizard state - missing source, path, or targets"
        case .valueNotFound:
            return "Could not find value at the specified path"
        case .fileDeleted(let countryCode):
            return "Cannot save: The config file for '\(countryCode)' was deleted. Please reload the repository."
        }
    }
}

// MARK: - GitPublishable Conformance

extension S3Store: GitPublishable {
    func saveAllModifications() async throws {
        // S3 Editor saves all modified countries
        try await saveAllChanges()
    }

    func generateCommitMessage() -> String {
        let countryList = uncommittedCountries.map { $0.countryCode.uppercased() }.sorted().joined(separator: ", ")
        if countryList.isEmpty {
            return "Update S3 feature config"
        }
        return "Update feature config for [\(countryList)]"
    }

    func generatePRTitle() -> String {
        let count = uncommittedCountries.count
        if count == 0 {
            return "feat: Update S3 feature config"
        }
        return "feat: Update S3 feature config for \(count) countr\(count == 1 ? "y" : "ies")"
    }

    func generatePRBody() -> String {
        let modifiedCountries = uncommittedCountries.map { $0.countryCode.uppercased() }.sorted()
        let countryList = modifiedCountries.joined(separator: ", ")
        if countryList.isEmpty {
            return """
            ## Summary
            - Updated S3 feature configuration
            - Environment: \(selectedEnvironment.displayName)

            ---
            Created with DHOpsTools S3 Config Editor
            """
        }
        return """
        ## Summary
        - Updated S3 feature configuration for: \(countryList)
        - Environment: \(selectedEnvironment.displayName)

        ## Changes
        \(modifiedCountries.map { "- \($0)" }.joined(separator: "\n"))

        ---
        Created with DHOpsTools S3 Config Editor
        """
    }

    func refreshAfterGitOperation() async {
        await refreshGitStatus()
        await updateGitStatuses()
    }

    /// Reloads countries and updates git statuses after git operations
    func reloadDataAfterGitOperation() async {
        await loadCountries()
        await updateGitStatuses()
    }

    /// Cleans up state after discard all
    func cleanupStateAfterDiscardAll() async {
        // Clear modified country IDs
        modifiedCountryIds.removeAll()

        // Clear selection if it was modified
        if let selectedCountry, selectedCountry.gitStatus != .unchanged {
            self.selectedCountry = nil
        }
    }

    // MARK: - Schema Validation

    /// Validates a country configuration against the schema
    /// - Parameter country: The country configuration to validate
    /// - Returns: Validation result containing any errors or warnings
    func validateCountry(_ country: S3CountryConfig) async -> JSONSchemaValidationResult {
        guard let schema = parsedSchema else {
            // No schema available, return success
            return .success
        }

        // Convert country data to JSON dictionary for validation
        guard let jsonData = country.configData else {
            return .failure(path: [], message: "No data available for validation")
        }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            let validator = JSONSchemaValidator(schema: schema)
            return validator.validate(jsonObject, schema: schema, path: [])
        } catch {
            return .failure(path: [], message: "Invalid JSON data: \(error.localizedDescription)")
        }
    }

    /// Checks if a country configuration is valid for saving
    /// - Parameter country: The country configuration to check
    /// - Returns: true if validation passes (no errors), false otherwise
    func isValidForSave(_ country: S3CountryConfig) -> Bool {
        guard let result = validationResults[country.countryCode] else {
            return true // No validation result means no schema, allow save
        }
        return result.isValid
    }

    /// Validates the selected country and stores the result
    func validateSelectedCountry() async {
        guard let country = selectedCountry else { return }

        let result = await validateCountry(country)
        validationResults[country.countryCode] = result

        if !result.errors.isEmpty {
            AppLogger.shared.info("Validation found \(result.errorCount) errors and \(result.warningCount) warnings for \(country.countryCode)")
        }
    }

    /// Clears validation results (useful when schema changes or countries reload)
    func clearValidationResults() {
        validationResults.removeAll()
    }

    /// Navigate to a validation error by expanding parents, selecting, and scrolling
    /// - Parameters:
    ///   - error: The validation error to navigate to
    ///   - treeViewModel: Tree view model to expand nodes
    ///   - scrollProxy: Scroll view proxy to scroll to the error
    func navigateToValidationError(
        _ error: ValidationError,
        treeViewModel: JSONTreeViewModel,
        scrollProxy: ScrollViewProxy
    ) {
        // 1. Expand parent nodes
        treeViewModel.expandPathToNode(error.path)

        // 2. Get value at error path for selection
        guard let country = selectedCountry,
              let json = country.parseConfigJSON() else { return }

        let value = getValue(at: error.path, from: json)

        // 3. Select the node with key count for objects
        if let value = value {
            let keyCount: Int?
            if let node = treeViewModel.flattenedNodes.first(where: { $0.path == error.path }),
               case .object(let count) = node.nodeType {
                keyCount = count
            } else {
                keyCount = nil
            }
            selectNode(path: error.path, value: value, keyCount: keyCount)
        }

        // 4. Scroll to the node with animation
        // Small delay ensures tree has rebuilt after expansion
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))

            withAnimation(.easeInOut(duration: 0.3)) {
                scrollProxy.scrollTo(error.pathString, anchor: .center)
            }
        }
    }
}
