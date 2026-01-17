import SwiftUI
import Observation
import DHBootlegToolkitCore

// MARK: - JSON Tree View Model

/// View model for virtualized JSON tree rendering
/// Flattens the tree structure for use with LazyVStack
@Observable
final class JSONTreeViewModel {
    // MARK: - Published State

    /// Flattened nodes for rendering (only includes visible nodes)
    private(set) var flattenedNodes: [FlattenedNode] = []

    /// Currently expanded paths
    private(set) var expandedPaths: Set<String> = []

    /// Whether all nodes are currently expanded (for toggle button state)
    /// Marked as @ObservationIgnored to prevent triggering view updates during configuration
    @ObservationIgnored
    private(set) var isAllExpanded: Bool = true

    /// Current search match path
    var currentMatchPath: [String]? = nil {
        didSet {
            if currentMatchPath != oldValue {
                rebuildFlattenedNodes()
            }
        }
    }

    /// Paths that should be expanded due to search
    var searchExpandedPaths: Set<String> = [] {
        didSet {
            if searchExpandedPaths != oldValue {
                rebuildFlattenedNodes()
            }
        }
    }

    // MARK: - Source Data

    /// The source JSON data
    private var json: [String: Any] = [:]

    /// Whether to expand all nodes by default
    private var expandAllByDefault: Bool = true

    /// Manually collapsed paths (user explicitly collapsed)
    private var manuallyCollapsed: Set<String> = []

    /// Original JSON from git HEAD (for change tracking)
    private var originalJSON: [String: Any]?

    /// Git status of the file itself (A/M/D/unchanged)
    private var fileGitStatus: GitFileStatus? = nil

    /// Set of paths that were explicitly edited by the user
    private var editedPaths: Set<String> = []

    /// Change status for each path compared to git HEAD (only includes changed paths)
    internal private(set) var pathChangeStatus: [String: JSONChangeStatus] = [:]

    /// Whether to show only changed fields
    private var showChangedFieldsOnly: Bool = false

    /// Cached set of visible paths when filtering by changes
    private var cachedVisiblePaths: Set<String>? = nil

    // MARK: - Schema State

    /// The JSON Schema for validation and field descriptions
    private var schema: JSONSchema? = nil

    /// Validation errors by path
    private var validationErrors: [String: ValidationError] = [:]

    // MARK: - Initialization

    init() {}

    // MARK: - Configuration

    /// Configure the view model with JSON data
    /// - Parameters:
    ///   - json: The current JSON data to display
    ///   - expandAllByDefault: Whether to expand all nodes by default
    ///   - manuallyCollapsed: Set of paths that were manually collapsed by the user
    ///   - originalJSON: The original JSON from git HEAD for change tracking (nil = no diff)
    ///   - fileGitStatus: The git status of the file itself (for applying file-level status to all fields)
    ///   - hasInMemoryChanges: Whether the file has been edited in memory (affects how deleted/added files are handled)
    ///   - editedPaths: Set of paths that were explicitly edited by the user (for hybrid badge computation)
    ///   - showChangedFieldsOnly: Whether to filter the tree to show only changed fields
    ///   - schema: The JSON Schema for validation and field descriptions
    ///   - validationResult: The validation result for this JSON
    func configure(
        json: [String: Any],
        expandAllByDefault: Bool = true,
        manuallyCollapsed: Set<String> = [],
        originalJSON: [String: Any]? = nil,
        fileGitStatus: GitFileStatus? = nil,
        hasInMemoryChanges: Bool = false,
        editedPaths: Set<String> = [],
        showChangedFieldsOnly: Bool = false,
        schema: JSONSchema? = nil,
        validationResult: JSONSchemaValidationResult? = nil
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()

        self.json = json
        self.expandAllByDefault = expandAllByDefault
        self.manuallyCollapsed = manuallyCollapsed
        self.originalJSON = originalJSON
        self.fileGitStatus = fileGitStatus
        self.editedPaths = editedPaths
        self.showChangedFieldsOnly = showChangedFieldsOnly
        self.schema = schema

        // Build validation errors map keyed by path
        // Note: Multiple errors can exist for the same path, so we use uniquingKeysWith to keep the first error
        if let result = validationResult {
            self.validationErrors = Dictionary(
                result.errors.map { error in (error.pathString, error) },
                uniquingKeysWith: { first, _ in first }
            )
        } else {
            self.validationErrors = [:]
        }

        // Compute change status with hybrid approach
        if let fileStatus = fileGitStatus, (fileStatus == .deleted || fileStatus == .added) {
            // Hybrid mode: combine file-wide status with per-field diff for edited paths
            pathChangeStatus = computeHybridChangeStatus(
                json: json,
                fileStatus: fileStatus,
                originalJSON: originalJSON,
                editedPaths: editedPaths
            )
        } else if let original = originalJSON {
            // Standard per-field diff for modified/unchanged files
            pathChangeStatus = JSONDiffUtility.computeChanges(current: json, original: original)
        } else {
            pathChangeStatus = [:]
        }

        // Cache visible paths if filtering
        if showChangedFieldsOnly {
            cachedVisiblePaths = computeVisiblePathsForChangeFilter()
        } else {
            cachedVisiblePaths = nil
        }

        // Initialize expanded paths based on default behavior
        var pathDuration: TimeInterval = 0
        if expandAllByDefault {
            let pathStart = CFAbsoluteTimeGetCurrent()
            expandedPaths = collectAllExpandablePaths(from: json, parentPath: [])
            // Also collect paths from originalJSON to include deleted fields
            if let original = originalJSON {
                expandedPaths.formUnion(collectAllExpandablePaths(from: original, parentPath: []))
            }
            // Remove manually collapsed
            expandedPaths.subtract(manuallyCollapsed)
            pathDuration = CFAbsoluteTimeGetCurrent() - pathStart
        } else {
            expandedPaths = []
        }

        let rebuildStart = CFAbsoluteTimeGetCurrent()
        rebuildFlattenedNodes()
        let rebuildDuration = CFAbsoluteTimeGetCurrent() - rebuildStart

        let totalDuration = CFAbsoluteTimeGetCurrent() - startTime

        // Capture values for async logging to avoid data races
        let pathCount = expandedPaths.count
        let nodeCount = flattenedNodes.count

        // Log timing summaries
        Task { @MainActor in
            AppLogger.shared.timingSummary("collectAllExpandablePaths (\(pathCount) paths)", duration: pathDuration)
            AppLogger.shared.timingSummary("rebuildFlattenedNodes (\(nodeCount) nodes)", duration: rebuildDuration)
            AppLogger.shared.timingSummary("TreeVM Configure Total", duration: totalDuration)
        }
    }

    /// Reset state when switching to a new country/JSON
    func reset() {
        json = [:]
        expandedPaths = []
        manuallyCollapsed = []
        searchExpandedPaths = []
        currentMatchPath = nil
        flattenedNodes = []
        originalJSON = nil
        fileGitStatus = nil
        editedPaths = []
        pathChangeStatus = [:]
        showChangedFieldsOnly = false
        cachedVisiblePaths = nil
    }

    /// Computes change status for all paths when the entire file has a git status
    /// Used when file is deleted or added - all fields get the same status
    private func computeFileWideChangeStatus(json: [String: Any], status: GitFileStatus) -> [String: JSONChangeStatus] {
        var result: [String: JSONChangeStatus] = [:]
        let changeStatus: JSONChangeStatus = status == .deleted ? .deleted : .added

        func traverse(_ value: Any, path: [String]) {
            let pathString = path.joined(separator: ".")
            result[pathString] = changeStatus

            if let dict = value as? [String: Any] {
                for (key, childValue) in dict {
                    traverse(childValue, path: path + [key])
                }
            } else if let array = value as? [Any] {
                for (index, childValue) in array.enumerated() {
                    traverse(childValue, path: path + ["[\(index)]"])
                }
            }
        }

        // Traverse all top-level keys
        for (key, value) in json {
            traverse(value, path: [key])
        }

        return result
    }

    /// Computes hybrid change status for deleted/added files with some edited fields
    /// - Edited paths: Compare with git HEAD (per-field diff)
    /// - Unedited paths: Show file status ([D] or [A])
    private func computeHybridChangeStatus(
        json: [String: Any],
        fileStatus: GitFileStatus,
        originalJSON: [String: Any]?,
        editedPaths: Set<String>
    ) -> [String: JSONChangeStatus] {
        var result: [String: JSONChangeStatus] = [:]

        // Default status for unedited fields
        let fileChangeStatus: JSONChangeStatus = fileStatus == .deleted ? .deleted : .added

        // Compute per-field diff if we have original JSON
        let diffStatuses = originalJSON != nil ?
            JSONDiffUtility.computeChanges(current: json, original: originalJSON!) : [:]

        // Helper to traverse deleted nodes (only in original, not in current)
        func traverseDeleted(_ value: Any, path: [String]) {
            let pathString = path.joined(separator: ".")
            result[pathString] = .deleted

            // Recurse into children of deleted nodes
            if let dict = value as? [String: Any] {
                for (key, childValue) in dict {
                    traverseDeleted(childValue, path: path + [key])
                }
            } else if let array = value as? [Any] {
                for (index, childValue) in array.enumerated() {
                    traverseDeleted(childValue, path: path + ["[\(index)]"])
                }
            }
        }

        func traverse(_ value: Any, path: [String], existsInOriginal: Bool) {
            let pathString = path.joined(separator: ".")

            // Check if this path or any parent path was edited
            let wasEdited = editedPaths.contains { editedPath in
                pathString == editedPath || pathString.hasPrefix(editedPath + ".")
            }

            if wasEdited {
                // Use per-field diff status for edited paths
                result[pathString] = diffStatuses[pathString] ?? .unchanged
            } else {
                // Use file status for unedited paths
                result[pathString] = fileChangeStatus
            }

            // Recurse into children (OPTIMIZED: only traverse deleted subtrees, not all of original)
            if let dict = value as? [String: Any] {
                let originalDict = getOriginalValue(at: path) as? [String: Any]

                // Traverse current keys
                for (key, childValue) in dict {
                    let childExistsInOriginal = originalDict?[key] != nil
                    traverse(childValue, path: path + [key], existsInOriginal: childExistsInOriginal)
                }

                // Traverse ONLY missing keys from original (lazy approach)
                if let orig = originalDict {
                    for (key, origValue) in orig where dict[key] == nil {
                        traverseDeleted(origValue, path: path + [key])
                    }
                }
            } else if let array = value as? [Any] {
                let originalArray = getOriginalValue(at: path) as? [Any]

                // Traverse current array elements
                for (index, childValue) in array.enumerated() {
                    let childPath = path + ["[\(index)]"]
                    let childExistsInOriginal = originalArray?.indices.contains(index) ?? false
                    traverse(childValue, path: childPath, existsInOriginal: childExistsInOriginal)
                }

                // Traverse ONLY missing elements from original (lazy approach)
                if let orig = originalArray, orig.count > array.count {
                    for index in array.count..<orig.count {
                        traverseDeleted(orig[index], path: path + ["[\(index)]"])
                    }
                }
            }
        }

        // Traverse union of keys from both current and original JSON
        var allKeys = Set(json.keys)
        if let original = originalJSON {
            allKeys.formUnion(original.keys)
        }

        for key in allKeys {
            let currentValue = json[key]
            let originalValue = originalJSON?[key]

            if let value = currentValue {
                // Field exists in current JSON
                traverse(value, path: [key], existsInOriginal: originalValue != nil)
            } else if let value = originalValue {
                // Field exists only in original (deleted)
                traverseDeleted(value, path: [key])
            }
        }

        return result
    }

    // MARK: - Expansion Control

    /// Toggle expansion state for a path
    func toggleExpand(_ pathString: String) {
        if expandedPaths.contains(pathString) {
            // Collapsing
            expandedPaths.remove(pathString)
            manuallyCollapsed.insert(pathString)
        } else {
            // Expanding
            expandedPaths.insert(pathString)
            manuallyCollapsed.remove(pathString)
        }
        rebuildFlattenedNodes()
    }

    /// Check if a path is expanded
    func isExpanded(_ pathString: String) -> Bool {
        // Search expansion takes priority
        if searchExpandedPaths.contains(pathString) {
            return true
        }
        return expandedPaths.contains(pathString)
    }

    /// Get the set of manually collapsed paths (for persistence)
    func getManuallyCollapsed() -> Set<String> {
        manuallyCollapsed
    }

    /// Set manually collapsed paths (for restoration)
    func setManuallyCollapsed(_ collapsed: Set<String>) {
        manuallyCollapsed = collapsed
        expandedPaths.subtract(collapsed)
        rebuildFlattenedNodes()
    }

    /// Expand all expandable paths in the tree
    func expandAll() {
        manuallyCollapsed.removeAll()
        expandedPaths = collectAllExpandablePaths(from: json, parentPath: [])
        // Also collect paths from originalJSON to include deleted fields
        if let original = originalJSON {
            expandedPaths.formUnion(collectAllExpandablePaths(from: original, parentPath: []))
        }
        isAllExpanded = true
        rebuildFlattenedNodes()
    }

    /// Collapse all paths except root level (depth 0)
    /// Root-level paths have no dot separator (e.g., "config", "features")
    func collapseAllExceptRoot() {
        let allPaths = collectAllExpandablePaths(from: json, parentPath: [])

        // Root-level paths have no dot separator
        let rootPaths = allPaths.filter { !$0.contains(".") }
        let nestedPaths = allPaths.filter { $0.contains(".") }

        // Keep root expanded, collapse everything else
        expandedPaths = rootPaths
        manuallyCollapsed = nestedPaths
        isAllExpanded = false
        rebuildFlattenedNodes()
    }

    /// Expand all parent nodes in the path to reveal the target field
    /// - Parameter targetPath: Path array (e.g., ["features", "darkMode"])
    func expandPathToNode(_ targetPath: [String]) {
        guard !targetPath.isEmpty else { return }

        // Build all parent paths that need expansion
        // e.g., ["features", "darkMode"] -> expand "features"
        for i in 1..<targetPath.count {
            let parentPath = targetPath.prefix(i).joined(separator: ".")
            expandedPaths.insert(parentPath)
            manuallyCollapsed.remove(parentPath)  // Override manual collapse
        }

        // Rebuild tree to show newly expanded nodes
        rebuildFlattenedNodes()
    }

    /// Set the change filter state and rebuild the tree
    func setShowChangedFieldsOnly(_ enabled: Bool) {
        guard showChangedFieldsOnly != enabled else { return }
        showChangedFieldsOnly = enabled

        // Update cached visible paths
        if enabled {
            cachedVisiblePaths = computeVisiblePathsForChangeFilter()
        } else {
            cachedVisiblePaths = nil
        }

        rebuildFlattenedNodes()
    }

    /// Returns the count of fields with changes (added, modified, or deleted)
    func countChangedFields() -> Int {
        return pathChangeStatus.values.filter { status in
            status == .added || status == .modified || status == .deleted
        }.count
    }

    // MARK: - Flattening

    /// Rebuild the flattened nodes array
    /// Called when expansion state or source data changes
    func rebuildFlattenedNodes() {
        flattenedNodes = flattenJSON(
            json,
            parentPath: [],
            depth: 0,
            parentType: .root
        )
    }

    /// Flatten a JSON dictionary into an array of nodes
    private func flattenJSON(
        _ dict: [String: Any],
        parentPath: [String],
        depth: Int,
        parentType: ParentType
    ) -> [FlattenedNode] {
        var result: [FlattenedNode] = []

        // Collect all keys: current keys + deleted keys from original
        var allKeys = Set(dict.keys)

        // Find deleted keys from original
        if let originalDict = getOriginalValue(at: parentPath) as? [String: Any] {
            for key in originalDict.keys where dict[key] == nil {
                allKeys.insert(key)
            }
        }

        for key in allKeys.sorted() {
            let path = parentPath + [key]
            let pathString = path.joined(separator: ".")

            // Skip node if filtering and not in visible set
            if let visibleSet = cachedVisiblePaths, !visibleSet.contains(pathString) {
                continue
            }

            let isDeleted = dict[key] == nil
            let value: Any
            let nodeType: JSONNodeType
            let changeStatus: JSONChangeStatus?

            if isDeleted {
                // Deleted node - get value from original
                guard let originalDict = getOriginalValue(at: parentPath) as? [String: Any],
                      let originalValue = originalDict[key] else {
                    continue
                }
                value = originalValue
                nodeType = JSONNodeType.infer(from: originalValue)
                changeStatus = .deleted
            } else {
                // Normal node - get value from current
                guard let currentValue = dict[key] else { continue }
                value = currentValue
                nodeType = JSONNodeType.infer(from: currentValue)
                changeStatus = pathChangeStatus[pathString]
            }

            let isExpanded = self.isExpanded(pathString) // Allow deleted nodes to expand to show children
            let isCurrentMatch = (currentMatchPath == path)

            // Get schema information for this path
            let schemaDescription = schema?.schema(at: path)?.description
            let validationError = validationErrors[pathString]
            let isRequired = parentPath.isEmpty ? false : (schema?.isRequired(key, at: parentPath) ?? false)

            var node = FlattenedNode(
                id: pathString,
                key: key,
                value: value,
                path: path,
                depth: depth,
                nodeType: nodeType,
                parentType: parentType,
                isExpanded: isExpanded,
                isCurrentMatch: isCurrentMatch,
                changeStatus: changeStatus
            )

            // Add schema properties
            node.schemaDescription = schemaDescription
            node.validationError = validationError
            node.isRequired = isRequired

            result.append(node)

            // Recursively add children if expanded (including deleted nodes to show git HEAD structure)
            if isExpanded {
                if let childDict = value as? [String: Any] {
                    result += flattenJSON(childDict, parentPath: path, depth: depth + 1, parentType: .object)
                } else if let childArray = value as? [Any] {
                    result += flattenArray(childArray, parentPath: path, depth: depth + 1, parentType: .array)
                }
            }
        }

        return result
    }

    /// Flatten a JSON array into an array of nodes
    private func flattenArray(
        _ array: [Any],
        parentPath: [String],
        depth: Int,
        parentType: ParentType
    ) -> [FlattenedNode] {
        var result: [FlattenedNode] = []

        // Get original array if available (for detecting deleted elements)
        let originalArray = getOriginalValue(at: parentPath) as? [Any]
        let totalCount = max(array.count, originalArray?.count ?? 0)

        for index in 0..<totalCount {
            let key = "[\(index)]"
            let path = parentPath + ["[\(index)]"]
            let pathString = path.joined(separator: ".")

            // Skip node if filtering and not in visible set
            if let visibleSet = cachedVisiblePaths, !visibleSet.contains(pathString) {
                continue
            }

            let isDeleted = index >= array.count
            let value: Any
            let nodeType: JSONNodeType
            let changeStatus: JSONChangeStatus?

            if isDeleted {
                // Deleted element - get value from original
                guard let originalArray = originalArray, index < originalArray.count else {
                    continue
                }
                value = originalArray[index]
                nodeType = JSONNodeType.infer(from: value)
                changeStatus = .deleted
            } else {
                // Normal element
                value = array[index]
                nodeType = JSONNodeType.infer(from: value)
                changeStatus = pathChangeStatus[pathString]
            }

            let isExpanded = self.isExpanded(pathString) // Allow deleted array elements to expand
            let isCurrentMatch = (currentMatchPath == path)

            // Get schema information for array items
            let itemSchema = schema?.schema(at: parentPath)?.items?.value
            let schemaDescription = itemSchema?.description
            let validationError = validationErrors[pathString]

            var node = FlattenedNode(
                id: pathString,
                key: key,
                value: value,
                path: path,
                depth: depth,
                nodeType: nodeType,
                parentType: parentType,
                isExpanded: isExpanded,
                isCurrentMatch: isCurrentMatch,
                changeStatus: changeStatus
            )

            // Add schema properties
            node.schemaDescription = schemaDescription
            node.validationError = validationError
            node.isRequired = false // Array elements are not "required" in the same way

            result.append(node)

            // Recursively add children if expanded (including deleted nodes to show git HEAD structure)
            if isExpanded {
                if let childDict = value as? [String: Any] {
                    result += flattenJSON(childDict, parentPath: path, depth: depth + 1, parentType: .object)
                } else if let childArray = value as? [Any] {
                    result += flattenArray(childArray, parentPath: path, depth: depth + 1, parentType: .array)
                }
            }
        }

        return result
    }

    // MARK: - Helper Methods

    /// Collect all expandable paths from a JSON dictionary
    private func collectAllExpandablePaths(
        from dict: [String: Any],
        parentPath: [String]
    ) -> Set<String> {
        var paths = Set<String>()

        for (key, value) in dict {
            let path = parentPath + [key]
            let pathString = path.joined(separator: ".")

            if let childDict = value as? [String: Any] {
                paths.insert(pathString)
                paths.formUnion(collectAllExpandablePaths(from: childDict, parentPath: path))
            } else if let childArray = value as? [Any] {
                paths.insert(pathString)
                paths.formUnion(collectAllExpandablePathsFromArray(childArray, parentPath: path))
            }
        }

        return paths
    }

    /// Collect all expandable paths from a JSON array
    private func collectAllExpandablePathsFromArray(
        _ array: [Any],
        parentPath: [String]
    ) -> Set<String> {
        var paths = Set<String>()

        for (index, value) in array.enumerated() {
            let path = parentPath + ["[\(index)]"]
            let pathString = path.joined(separator: ".")

            if let childDict = value as? [String: Any] {
                paths.insert(pathString)
                paths.formUnion(collectAllExpandablePaths(from: childDict, parentPath: path))
            } else if let childArray = value as? [Any] {
                paths.insert(pathString)
                paths.formUnion(collectAllExpandablePathsFromArray(childArray, parentPath: path))
            }
        }

        return paths
    }

    /// Calculate paths to expand to reveal a target path (for search navigation)
    func pathsToExpand(for targetPath: [String]?) -> Set<String> {
        guard let path = targetPath else { return [] }
        var result = Set<String>()
        for i in 1..<path.count {
            result.insert(path.prefix(i).map { $0 }.joined(separator: "."))
        }
        return result
    }

    /// Navigate the original JSON to get the value at a specific path
    private func getOriginalValue(at path: [String]) -> Any? {
        guard let original = originalJSON else { return nil }
        var current: Any = original
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

    /// Computes which paths should be visible when filtering by changes
    /// Returns set of paths that have changes OR are ancestors of changed nodes
    private func computeVisiblePathsForChangeFilter() -> Set<String> {
        var visiblePaths = Set<String>()

        // For each changed path (added, modified, or deleted), include it and all ancestors
        for (pathString, status) in pathChangeStatus {
            guard status == .added || status == .modified || status == .deleted else { continue }

            // Add the changed path itself
            visiblePaths.insert(pathString)

            // Add all ancestor paths to maintain tree structure
            let components = pathString.split(separator: ".").map(String.init)
            for i in 1..<components.count {
                let ancestorPath = components.prefix(i).joined(separator: ".")
                visiblePaths.insert(ancestorPath)
            }
        }

        return visiblePaths
    }
}
