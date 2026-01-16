import Foundation

/// Result of checking for external changes to a feature file.
public struct ExternalChangeResult: Sendable {
    /// Feature ID that was externally modified
    public let featureId: String

    /// Display name for the feature
    public let featureName: String

    /// Path to the modified file
    public let filePath: String

    /// Whether user has unsaved local changes (conflict)
    public let hasLocalConflict: Bool

    public init(featureId: String, featureName: String, filePath: String, hasLocalConflict: Bool) {
        self.featureId = featureId
        self.featureName = featureName
        self.filePath = filePath
        self.hasLocalConflict = hasLocalConflict
    }
}

/// Detects external modifications to feature files.
///
/// Compares current disk state against cached hashes to identify
/// files that were modified outside the application.
///
/// ## Usage
/// ```swift
/// let worker = ExternalChangeWorker(fileSystemWorker: fsWorker)
/// if let conflict = await worker.checkForExternalChanges(
///     features: loadedFeatures,
///     cachedHashes: featureFileHashes,
///     featuresWithLocalChanges: modifiedFeatureIds
/// ) {
///     // Handle conflict or safe reload
/// }
/// ```
public actor ExternalChangeWorker {

    private let fileSystemWorker: FileSystemWorker

    public init(fileSystemWorker: FileSystemWorker) {
        self.fileSystemWorker = fileSystemWorker
    }

    /// Checks all features for external changes.
    ///
    /// Returns the first external change found. If the feature has local unsaved changes,
    /// this is a conflict requiring user resolution. Otherwise, it's safe to reload.
    ///
    /// - Parameters:
    ///   - features: Features to check
    ///   - cachedHashes: Previously computed file hashes keyed by feature ID
    ///   - featuresWithLocalChanges: Set of feature IDs with unsaved local changes
    /// - Returns: First external change found, or nil if no external changes detected
    public nonisolated func checkForExternalChanges(
        features: [FeatureFolder],
        cachedHashes: [String: String],
        featuresWithLocalChanges: Set<String>
    ) -> ExternalChangeResult? {

        for feature in features {
            let fileURL = feature.primaryLanguageFileURL
            let currentDiskHash = fileSystemWorker.computeFileHash(fileURL)
            let lastLoadedHash = cachedHashes[feature.id]

            // Skip if disk unchanged (same hash)
            guard currentDiskHash != lastLoadedHash else {
                continue
            }

            // Disk changed externally
            let hasLocalConflict = featuresWithLocalChanges.contains(feature.id)

            return ExternalChangeResult(
                featureId: feature.id,
                featureName: feature.displayName,
                filePath: fileURL.path,
                hasLocalConflict: hasLocalConflict
            )
        }

        return nil
    }

    /// Returns all features that were modified externally.
    ///
    /// - Parameters:
    ///   - features: Features to check
    ///   - cachedHashes: Previously computed file hashes keyed by feature ID
    /// - Returns: Array of features whose files changed on disk
    public nonisolated func getExternallyModifiedFeatures(
        features: [FeatureFolder],
        cachedHashes: [String: String]
    ) -> [FeatureFolder] {

        features.filter { feature in
            let fileURL = feature.primaryLanguageFileURL
            let currentDiskHash = fileSystemWorker.computeFileHash(fileURL)
            let lastLoadedHash = cachedHashes[feature.id]
            return currentDiskHash != lastLoadedHash
        }
    }

    /// Returns features that can be safely reloaded (externally modified but no local changes).
    ///
    /// - Parameters:
    ///   - features: Features to check
    ///   - cachedHashes: Previously computed file hashes keyed by feature ID
    ///   - featuresWithLocalChanges: Set of feature IDs with unsaved local changes
    /// - Returns: Features that changed externally but have no local conflicts
    public nonisolated func getSafelyReloadableFeatures(
        features: [FeatureFolder],
        cachedHashes: [String: String],
        featuresWithLocalChanges: Set<String>
    ) -> [FeatureFolder] {

        features.filter { feature in
            let fileURL = feature.primaryLanguageFileURL
            let currentDiskHash = fileSystemWorker.computeFileHash(fileURL)
            let lastLoadedHash = cachedHashes[feature.id]

            // Only include if disk changed AND no local conflict
            return currentDiskHash != lastLoadedHash &&
                   !featuresWithLocalChanges.contains(feature.id)
        }
    }

    /// Returns features that have conflicts (externally modified AND have local changes).
    ///
    /// - Parameters:
    ///   - features: Features to check
    ///   - cachedHashes: Previously computed file hashes keyed by feature ID
    ///   - featuresWithLocalChanges: Set of feature IDs with unsaved local changes
    /// - Returns: Features that changed externally AND have local unsaved changes
    public nonisolated func getConflictingFeatures(
        features: [FeatureFolder],
        cachedHashes: [String: String],
        featuresWithLocalChanges: Set<String>
    ) -> [FeatureFolder] {

        features.filter { feature in
            let fileURL = feature.primaryLanguageFileURL
            let currentDiskHash = fileSystemWorker.computeFileHash(fileURL)
            let lastLoadedHash = cachedHashes[feature.id]

            // Include if disk changed AND has local conflict
            return currentDiskHash != lastLoadedHash &&
                   featuresWithLocalChanges.contains(feature.id)
        }
    }
}
