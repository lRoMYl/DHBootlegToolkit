import SwiftUI
import Observation

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

    /// Change status for each path compared to git HEAD (only includes changed paths)
    private var pathChangeStatus: [String: JSONChangeStatus] = [:]

    /// Whether to show only changed fields
    private var showChangedFieldsOnly: Bool = false

    /// Cached set of visible paths when filtering by changes
    private var cachedVisiblePaths: Set<String>? = nil

    // MARK: - Initialization

    init() {}

    // MARK: - Configuration

    /// Configure the view model with JSON data
    /// - Parameters:
    ///   - json: The current JSON data to display
    ///   - expandAllByDefault: Whether to expand all nodes by default
    ///   - manuallyCollapsed: Set of paths that were manually collapsed by the user
    ///   - originalJSON: The original JSON from git HEAD for change tracking (nil = no diff)
    ///   - showChangedFieldsOnly: Whether to filter the tree to show only changed fields
    func configure(
        json: [String: Any],
        expandAllByDefault: Bool = true,
        manuallyCollapsed: Set<String> = [],
        originalJSON: [String: Any]? = nil,
        showChangedFieldsOnly: Bool = false
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()

        self.json = json
        self.expandAllByDefault = expandAllByDefault
        self.manuallyCollapsed = manuallyCollapsed
        self.originalJSON = originalJSON
        self.showChangedFieldsOnly = showChangedFieldsOnly

        // Compute change status against original JSON
        if let original = originalJSON {
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
        pathChangeStatus = [:]
        showChangedFieldsOnly = false
        cachedVisiblePaths = nil
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

    /// Returns the count of fields with changes (added or modified)
    func countChangedFields() -> Int {
        return pathChangeStatus.values.filter { status in
            status == .added || status == .modified
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

        for key in dict.keys.sorted() {
            guard let value = dict[key] else { continue }

            let path = parentPath + [key]
            let pathString = path.joined(separator: ".")

            // Skip node if filtering and not in visible set
            if let visibleSet = cachedVisiblePaths, !visibleSet.contains(pathString) {
                continue
            }

            let nodeType = JSONNodeType.infer(from: value)
            let isExpanded = self.isExpanded(pathString)
            let isCurrentMatch = (currentMatchPath == path)

            let node = FlattenedNode(
                id: pathString,
                key: key,
                value: value,
                path: path,
                depth: depth,
                nodeType: nodeType,
                parentType: parentType,
                isExpanded: isExpanded,
                isCurrentMatch: isCurrentMatch,
                changeStatus: pathChangeStatus[pathString]
            )

            result.append(node)

            // Recursively add children if expanded
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

        for (index, value) in array.enumerated() {
            let key = "[\(index)]"
            let path = parentPath + [String(index)]
            let pathString = path.joined(separator: ".")

            // Skip node if filtering and not in visible set
            if let visibleSet = cachedVisiblePaths, !visibleSet.contains(pathString) {
                continue
            }

            let nodeType = JSONNodeType.infer(from: value)
            let isExpanded = self.isExpanded(pathString)
            let isCurrentMatch = (currentMatchPath == path)

            let node = FlattenedNode(
                id: pathString,
                key: key,
                value: value,
                path: path,
                depth: depth,
                nodeType: nodeType,
                parentType: parentType,
                isExpanded: isExpanded,
                isCurrentMatch: isCurrentMatch,
                changeStatus: pathChangeStatus[pathString]
            )

            result.append(node)

            // Recursively add children if expanded
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
            let path = parentPath + [String(index)]
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

    /// Computes which paths should be visible when filtering by changes
    /// Returns set of paths that have changes OR are ancestors of changed nodes
    private func computeVisiblePathsForChangeFilter() -> Set<String> {
        var visiblePaths = Set<String>()

        // For each changed path (added or modified), include it and all ancestors
        for (pathString, status) in pathChangeStatus {
            guard status == .added || status == .modified else { continue }

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
