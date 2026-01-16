import Foundation

/// Computes diffs between HEAD and the working directory.
///
/// DiffWorker compares the current state of files in the working directory
/// against the last committed version (HEAD) to identify added, modified,
/// and deleted entities.
public actor DiffWorker {

    private let gitWorker: GitWorker
    private let repositoryURL: URL

    public init(repositoryURL: URL, gitWorker: GitWorker) {
        self.repositoryURL = repositoryURL
        self.gitWorker = gitWorker
    }

    // MARK: - Diff Computation

    /// Computes the diff for a feature folder's primary language file.
    /// Marked nonisolated to allow parallel execution from TaskGroup.
    public nonisolated func computeDiff(for feature: FeatureFolder) async -> EntityDiff {
        let fileURL = feature.primaryLanguageFileURL
        let repoPath = repositoryURL.path
        let relativePath = fileURL.path.replacingOccurrences(of: repoPath + "/", with: "")

        // Load current working directory version
        let currentKeys: [String: [String: Any]]
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                currentKeys = try loadJsonAsDictionary(from: fileURL)
            } catch {
                // Can't parse current file, return empty diff
                return .empty
            }
        } else {
            // File deleted from working directory
            if let headData = await gitWorker.getHeadFileContent(relativePath: relativePath),
               let headKeys = try? parseJsonData(headData) {
                return EntityDiff(
                    featureId: feature.id,
                    filePath: relativePath,
                    addedKeys: [],
                    modifiedKeys: [],
                    deletedKeys: Set(headKeys.keys),
                    isNewFile: false,
                    isDeletedFile: true
                )
            }
            return .empty
        }

        // Load HEAD version
        let headData = await gitWorker.getHeadFileContent(relativePath: relativePath)

        guard let headData, let headKeys = try? parseJsonData(headData) else {
            // New file - all keys are added
            return EntityDiff(
                featureId: feature.id,
                filePath: relativePath,
                addedKeys: Set(currentKeys.keys),
                modifiedKeys: [],
                deletedKeys: [],
                isNewFile: true,
                isDeletedFile: false
            )
        }

        // Compute diff between HEAD and current
        return computeKeyDiff(
            featureId: feature.id,
            filePath: relativePath,
            headKeys: headKeys,
            currentKeys: currentKeys
        )
    }

    // MARK: - Private Helpers

    private nonisolated func loadJsonAsDictionary(from url: URL) throws -> [String: [String: Any]] {
        let data = try Data(contentsOf: url)
        return try parseJsonData(data)
    }

    private nonisolated func parseJsonData(_ data: Data) throws -> [String: [String: Any]] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }

        var result: [String: [String: Any]] = [:]
        for (key, value) in json {
            if let dict = value as? [String: Any] {
                result[key] = dict
            }
        }
        return result
    }

    private nonisolated func computeKeyDiff(
        featureId: String,
        filePath: String,
        headKeys: [String: [String: Any]],
        currentKeys: [String: [String: Any]]
    ) -> EntityDiff {
        let headKeyNames = Set(headKeys.keys)
        let currentKeyNames = Set(currentKeys.keys)

        // Added: in current but not in HEAD
        let addedKeys = currentKeyNames.subtracting(headKeyNames)

        // Deleted: in HEAD but not in current
        let deletedKeys = headKeyNames.subtracting(currentKeyNames)

        // Modified: in both but with different values
        let commonKeys = headKeyNames.intersection(currentKeyNames)
        var modifiedKeys = Set<String>()

        for keyName in commonKeys {
            guard let headValue = headKeys[keyName],
                  let currentValue = currentKeys[keyName] else {
                continue
            }

            if !dictionariesAreEqual(headValue, currentValue) {
                modifiedKeys.insert(keyName)
            }
        }

        return EntityDiff(
            featureId: featureId,
            filePath: filePath,
            addedKeys: addedKeys,
            modifiedKeys: modifiedKeys,
            deletedKeys: deletedKeys
        )
    }

    /// Compares two dictionaries for equality (handles nested values).
    private nonisolated func dictionariesAreEqual(_ dict1: [String: Any], _ dict2: [String: Any]) -> Bool {
        guard dict1.count == dict2.count else { return false }

        for (key, value1) in dict1 {
            guard let value2 = dict2[key] else { return false }

            switch (value1, value2) {
            case (let s1 as String, let s2 as String):
                if s1 != s2 { return false }
            case (let i1 as Int, let i2 as Int):
                if i1 != i2 { return false }
            case (let a1 as [String], let a2 as [String]):
                if a1 != a2 { return false }
            case (let d1 as [String: Any], let d2 as [String: Any]):
                if !dictionariesAreEqual(d1, d2) { return false }
            default:
                // For other types, convert to string and compare
                if String(describing: value1) != String(describing: value2) {
                    return false
                }
            }
        }

        return true
    }
}
