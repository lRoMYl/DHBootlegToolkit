import SwiftUI
import Observation
import DHBootlegToolkitCore
import OSLog

// MARK: - Detail Tab Model

enum DetailTab: String, CaseIterable {
    case newKey = "new"
    case existingKey = "existing"
}

// MARK: - External Change Info

struct ExternalChangeInfo {
    let featureName: String
    let filePath: String
}

// MARK: - New Key Form Data

/// Persists the state of the New Key wizard across tab switches
struct NewKeyFormData {
    enum WizardStep: Int, CaseIterable {
        case screenshot = 0
        case keyDetails = 1
        case review = 2

        var title: String {
            switch self {
            case .screenshot: return "Add Screenshot"
            case .keyDetails: return "Key Details"
            case .review: return "Review & Create"
            }
        }

        var stepNumber: Int { rawValue + 1 }
        var totalSteps: Int { WizardStep.allCases.count }
    }

    var currentStep: WizardStep = .screenshot
    var screenshotURL: URL?
    var generatedScreenshotName: String = ""
    var keyName: String = ""
    var translation: String = ""
    var notes: String = ""
    var targetLanguagesText: String = ""
    var charLimit: Int?
}

@Observable
@MainActor
final class AppStore {

    // MARK: - Configuration

    private let configuration: RepositoryConfiguration
    private let logger = Logger(subsystem: "com.dhbootlegtoolkit", category: "AppStore")

    init(configuration: RepositoryConfiguration = PandoraRepositoryConfiguration()) {
        self.configuration = configuration
    }

    // MARK: - State

    var repositoryURL: URL?
    var selectedPlatform: Platform = .mobile
    var selectedFeature: FeatureFolder?

    var features: [FeatureFolder] = []
    var translationKeys: [TranslationKey] = []
    var pendingScreenshots: [PendingScreenshot] = []

    /// Pre-computed index for O(1) feature lookup by path prefix
    private var featurePathIndex: [String: FeatureFolder] = [:]

    // Sidebar navigation state
    var expandedFeatures: Set<String> = []
    var searchText: String = ""
    var featureKeys: [String: [TranslationKey]] = [:]
    private var featureFileHashes: [String: String] = [:]  // [featureId: fileHash]

    // Multi-tab navigation state
    var openTabs: [EditorTab] = []           // Ordered list of open key tabs
    var activeTabId: UUID?                    // Currently focused key tab
    var showNewKeyTab = false                 // "New" tab (always first, max 1)
    var newKeyTabFeature: FeatureFolder?
    var newKeyFormData: NewKeyFormData?       // Persisted form data for "New" tab
    var isNewKeyTabActive: Bool {             // Is "New" tab the active one?
        showNewKeyTab && activeTabId == nil
    }

    // Close tab confirmation state
    var pendingCloseTabId: UUID?
    var showCloseTabConfirmation = false

    var gitStatus: GitStatus = .unconfigured
    var isLoading = false

    // Diff state for tracking key-level changes
    var featureKeyDiffs: [String: TranslationKeyDiff] = [:]

    // Feature file items cache (for sidebar tree display)
    var featureFiles: [String: [FeatureFileItem]] = [:]

    var showRepositoryPickerDialog = false
    var showCreateBranchPrompt = false

    /// Feature to open Add New Key tab for after branch creation (set when Add New Key triggers branch prompt)
    var pendingAddNewKeyFeature: FeatureFolder?
    var showPublishError = false
    var publishErrorMessage: String?

    var showRepositoryError = false
    var repositoryErrorMessage: String?
    var availablePlatforms: Set<Platform> = []
    var availableBranches: [String] = []
    var isLoadingBranches = false

    // Branch switch confirmation state
    var pendingBranchSwitch: String?
    var pendingBranchSwitchError: String?
    var showUncommittedChangesConfirmation = false

    // External change detection state
    private var lastLoadedFileHash: String?
    var showExternalChangeConflict = false
    var pendingExternalChange: ExternalChangeInfo?

    // Discard confirmation state
    var showDiscardKeyConfirmation = false
    var showDiscardAllConfirmation = false
    var showDiscardRepositoryConfirmation = false
    var keyToDiscard: String?
    var featureToDiscard: FeatureFolder?

    // File discard confirmation state
    var showDiscardFileConfirmation = false
    var fileToDiscard: (file: FeatureFileItem, feature: FeatureFolder)?

    // Permanent delete confirmation state
    var showDeleteFileConfirmation = false
    var fileToDelete: (file: FeatureFileItem, feature: FeatureFolder)?
    var showDeleteFolderConfirmation = false
    var folderToDelete: (folder: FeatureFileItem, feature: FeatureFolder)?

    // Delete localization key confirmation state
    var showDeleteLocalizationConfirmation = false
    var localizationKeyToDelete: (keyName: String, feature: FeatureFolder)?

    // Navigation with unsaved changes confirmation
    var showUnsavedChangesWarning = false
    var pendingKeySelection: (key: TranslationKey, feature: FeatureFolder)?

    // State management error state
    var showStateManagementError = false
    var stateManagementErrorMessage: String?

    // MARK: - Workers

    private var fileSystemWorker: FileSystemWorker?
    var gitWorker: GitWorker?
    private var diffWorker: DiffWorker?
    private var externalChangeWorker: ExternalChangeWorker?

    /// Whether the file system worker is initialized (repository selected)
    var isFileSystemReady: Bool {
        fileSystemWorker != nil
    }

    // MARK: - Computed Properties

    /// The currently active key tab data (if any key tab is active)
    var activeKeyTab: KeyTabData? {
        guard let activeTabId else { return nil }
        return openTabs.first { $0.id == activeTabId }?.keyData
    }

    /// The currently active image tab data (if any image tab is active)
    var activeImageTab: ImageTabData? {
        guard let activeTabId else { return nil }
        return openTabs.first { $0.id == activeTabId }?.imageData
    }

    /// The currently active generic file tab data (if any generic file tab is active)
    var activeGenericFileTab: GenericFileTabData? {
        guard let activeTabId else { return nil }
        return openTabs.first { $0.id == activeTabId }?.genericFileData
    }

    /// The currently active text file tab data (if any text file tab is active)
    var activeTextFileTab: TextTabData? {
        guard let activeTabId else { return nil }
        return openTabs.first { $0.id == activeTabId }?.textFileData
    }

    /// The key from the active tab (for backward compatibility)
    var selectedKey: TranslationKey? {
        activeKeyTab?.editedKey
    }

    /// The edited key from the active tab (for backward compatibility)
    var editedKey: TranslationKey? {
        get { activeKeyTab?.editedKey }
        set {
            guard let newValue else {
                logger.warning("editedKey setter: newValue is nil, ignoring")
                return
            }

            guard let tabId = activeTabId else {
                logger.error("editedKey setter: activeTabId is nil")
                stateManagementErrorMessage = "Cannot save changes: No active tab. Please close and reopen the translation key."
                showStateManagementError = true
                return
            }

            guard let index = openTabs.firstIndex(where: { $0.id == tabId }) else {
                logger.error("editedKey setter: Tab with ID \(tabId) not found in openTabs")
                stateManagementErrorMessage = "Cannot save changes: Tab was closed. Please reopen the translation key."
                showStateManagementError = true
                return
            }

            guard case .key(var keyData) = openTabs[index] else {
                logger.error("editedKey setter: Tab at index \(index) is not a key tab")
                stateManagementErrorMessage = "Cannot save changes: Invalid tab type. Please close and reopen the translation key."
                showStateManagementError = true
                return
            }

            keyData.editedKey = newValue
            openTabs[index] = .key(keyData)
            logger.debug("editedKey setter: Successfully updated edited key for tab \(tabId)")
        }
    }

    /// Whether the active tab has unsaved changes (for backward compatibility)
    var hasChanges: Bool {
        get { activeKeyTab?.hasChanges ?? false }
        set {
            guard let tabId = activeTabId else {
                logger.error("hasChanges setter: activeTabId is nil")
                stateManagementErrorMessage = "Cannot update change state: No active tab. Please close and reopen the translation key."
                showStateManagementError = true
                return
            }

            guard let index = openTabs.firstIndex(where: { $0.id == tabId }) else {
                logger.error("hasChanges setter: Tab with ID \(tabId) not found in openTabs")
                stateManagementErrorMessage = "Cannot update change state: Tab was closed. Please reopen the translation key."
                showStateManagementError = true
                return
            }

            guard case .key(var keyData) = openTabs[index] else {
                logger.error("hasChanges setter: Tab at index \(index) is not a key tab")
                stateManagementErrorMessage = "Cannot update change state: Invalid tab type. Please close and reopen the translation key."
                showStateManagementError = true
                return
            }

            keyData.hasChanges = newValue
            openTabs[index] = .key(keyData)
            logger.debug("hasChanges setter: Successfully updated hasChanges to \(newValue) for tab \(tabId)")
        }
    }

    /// Check if any tab has unsaved changes
    var anyTabHasChanges: Bool {
        openTabs.contains { tab in
            if case .key(let data) = tab {
                return data.hasChanges
            }
            return false
        }
    }

    var canSave: Bool {
        guard let keyData = activeKeyTab, let key = keyData.editedKey else { return false }
        return key.isValid
    }

    var canPublish: Bool {
        gitStatus.hasUncommittedChanges && gitStatus.isReady
    }

    var currentBranchDisplayName: String {
        gitStatus.currentBranch ?? "No branch"
    }

    var isOnProtectedBranch: Bool {
        gitStatus.isOnProtectedBranch
    }

    /// Checks if a specific branch name is protected
    func isProtectedBranch(_ branchName: String) -> Bool {
        configuration.isProtectedBranch(branchName)
    }

    /// Builds the feature path index for O(1) lookups
    /// Called after features are loaded
    private func buildFeaturePathIndex() {
        featurePathIndex = [:]
        for feature in features {
            let key = "\(feature.platform.folderName)/\(feature.name)/"
            featurePathIndex[key] = feature
        }
    }

    /// Features that have uncommitted files (detected from git status)
    /// Uses featurePathIndex for O(n) lookup instead of O(n*m)
    var uncommittedFeatureIds: Set<String> {
        var featureIds = Set<String>()
        for file in gitStatus.uncommittedFiles {
            // Find matching feature using path prefix index
            for (pathPrefix, feature) in featurePathIndex {
                if file.contains(pathPrefix) {
                    featureIds.insert(feature.id)
                    break  // Found match, stop searching for this file
                }
            }
        }
        return featureIds
    }

    /// Features that have uncommitted changes (for generating commit messages)
    var uncommittedFeatures: [FeatureFolder] {
        let ids = uncommittedFeatureIds
        return features.filter { ids.contains($0.id) }
    }

    // MARK: - Diff Operations

    /// Get the diff for a specific feature (returns cached or empty)
    func getDiff(for feature: FeatureFolder) -> TranslationKeyDiff {
        featureKeyDiffs[feature.id] ?? .empty
    }

    /// Get the change status for a specific key in a feature
    func keyChangeStatus(_ keyName: String, in feature: FeatureFolder) -> KeyChangeStatus {
        getDiff(for: feature).status(for: keyName)
    }

    /// Compute diff for a single feature (lazy, on expansion)
    func computeDiffForFeature(_ feature: FeatureFolder) async {
        // Only skip if already cached or no diffWorker
        guard featureKeyDiffs[feature.id] == nil,
              let diffWorker else {
            return
        }

        let diff = await diffWorker.computeDiff(for: feature)
        featureKeyDiffs[feature.id] = diff
    }

    /// Compute diffs for all features with uncommitted changes
    /// Called after git status refresh to ensure badges show counters instead of [M]
    func computeDiffsForUncommittedFeatures() async {
        guard let diffWorker else { return }

        let uncommittedIds = uncommittedFeatureIds
        let featuresToCompute = features.filter {
            uncommittedIds.contains($0.id) && featureKeyDiffs[$0.id] == nil
        }

        guard !featuresToCompute.isEmpty else { return }

        // Compute diffs in parallel (computeDiff is nonisolated)
        await withTaskGroup(of: (String, TranslationKeyDiff).self) { group in
            for feature in featuresToCompute {
                group.addTask {
                    let diff = await diffWorker.computeDiff(for: feature)
                    return (feature.id, diff)
                }
            }

            for await (featureId, diff) in group {
                featureKeyDiffs[featureId] = diff
            }
        }
    }

    /// Invalidate diff cache (call after save or git status refresh)
    func invalidateDiffCache() {
        featureKeyDiffs = [:]
    }

    /// Features filtered by search text (matches feature name, key name, translation, or notes)
    var filteredFeatures: [FeatureFolder] {
        guard !searchText.isEmpty else { return features }

        return features.filter { feature in
            // Match feature folder name
            if feature.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            // Match keys within feature
            guard let keys = featureKeys[feature.id] else { return false }
            return keys.contains { key in
                key.key.localizedCaseInsensitiveContains(searchText) ||
                key.translation.localizedCaseInsensitiveContains(searchText) ||
                key.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    /// Get filtered keys for a feature based on search text
    func filteredKeys(for feature: FeatureFolder) -> [TranslationKey] {
        guard let keys = featureKeys[feature.id] else { return [] }
        guard !searchText.isEmpty else { return keys }

        return keys.filter { key in
            key.key.localizedCaseInsensitiveContains(searchText) ||
            key.translation.localizedCaseInsensitiveContains(searchText) ||
            key.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Repository Management

    func showRepositoryPicker() {
        showRepositoryPickerDialog = true
    }

    func selectRepository(_ url: URL, showAlertOnError: Bool = true) async {
        let startup = TimingGroup(id: "localization-editor-tti-\(url.lastPathComponent)", name: "Localization Editor TTI: \(url.lastPathComponent)")
        AppLogger.shared.info("Opening repository: \(url.lastPathComponent)")

        let worker = FileSystemWorker(configuration: configuration)

        // Validate repository
        let validation = await AppLogger.shared.time("Validate repository", group: startup) {
            worker.validateRepository(url)
        }

        guard validation.isValid else {
            AppLogger.shared.error("Repository validation failed: \(validation.errorMessage ?? "Unknown error")")
            repositoryErrorMessage = validation.errorMessage
            if showAlertOnError {
                showRepositoryError = true
            }
            AppLogger.shared.endGroup(startup)
            return
        }

        // Set loading immediately so sidebar shows indicator during all async work
        isLoading = true
        defer { isLoading = false }

        // Initialize workers
        await AppLogger.shared.time("Initialize workers", group: startup) {
            repositoryURL = url
            fileSystemWorker = worker
            gitWorker = GitWorker(repositoryURL: url, configuration: configuration)
            diffWorker = DiffWorker(repositoryURL: url, gitWorker: gitWorker!)
            externalChangeWorker = ExternalChangeWorker(fileSystemWorker: worker)
        }

        // Track available platforms from validation result
        availablePlatforms = Set(
            configuration.platforms.filter { validation.availablePlatformIds.contains($0.id) }
        )

        // Default to first available platform
        if !availablePlatforms.contains(selectedPlatform) {
            selectedPlatform = availablePlatforms.first ?? .mobile
        }

        // Git operations
        await AppLogger.shared.time("Refresh git status", group: startup) {
            await refreshGitStatus()
        }

        // Note: loadBranches() is called by GitStatusBar's .task when it appears
        // This avoids blocking startup (~5s) - branches load in background

        // Feature loading
        await AppLogger.shared.time("Load features", group: startup) {
            await loadFeatures()
        }

        await AppLogger.shared.time("Compute diffs", group: startup) {
            await computeDiffsForUncommittedFeatures()
        }

        await AppLogger.shared.time("Load uncommitted files", group: startup) {
            await loadFilesForUncommittedFeatures()
        }

        // Log completion message inside the timing group
        AppLogger.shared.info("Repository ready")

        // End the startup timing group (logs total duration)
        AppLogger.shared.endGroup(startup)
    }

    // MARK: - Git Operations

    /// Creates a branch, returns result with collision detection
    func createBranch(_ branchName: String) async -> BranchResult {
        guard let gitWorker, !branchName.isEmpty else {
            return .error("Invalid branch name")
        }

        do {
            try await gitWorker.createBranch(branchName)
            await refreshGitStatus()
            await loadBranches()
            return .success
        } catch {
            await refreshGitStatus()
            let message = error.localizedDescription
            if message.contains("already exists") {
                return .branchExists(branchName)
            }
            return .error(userFriendlyGitError(error))
        }
    }

    /// Performs the actual branch switch (called after confirmation or when no changes)
    func performBranchSwitch(_ branchName: String) async -> String? {
        guard let gitWorker else { return "Git not configured" }

        do {
            try await gitWorker.switchToBranch(branchName)
            await refreshGitStatus()
            await loadBranches()
            return nil
        } catch {
            await refreshGitStatus()
            return userFriendlyGitError(error)
        }
    }

    /// Rename branch (not allowed for protected branches), returns error message if failed
    func renameBranch(to newName: String) async -> String? {
        guard let gitWorker, let currentBranch = gitStatus.currentBranch else {
            return "No current branch"
        }

        // Protect main/master and other protected branches
        if configuration.protectedBranches.contains(currentBranch) {
            return "Cannot rename a protected branch"
        }

        do {
            try await gitWorker.renameBranch(from: currentBranch, to: newName)
            await refreshGitStatus()
            await loadBranches()
            return nil
        } catch {
            await refreshGitStatus()
            return userFriendlyGitError(error)
        }
    }

    // MARK: - Feature Loading

    func loadFeatures() async {
        guard let repositoryURL, let fileSystemWorker else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            features = try await fileSystemWorker.discoverFeatures(in: repositoryURL, platform: selectedPlatform)
            AppLogger.shared.info("Found \(features.count) features for \(selectedPlatform.displayName)")

            // Build path index for fast uncommitted feature lookups
            buildFeaturePathIndex()

            // Pre-load keys for all features so search works immediately
            await loadAllFeatureKeys()
        } catch {
            AppLogger.shared.error("Failed to discover features: \(error.localizedDescription)")
            features = []
        }
    }

    /// Pre-load keys for all features (enables search to work immediately)
    private func loadAllFeatureKeys() async {
        await withTaskGroup(of: Void.self) { group in
            for feature in features {
                group.addTask {
                    await self.loadKeysForFeature(feature)
                }
            }
        }
    }

    func selectPlatform(_ platform: Platform) async {
        selectedPlatform = platform
        selectedFeature = nil
        closeAllTabs()
        translationKeys = []
        featureKeys = [:] // Clear cached keys when switching platform
        featureFiles = [:] // Clear cached files when switching platform
        expandedFeatures = []
        invalidateDiffCache() // Clear diffs when switching platform
        await loadFeatures()
        await computeDiffsForUncommittedFeatures()
        await loadFilesForUncommittedFeatures()
    }

    func selectFeature(_ feature: FeatureFolder) async {
        selectedFeature = feature
        closeAllTabs()
        await loadTranslationKeys()
    }

    /// Toggle expansion state of a feature in sidebar
    func toggleFeatureExpansion(_ feature: FeatureFolder) {
        if expandedFeatures.contains(feature.id) {
            expandedFeatures.remove(feature.id)
        } else {
            expandedFeatures.insert(feature.id)
            // Load keys if not already loaded
            if featureKeys[feature.id] == nil {
                Task { await loadKeysForFeature(feature) }
            }
        }
    }

    /// Load keys for a specific feature (used for lazy loading in sidebar)
    func loadKeysForFeature(_ feature: FeatureFolder) async {
        guard let fileSystemWorker else { return }

        let fileURL = feature.primaryLanguageFileURL
        do {
            if fileSystemWorker.fileExists(at: fileURL) {
                let keys = try await fileSystemWorker.loadEntities(from: fileURL)
                featureKeys[feature.id] = keys
                // Track the hash of what we loaded
                featureFileHashes[feature.id] = fileSystemWorker.computeFileHash(fileURL)
            } else {
                featureKeys[feature.id] = []
                featureFileHashes[feature.id] = nil
            }
        } catch {
            featureKeys[feature.id] = []
        }
    }

    /// Load file items for a specific feature (for sidebar tree display)
    func loadFilesForFeature(_ feature: FeatureFolder) async {
        guard let fileSystemWorker, let gitWorker, let repositoryURL else { return }

        do {
            // Discover files in the feature folder
            var items = try await fileSystemWorker.discoverFilesInFeature(feature)

            // Calculate relative path for git status
            let repoPath = repositoryURL.path
            let featurePath = feature.url.path
            let relativePath = featurePath.hasPrefix(repoPath) ?
                String(featurePath.dropFirst(repoPath.count + 1)) : feature.name

            // Update git status for all items
            items = try await gitWorker.updateFileItemStatuses(items, basePath: relativePath)

            // Add deleted files (exist in git but not on disk)
            let deletedFilePaths = try await gitWorker.getDeletedFiles(inDirectory: relativePath)
            items = insertDeletedFiles(
                deletedFilePaths,
                into: items,
                featureId: feature.id,
                repoPath: repoPath,
                basePath: relativePath
            )

            // Sort items: primary JSON first, then folders, then other files alphabetically
            items.sort { lhs, rhs in
                // Primary JSON first
                if case .jsonFile(let lhsPrimary) = lhs.type,
                   case .jsonFile(let rhsPrimary) = rhs.type {
                    if lhsPrimary != rhsPrimary { return lhsPrimary }
                }
                if case .jsonFile(let lhsPrimary) = lhs.type, lhsPrimary { return true }
                if case .jsonFile(let rhsPrimary) = rhs.type, rhsPrimary { return false }

                // Folders before files
                if case .folder = lhs.type, case .folder = rhs.type {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                if case .folder = lhs.type { return true }
                if case .folder = rhs.type { return false }

                // Alphabetical for the rest
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

            featureFiles[feature.id] = items
        } catch {
            featureFiles[feature.id] = []
        }
    }

    /// Loads file items for all features that have uncommitted changes.
    /// This enables counter badges to show proper counts before expansion.
    func loadFilesForUncommittedFeatures() async {
        let uncommittedIds = uncommittedFeatureIds

        for feature in features where uncommittedIds.contains(feature.id) {
            // Only load if not already loaded
            if featureFiles[feature.id] == nil {
                await loadFilesForFeature(feature)
            }
        }
    }

    /// Inserts deleted files into the correct location in the item tree.
    /// Files in subfolders are added as children of the appropriate folder.
    private func insertDeletedFiles(
        _ deletedPaths: [String],
        into items: [FeatureFileItem],
        featureId: String,
        repoPath: String,
        basePath: String
    ) -> [FeatureFileItem] {
        var result = items

        for fullPath in deletedPaths {
            // Get path relative to feature folder
            // fullPath is like "translations/mobile/feature/images/file.png"
            // basePath is like "translations/mobile/feature"
            let relativePath: String
            if fullPath.hasPrefix(basePath + "/") {
                relativePath = String(fullPath.dropFirst(basePath.count + 1))
            } else {
                relativePath = fullPath
            }

            // Split into components to check for subdirectories
            let components = relativePath.split(separator: "/").map(String.init)

            if components.count > 1 {
                // File is in a subdirectory (e.g., "images/file.png")
                let folderName = components[0]
                let fileName = components.last!

                // Find the folder in the items
                if let folderIndex = result.firstIndex(where: { $0.name == folderName && $0.type == .folder }) {
                    // Create the deleted file item
                    let deletedItem = createDeletedFileItem(
                        fullPath: fullPath,
                        name: fileName,
                        featureId: featureId,
                        repoPath: repoPath
                    )
                    // Add to folder's children
                    result[folderIndex].children.append(deletedItem)
                } else {
                    // Folder doesn't exist - it might have been deleted entirely
                    // Create both folder and file
                    let deletedItem = createDeletedFileItem(
                        fullPath: fullPath,
                        name: fileName,
                        featureId: featureId,
                        repoPath: repoPath
                    )
                    let folderUrl = URL(fileURLWithPath: repoPath)
                        .appendingPathComponent(basePath)
                        .appendingPathComponent(folderName)
                    let folder = FeatureFileItem(
                        id: "\(featureId)_deleted_folder_\(folderName)",
                        name: folderName,
                        url: folderUrl,
                        type: .folder,
                        children: [deletedItem],
                        gitStatus: .deleted
                    )
                    result.append(folder)
                }
            } else {
                // File is at the root level of the feature folder
                let deletedItem = createDeletedFileItem(
                    fullPath: fullPath,
                    name: components[0],
                    featureId: featureId,
                    repoPath: repoPath
                )
                result.append(deletedItem)
            }
        }

        return result
    }

    /// Creates a single FeatureFileItem for a deleted file.
    private func createDeletedFileItem(
        fullPath: String,
        name: String,
        featureId: String,
        repoPath: String
    ) -> FeatureFileItem {
        let url = URL(fileURLWithPath: repoPath).appendingPathComponent(fullPath)
        let ext = url.pathExtension.lowercased()

        let type: FeatureFileItem.FileItemType
        switch ext {
        case "json":
            type = .jsonFile(isPrimary: name == "en.json")
        case "png", "jpg", "jpeg", "gif", "webp":
            type = .image
        default:
            type = .otherFile(fileExtension: ext)
        }

        return FeatureFileItem(
            id: "\(featureId)_deleted_\(fullPath)",
            name: name,
            url: url,
            type: type,
            children: [],
            gitStatus: .deleted
        )
    }

    /// Select a key from sidebar (opens new tab or focuses existing)
    func selectKeyFromSidebar(_ key: TranslationKey, in feature: FeatureFolder) {
        // Use the multi-tab approach - always open/focus the key
        openKeyTab(key, in: feature)
    }

    // MARK: - Multi-Tab Management

    /// Open a key in a new tab (or focus if already open)
    func openKeyTab(_ key: TranslationKey, in feature: FeatureFolder) {
        // Check if already open - focus it
        if let existingTab = openTabs.first(where: {
            if case .key(let data) = $0 {
                return data.keyId == key.id
            }
            return false
        }) {
            activeTabId = existingTab.id
            return
        }

        // Create new tab
        let newTab = EditorTab.keyTab(key: key, featureId: feature.id)
        openTabs.append(newTab)
        activeTabId = newTab.id

        // Also set the feature context
        selectedFeature = feature
        translationKeys = featureKeys[feature.id] ?? []
    }

    /// Open an image in a new tab (or focus if already open)
    func openImageTab(_ imageURL: URL, in feature: FeatureFolder) {
        // Check if already open - focus it
        if let existingTab = openTabs.first(where: {
            if case .image(let data) = $0 {
                return data.imageURL == imageURL
            }
            return false
        }) {
            activeTabId = existingTab.id
            return
        }

        // Create new tab
        let newTab = EditorTab.imageTab(url: imageURL, featureId: feature.id)
        openTabs.append(newTab)
        activeTabId = newTab.id
    }

    /// Open a generic file in a new tab (or focus if already open)
    func openGenericFileTab(_ fileURL: URL, iconName: String, in feature: FeatureFolder) {
        // Check if already open - focus it
        if let existingTab = openTabs.first(where: {
            if case .genericFile(let data) = $0 {
                return data.fileURL == fileURL
            }
            return false
        }) {
            activeTabId = existingTab.id
            return
        }

        // Create new tab
        let newTab = EditorTab.genericFileTab(url: fileURL, iconName: iconName, featureId: feature.id)
        openTabs.append(newTab)
        activeTabId = newTab.id
    }

    /// Open a text file in a new tab (or focus if already open)
    func openTextFileTab(_ fileURL: URL, in feature: FeatureFolder) {
        // Check if already open - focus it
        if let existingTab = openTabs.first(where: {
            if case .textFile(let data) = $0 {
                return data.fileURL == fileURL
            }
            return false
        }) {
            activeTabId = existingTab.id
            return
        }

        // Create new tab
        let newTab = EditorTab.textFileTab(url: fileURL, featureId: feature.id)
        openTabs.append(newTab)
        activeTabId = newTab.id
    }

    /// Check if a key is open in any tab
    func isKeyOpen(_ keyId: UUID) -> Bool {
        openTabs.contains {
            if case .key(let data) = $0 {
                return data.keyId == keyId
            }
            return false
        }
    }

    /// Check if an image is open in any tab
    func isImageOpen(_ imageURL: URL) -> Bool {
        openTabs.contains {
            if case .image(let data) = $0 {
                return data.imageURL == imageURL
            }
            return false
        }
    }

    /// Focus a key tab by its ID
    func focusKeyTab(_ tabId: UUID) {
        activeTabId = tabId
    }

    /// Request to close a tab (shows confirmation if unsaved changes)
    func requestCloseTab(_ tabId: UUID) {
        guard let tab = openTabs.first(where: { $0.id == tabId }) else { return }

        // Check if key tab with changes
        if case .key(let data) = tab, data.hasChanges {
            pendingCloseTabId = tabId
            showCloseTabConfirmation = true
        } else {
            closeTab(tabId)
        }
    }

    /// Close a specific tab (no confirmation)
    func closeTab(_ tabId: UUID) {
        openTabs.removeAll { $0.id == tabId }

        // If closed tab was active, activate another
        if activeTabId == tabId {
            activeTabId = openTabs.last?.id
        }
    }

    /// Confirm closing tab with unsaved changes
    func confirmCloseTab() {
        if let tabId = pendingCloseTabId {
            closeTab(tabId)
        }
        pendingCloseTabId = nil
        showCloseTabConfirmation = false
    }

    /// Cancel closing tab
    func cancelCloseTab() {
        pendingCloseTabId = nil
        showCloseTabConfirmation = false
    }

    /// Reorder tabs (for drag-and-drop)
    func moveTab(fromOffsets source: IndexSet, toOffset destination: Int) {
        openTabs.move(fromOffsets: source, toOffset: destination)
    }

    /// Update the edited key in a specific tab
    func updateTabEditedKey(_ tabId: UUID, key: TranslationKey, hasChanges: Bool) {
        guard let index = openTabs.firstIndex(where: { $0.id == tabId }),
              case .key(var keyData) = openTabs[index] else { return }
        keyData.editedKey = key
        keyData.hasChanges = hasChanges
        openTabs[index] = .key(keyData)
    }

    /// Open a new key wizard tab for a feature
    func openNewKeyTab(for feature: FeatureFolder) {
        // Only create new form data if opening for a different feature or no data exists
        if newKeyTabFeature?.id != feature.id || newKeyFormData == nil {
            newKeyFormData = NewKeyFormData()
        }
        showNewKeyTab = true
        newKeyTabFeature = feature
        activeTabId = nil  // New tab is active when activeTabId is nil
    }

    /// Close the new key tab
    func closeNewKeyTab() {
        showNewKeyTab = false
        newKeyTabFeature = nil
        newKeyFormData = nil  // Clear form data when tab is closed
        // Activate the last key tab if any exist
        activeTabId = openTabs.last?.id
    }

    /// Focus the "New" tab
    func focusNewKeyTab() {
        if showNewKeyTab {
            activeTabId = nil
        }
    }

    /// Close all key tabs (used when switching platforms/features)
    func closeAllTabs() {
        openTabs.removeAll()
        activeTabId = nil
        showNewKeyTab = false
        newKeyTabFeature = nil
        newKeyFormData = nil  // Clear form data
    }

    /// Update the edited key in the active tab
    func updateActiveTabKey(_ key: TranslationKey?) {
        guard let tabId = activeTabId else {
            logger.error("updateActiveTabKey: activeTabId is nil")
            stateManagementErrorMessage = "Cannot update key: No active tab. Please close and reopen the translation key."
            showStateManagementError = true
            return
        }

        guard let index = openTabs.firstIndex(where: { $0.id == tabId }) else {
            logger.error("updateActiveTabKey: Tab with ID \(tabId) not found in openTabs")
            stateManagementErrorMessage = "Cannot update key: Tab was closed. Please reopen the translation key."
            showStateManagementError = true
            return
        }

        guard case .key(var keyData) = openTabs[index] else {
            logger.error("updateActiveTabKey: Tab at index \(index) is not a key tab")
            stateManagementErrorMessage = "Cannot update key: Invalid tab type. Please close and reopen the translation key."
            showStateManagementError = true
            return
        }

        keyData.editedKey = key
        openTabs[index] = .key(keyData)
        logger.debug("updateActiveTabKey: Successfully updated key for tab \(tabId)")
    }

    // MARK: - Translation Key Management

    func loadTranslationKeys() async {
        guard let selectedFeature, let fileSystemWorker else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            if fileSystemWorker.fileExists(at: selectedFeature.enJsonURL) {
                translationKeys = try await fileSystemWorker.loadEntities(from: selectedFeature.enJsonURL)
                // Store hash for external change detection
                lastLoadedFileHash = fileSystemWorker.computeFileHash(selectedFeature.enJsonURL)
            } else {
                translationKeys = []
                lastLoadedFileHash = nil
            }
            hasChanges = false

            // Refresh open key tabs that belong to this feature
            for (index, tab) in openTabs.enumerated() {
                if tab.featureId == selectedFeature.id,
                   case .key(var keyData) = tab {
                    if let updatedKey = translationKeys.first(where: { $0.key == keyData.keyName }) {
                        keyData.editedKey = updatedKey
                        openTabs[index] = .key(keyData)
                    } else {
                        // Key was deleted externally - close this tab
                        closeTab(tab.id)
                    }
                }
            }
        } catch {
            translationKeys = []
            lastLoadedFileHash = nil
        }
    }

    // MARK: - External Change Detection

    func checkForExternalChanges() async {
        await refreshGitStatus()
        // Compute diffs for any newly uncommitted features
        await computeDiffsForUncommittedFeatures()
        // Load file items for uncommitted features (enables counter badges before expansion)
        await loadFilesForUncommittedFeatures()
        // DON'T invalidate diff cache here - only invalidate per-feature when reloaded

        guard let externalChangeWorker else { return }

        // Get features that have been loaded (have keys cached)
        let loadedFeatures = features.filter { featureKeys.keys.contains($0.id) }

        // Determine which features have unsaved local changes
        let featuresWithLocalChanges: Set<String> = if let selectedFeature, hasChanges {
            [selectedFeature.id]
        } else {
            []
        }

        // Use worker to detect external changes
        if let change = externalChangeWorker.checkForExternalChanges(
            features: loadedFeatures,
            cachedHashes: featureFileHashes,
            featuresWithLocalChanges: featuresWithLocalChanges
        ) {
            if change.hasLocalConflict {
                // CONFLICT: User has unsaved work that would be lost
                // Prompt for resolution, don't silently overwrite
                pendingExternalChange = ExternalChangeInfo(
                    featureName: change.featureName,
                    filePath: change.filePath
                )
                showExternalChangeConflict = true
                return  // Handle this conflict first
            } else {
                // SAFE: Disk changed but user has no unsaved changes
                // OK to reload silently (no data loss)
                guard let feature = features.first(where: { $0.id == change.featureId }) else { return }

                await loadKeysForFeature(feature)
                // Invalidate diff for this specific feature only
                featureKeyDiffs[change.featureId] = nil
                await computeDiffForFeature(feature)

                // If this was the selected feature, also reload editor copy
                if selectedFeature?.id == change.featureId {
                    await loadTranslationKeys()
                }
            }
        }
    }

    func reloadCurrentFeature() async {
        guard let selectedFeature else { return }

        await loadTranslationKeys()
        // Also update sidebar keys
        await loadKeysForFeature(selectedFeature)
        invalidateDiffCache()
        await computeDiffForFeature(selectedFeature)
        await refreshGitStatus()
    }

    func keepLocalChanges() {
        // User chose to keep their edits
        // Update hash to current disk state so we don't prompt again
        if let selectedFeature, let fileSystemWorker {
            lastLoadedFileHash = fileSystemWorker.computeFileHash(selectedFeature.primaryLanguageFileURL)
            featureFileHashes[selectedFeature.id] = lastLoadedFileHash
        }
        showExternalChangeConflict = false
        pendingExternalChange = nil
    }

    func discardLocalChanges() async {
        showExternalChangeConflict = false
        pendingExternalChange = nil
        hasChanges = false
        await reloadCurrentFeature()
    }

    // MARK: - Discard Operations

    /// Get relative path for a feature's JSON file (for git operations)
    private func relativePath(for feature: FeatureFolder) -> String? {
        guard let repositoryURL else { return nil }
        let fullPath = feature.primaryLanguageFileURL.path
        let repoPath = repositoryURL.path
        guard fullPath.hasPrefix(repoPath) else { return nil }
        return String(fullPath.dropFirst(repoPath.count + 1)) // +1 for the "/"
    }

    /// Discard changes for a single key (restore from git HEAD)
    func discardKeyChanges(_ keyName: String, in feature: FeatureFolder) async {
        guard let gitWorker, let fileSystemWorker else { return }

        isLoading = true
        defer { isLoading = false }

        // Get relative path for the file
        guard let relPath = relativePath(for: feature) else { return }

        // Get original file content from HEAD
        guard let originalData = await gitWorker.getHeadFileContent(relativePath: relPath) else {
            // File doesn't exist in HEAD - key was newly added, just remove it
            translationKeys.removeAll { $0.key == keyName }
            featureKeys[feature.id] = translationKeys

            // Save the file
            do {
                try await fileSystemWorker.saveEntities(translationKeys, to: feature.primaryLanguageFileURL)
            } catch {
                publishErrorMessage = "Failed to save: \(error.localizedDescription)"
                showPublishError = true
            }

            await refreshAfterDiscard(feature: feature)
            return
        }

        // Parse original JSON to get the key's original state
        do {
            let originalKeys = try await fileSystemWorker.loadEntities(from: originalData)
            let diff = getDiff(for: feature)

            if diff.addedKeys.contains(keyName) {
                // Key was added - remove it
                translationKeys.removeAll { $0.key == keyName }
            } else if diff.modifiedKeys.contains(keyName) {
                // Key was modified - restore original
                if let originalKey = originalKeys.first(where: { $0.key == keyName }),
                   let index = translationKeys.firstIndex(where: { $0.key == keyName }) {
                    translationKeys[index] = originalKey
                }
            } else if diff.deletedKeys.contains(keyName) {
                // Key was deleted - restore it
                if let originalKey = originalKeys.first(where: { $0.key == keyName }) {
                    translationKeys.append(originalKey)
                    translationKeys.sort { $0.key < $1.key }
                }
            }

            // Update cache
            featureKeys[feature.id] = translationKeys

            // Save the file
            try await fileSystemWorker.saveEntities(translationKeys, to: feature.primaryLanguageFileURL)

            // Close tab if we discarded its key
            if let tab = openTabs.first(where: {
                if case .key(let data) = $0 {
                    return data.keyName == keyName
                }
                return false
            }) {
                closeTab(tab.id)
            }

            await refreshAfterDiscard(feature: feature)
        } catch {
            publishErrorMessage = "Failed to discard: \(error.localizedDescription)"
            showPublishError = true
        }
    }

    /// Discard all changes in a feature file (restore entire file from git)
    func discardAllChanges(in feature: FeatureFolder) async {
        guard let gitWorker else { return }

        isLoading = true
        defer { isLoading = false }

        // Get relative path for the file
        guard let relPath = relativePath(for: feature) else { return }

        do {
            // Use git restore to revert the file
            try await gitWorker.restoreFile(relativePath: relPath)

            // Close all tabs for this feature
            openTabs.removeAll { $0.featureId == feature.id }
            if let currentTabId = activeTabId, !openTabs.contains(where: { $0.id == currentTabId }) {
                activeTabId = openTabs.last?.id
            }

            // Reload the feature's keys
            await loadKeysForFeature(feature)

            // If this was the selected feature, reload translation keys too
            if selectedFeature?.id == feature.id {
                await loadTranslationKeys()
            }

            await refreshAfterDiscard(feature: feature)
        } catch {
            publishErrorMessage = "Failed to discard: \(error.localizedDescription)"
            showPublishError = true
        }
    }

    /// Common refresh after discard operations
    private func refreshAfterDiscard(feature: FeatureFolder) async {
        hasChanges = false

        // Update hash to current disk state
        featureFileHashes[feature.id] = fileSystemWorker?.computeFileHash(feature.primaryLanguageFileURL)

        await refreshGitStatus()
        invalidateDiffCache()
        await computeDiffForFeature(feature)

        // Clear discard state
        keyToDiscard = nil
        featureToDiscard = nil
        showDiscardKeyConfirmation = false
        showDiscardAllConfirmation = false
        fileToDiscard = nil
        showDiscardFileConfirmation = false
    }

    /// Discard changes for a file (added, modified, or deleted)
    func discardFileChanges() async {
        guard let (file, feature) = fileToDiscard,
              let gitWorker else {
            fileToDiscard = nil
            showDiscardFileConfirmation = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            switch file.gitStatus {
            case .added:
                // Untracked file - delete from disk
                try FileManager.default.removeItem(at: file.url)

            case .modified:
                // Restore modified file from git
                guard let repositoryURL else { return }
                let relativePath = file.url.path.replacingOccurrences(
                    of: repositoryURL.path + "/",
                    with: ""
                )
                try await gitWorker.restoreFile(relativePath: relativePath)

            case .deleted:
                // Restore deleted file - use --staged --worktree to handle both
                // staged and unstaged deletions
                guard let repositoryURL else { return }
                let relativePath = file.url.path.replacingOccurrences(
                    of: repositoryURL.path + "/",
                    with: ""
                )
                try await gitWorker.restoreDeletedFile(relativePath: relativePath)

            case .unchanged:
                break
            }

            // Close any open tab for this file
            if let tabIndex = openTabs.firstIndex(where: {
                if case .image(let data) = $0 {
                    return data.imageURL == file.url
                }
                return false
            }) {
                closeTab(openTabs[tabIndex].id)
            }

            // Refresh
            await refreshAfterFileDiscard(for: feature)

        } catch {
            publishErrorMessage = "Failed to discard file: \(error.localizedDescription)"
            showPublishError = true
        }

        fileToDiscard = nil
        showDiscardFileConfirmation = false
    }

    /// Refresh after file discard operations
    private func refreshAfterFileDiscard(for feature: FeatureFolder) async {
        // Refresh git status
        await refreshGitStatus()

        // Reload file items for this feature
        await loadFilesForFeature(feature)

        // Also refresh the feature diff
        invalidateDiffCache()
        await computeDiffForFeature(feature)
    }

    // MARK: - Permanent Delete Operations

    /// Permanently delete a file from disk
    func deleteFile() async {
        guard let (file, feature) = fileToDelete else {
            fileToDelete = nil
            showDeleteFileConfirmation = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try FileManager.default.removeItem(at: file.url)

            // Close any open tab for this file
            closeTabsForFile(file.url)

            // Refresh
            await refreshAfterFileDiscard(for: feature)

        } catch {
            publishErrorMessage = "Failed to delete file: \(error.localizedDescription)"
            showPublishError = true
        }

        fileToDelete = nil
        showDeleteFileConfirmation = false
    }

    /// Permanently delete a folder and all its contents from disk
    func deleteFolder() async {
        guard let (folder, feature) = folderToDelete else {
            folderToDelete = nil
            showDeleteFolderConfirmation = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try FileManager.default.removeItem(at: folder.url)

            // Close any open tabs for files in this folder
            closeTabsInFolder(folder.url)

            // Refresh
            await refreshAfterFileDiscard(for: feature)

        } catch {
            publishErrorMessage = "Failed to delete folder: \(error.localizedDescription)"
            showPublishError = true
        }

        folderToDelete = nil
        showDeleteFolderConfirmation = false
    }

    /// Close tabs for a specific file URL
    private func closeTabsForFile(_ fileURL: URL) {
        let tabsToClose = openTabs.filter { tab in
            switch tab {
            case .image(let data): return data.imageURL == fileURL
            case .textFile(let data): return data.fileURL == fileURL
            case .genericFile(let data): return data.fileURL == fileURL
            case .key: return false
            }
        }
        for tab in tabsToClose {
            closeTab(tab.id)
        }
    }

    /// Close tabs for files within a folder
    private func closeTabsInFolder(_ folderURL: URL) {
        let folderPath = folderURL.path
        let tabsToClose = openTabs.filter { tab in
            switch tab {
            case .image(let data): return data.imageURL.path.hasPrefix(folderPath)
            case .textFile(let data): return data.fileURL.path.hasPrefix(folderPath)
            case .genericFile(let data): return data.fileURL.path.hasPrefix(folderPath)
            case .key: return false
            }
        }
        for tab in tabsToClose {
            closeTab(tab.id)
        }
    }

    /// Permanently delete a localization key from the JSON file
    func deleteLocalization() async {
        guard let (keyName, feature) = localizationKeyToDelete,
              let fileSystemWorker else {
            localizationKeyToDelete = nil
            showDeleteLocalizationConfirmation = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Remove the key from translationKeys if this is the selected feature
            if selectedFeature?.id == feature.id {
                translationKeys.removeAll { $0.key == keyName }
            }

            // Remove from featureKeys cache
            featureKeys[feature.id]?.removeAll { $0.key == keyName }

            // Close any open tab for this key
            let tabsToClose = openTabs.filter { tab in
                if case .key(let data) = tab {
                    return data.keyName == keyName && data.featureId == feature.id
                }
                return false
            }
            for tab in tabsToClose {
                closeTab(tab.id)
            }

            // Save the updated keys to the file
            let fileURL = feature.primaryLanguageFileURL
            let keysToSave = featureKeys[feature.id] ?? translationKeys
            try await fileSystemWorker.saveEntities(keysToSave, to: fileURL)

            // Update file hash
            featureFileHashes[feature.id] = fileSystemWorker.computeFileHash(fileURL)

            // Refresh
            await refreshGitStatus()
            invalidateDiffCache()
            await computeDiffForFeature(feature)

        } catch {
            publishErrorMessage = "Failed to delete localization: \(error.localizedDescription)"
            showPublishError = true
        }

        localizationKeyToDelete = nil
        showDeleteLocalizationConfirmation = false
    }

    func createNewKey() {
        let newKey = TranslationKey(isNew: true)
        translationKeys.append(newKey)
        // In multi-tab system, open a tab for the new key
        if let feature = selectedFeature {
            openKeyTab(newKey, in: feature)
        }
        hasChanges = true
    }

    func updateKey(_ key: TranslationKey) {
        if let index = translationKeys.firstIndex(where: { $0.id == key.id }) {
            translationKeys[index] = key
            // Update the active tab's editedKey
            updateActiveTabKey(key)
            hasChanges = true

            // Also update the featureKeys cache
            if let featureId = selectedFeature?.id {
                featureKeys[featureId] = translationKeys
            }
        }
    }

    /// Check if a key name already exists (excluding the current key being edited)
    func isKeyDuplicate(_ keyName: String, excludingId: UUID) -> Bool {
        translationKeys.contains { $0.key == keyName && $0.id != excludingId }
    }

    /// Validate key name and return error message if invalid
    func validateKeyName(_ keyName: String, excludingId: UUID) -> String? {
        if keyName.isEmpty {
            return "Key name is required"
        }

        if !configuration.isValidKeyName(keyName) {
            return "Key must start with a letter and contain only letters, numbers, and underscores"
        }

        if isKeyDuplicate(keyName, excludingId: excludingId) {
            return "A key with this name already exists"
        }

        return nil
    }

    func deleteKey(_ key: TranslationKey) {
        translationKeys.removeAll { $0.id == key.id }
        // Close the tab for the deleted key if it's open
        if let tabToClose = openTabs.first(where: {
            if case .key(let data) = $0 {
                return data.keyId == key.id
            }
            return false
        }) {
            closeTab(tabToClose.id)
        }
    }

    // MARK: - Screenshot Management

    func addScreenshot(from url: URL) {
        guard let selectedFeature else { return }

        let screenshot = PendingScreenshot(
            originalURL: url,
            destinationFolder: selectedFeature.assetsFolderURL
        )
        pendingScreenshots.append(screenshot)
        hasChanges = true
    }

    func removeScreenshot(_ screenshot: PendingScreenshot) {
        pendingScreenshots.removeAll { $0.id == screenshot.id }
    }

    /// Generate screenshot name with collision detection (DD_MM_YYYY.png, DD_MM_YYYY_2.png, etc.)
    func generateScreenshotName() -> String {
        guard let selectedFeature else { return "screenshot.png" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd_MM_yyyy"
        let dateString = dateFormatter.string(from: Date())

        let imagesFolder = selectedFeature.assetsFolderURL
        let fileManager = FileManager.default

        // Check base name first
        let baseName = "\(dateString).png"
        let basePath = imagesFolder.appendingPathComponent(baseName).path

        // Also check pending screenshots for collisions
        let pendingNames = Set(pendingScreenshots.map { $0.renamedName })

        if !fileManager.fileExists(atPath: basePath) && !pendingNames.contains(baseName) {
            return baseName
        }

        // Find next available number
        var counter = 2
        while true {
            let numberedName = "\(dateString)_\(counter).png"
            let numberedPath = imagesFolder.appendingPathComponent(numberedName).path

            if !fileManager.fileExists(atPath: numberedPath) && !pendingNames.contains(numberedName) {
                return numberedName
            }
            counter += 1

            // Safety limit
            if counter > 100 {
                return "\(dateString)_\(UUID().uuidString.prefix(8)).png"
            }
        }
    }

    // MARK: - Save Operations

    /// Saves the current file to disk.
    ///
    /// - Parameter forceOverwrite: If `true`, overwrites the file even if it was modified externally.
    ///                             Use this after user confirms they want to overwrite.
    /// - Throws: `FileOperationError` if save fails for any reason
    func saveCurrentFile(forceOverwrite: Bool = false) async throws {
        guard let selectedFeature else {
            throw FileOperationError.noFeatureSelected
        }
        guard let fileSystemWorker else {
            throw FileOperationError.fileSystemNotInitialized
        }

        let fileURL = selectedFeature.primaryLanguageFileURL

        // Check if file still exists before saving
        guard fileSystemWorker.fileExists(at: fileURL) else {
            throw FileOperationError.fileDeleted(path: fileURL.path)
        }

        // Check for external modifications (unless force overwrite)
        if !forceOverwrite,
           let lastHash = featureFileHashes[selectedFeature.id],
           fileSystemWorker.hasFileChanged(at: fileURL, since: lastHash) {
            throw FileOperationError.externallyModified(path: fileURL.path)
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Save translation keys
            try await fileSystemWorker.saveEntities(translationKeys, to: fileURL)

            // Import screenshots
            for screenshot in pendingScreenshots {
                try await fileSystemWorker.importScreenshot(
                    from: screenshot.originalURL,
                    to: screenshot.destinationURL
                )
            }

            pendingScreenshots = []
            hasChanges = false

            // Update hash to reflect the new disk state
            featureFileHashes[selectedFeature.id] = fileSystemWorker.computeFileHash(fileURL)

            // Also update sidebar keys cache
            featureKeys[selectedFeature.id] = translationKeys

            // Refresh git status, invalidate diff cache, and recompute diff for current feature
            await refreshGitStatus()
            invalidateDiffCache()

            // Recompute diff for the currently selected feature so UI updates
            await computeDiffForFeature(selectedFeature)
        } catch let error as FileOperationError {
            throw error
        } catch {
            throw FileOperationError.saveFailed(underlying: error.localizedDescription)
        }
    }
}

// MARK: - GitPublishable Conformance

extension AppStore: GitPublishable {
    func saveAllModifications() async throws {
        // Localization Editor saves current file only
        try await saveCurrentFile()
    }

    func generateCommitMessage() -> String {
        let features = uncommittedFeatures.map { $0.name }.joined(separator: ", ")
        if features.isEmpty {
            // Fallback to current feature if no uncommitted features detected
            return "Add/update translations for \(selectedFeature?.name ?? "feature")"
        }
        return "Add/update translations for [\(features)]"
    }

    func generatePRTitle() -> String {
        let count = uncommittedFeatures.count
        if count == 0 {
            // Fallback for when no uncommitted features detected
            return "feat: Update translations"
        }
        return "feat: Update translations for \(count) feature\(count == 1 ? "" : "s")"
    }

    func generatePRBody() -> String {
        let features = uncommittedFeatures.map { $0.name }.sorted()
        if features.isEmpty {
            // Fallback for when no uncommitted features detected
            return """
            ## Summary
            - Updated translation keys in \(selectedFeature?.name ?? "feature")
            - Screenshot attached

            ---
            Created with DHOpsTools Localization Editor
            """
        }
        return """
        ## Summary
        - Updated translations for: \(features.joined(separator: ", "))

        ## Changes
        \(features.map { "- \($0)" }.joined(separator: "\n"))

        ---
        Created with DHOpsTools Localization Editor
        """
    }

    func refreshAfterGitOperation() async {
        await refreshGitStatus()
        invalidateDiffCache()
        await refreshSidebarFileStatuses()
        await computeDiffsForUncommittedFeatures()
    }

    /// Refreshes git statuses for all loaded sidebar file items
    private func refreshSidebarFileStatuses() async {
        // Capture feature IDs that need refreshing (before clearing)
        let featureIdsToRefresh = Array(featureFiles.keys)

        // Clear the cached file items to force fresh git status query
        for featureId in featureIdsToRefresh {
            featureFiles[featureId] = []
        }

        // Reload files with fresh git statuses
        for featureId in featureIdsToRefresh {
            guard let feature = features.first(where: { $0.id == featureId }) else { continue }
            await loadFilesForFeature(feature)
        }
    }

    /// Reloads features after git operations
    func reloadDataAfterGitOperation() async {
        await loadFeatures()
    }

    /// Cleans up UI state after discard all
    func cleanupStateAfterDiscardAll() async {
        // Close all tabs since all changes are discarded
        openTabs.removeAll()
        activeTabId = nil
        editedKey = nil

        // Clear selection to force reload
        selectedFeature = nil
    }
}
