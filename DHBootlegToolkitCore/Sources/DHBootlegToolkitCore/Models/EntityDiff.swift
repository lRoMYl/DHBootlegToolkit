import Foundation

/// Represents the change status of an entity.
public enum EntityChangeStatus: Sendable, Hashable {
    case added
    case modified
    case deleted
    case unchanged

    /// Symbol for text-based display (e.g., "+", "~", "-")
    public var textSymbol: String? {
        switch self {
        case .added: return "+"
        case .modified: return "~"
        case .deleted: return "-"
        case .unchanged: return nil
        }
    }

    /// SF Symbol name for the change status
    public var systemImage: String? {
        switch self {
        case .added: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .unchanged: return nil
        }
    }
}

/// Stores diff information for a single translation file.
///
/// Compares the working directory state against the last committed version (HEAD).
public struct EntityDiff: Sendable {
    /// Feature identifier this diff belongs to
    public let featureId: String

    /// Path to the file being compared
    public let filePath: String

    /// Entity keys that exist in working directory but not in HEAD
    public let addedKeys: Set<String>

    /// Entity keys that exist in both but have different values
    public let modifiedKeys: Set<String>

    /// Entity keys that exist in HEAD but not in working directory
    public let deletedKeys: Set<String>

    /// File is new (not tracked in HEAD)
    public let isNewFile: Bool

    /// File was deleted from working directory
    public let isDeletedFile: Bool

    /// Whether there are any changes
    public var hasChanges: Bool {
        !addedKeys.isEmpty || !modifiedKeys.isEmpty || !deletedKeys.isEmpty
    }

    /// Total number of changes
    public var totalChanges: Int {
        addedKeys.count + modifiedKeys.count + deletedKeys.count
    }

    public init(
        featureId: String,
        filePath: String,
        addedKeys: Set<String>,
        modifiedKeys: Set<String>,
        deletedKeys: Set<String>,
        isNewFile: Bool = false,
        isDeletedFile: Bool = false
    ) {
        self.featureId = featureId
        self.filePath = filePath
        self.addedKeys = addedKeys
        self.modifiedKeys = modifiedKeys
        self.deletedKeys = deletedKeys
        self.isNewFile = isNewFile
        self.isDeletedFile = isDeletedFile
    }

    /// Gets the change status for a specific key.
    public func status(for keyName: String) -> EntityChangeStatus {
        if addedKeys.contains(keyName) { return .added }
        if modifiedKeys.contains(keyName) { return .modified }
        if deletedKeys.contains(keyName) { return .deleted }
        return .unchanged
    }

    /// Empty diff (no changes)
    public static let empty = EntityDiff(
        featureId: "",
        filePath: "",
        addedKeys: [],
        modifiedKeys: [],
        deletedKeys: []
    )
}
