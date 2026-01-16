import Foundation

/// Represents a file or folder item within a feature folder.
///
/// Used to display the tree structure of files in the sidebar,
/// including JSON files, images, folders, and other file types.
public struct FeatureFileItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let url: URL
    public let type: FileItemType
    public var children: [FeatureFileItem]
    public var gitStatus: GitFileStatus

    public init(
        id: String,
        name: String,
        url: URL,
        type: FileItemType,
        children: [FeatureFileItem] = [],
        gitStatus: GitFileStatus = .unchanged
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.type = type
        self.children = children
        self.gitStatus = gitStatus
    }

    /// The type of file item
    public enum FileItemType: Hashable, Sendable {
        case jsonFile(isPrimary: Bool)
        case folder
        case image
        case otherFile(fileExtension: String)
    }

    /// SF Symbol icon name for the file type
    public var iconName: String {
        switch type {
        case .jsonFile(let isPrimary):
            return isPrimary ? "doc.text.fill" : "doc.text"
        case .folder:
            return "folder.fill"
        case .image:
            return "photo"
        case .otherFile(let ext):
            switch ext.lowercased() {
            case "txt", "md", "markdown":
                return "doc.plaintext"
            case "xml", "plist":
                return "doc.badge.gearshape"
            default:
                return "doc"
            }
        }
    }

    /// For folders: returns aggregated status based on children.
    /// If any child has changes, the folder shows as modified.
    public var aggregatedGitStatus: GitFileStatus {
        guard case .folder = type else { return gitStatus }

        let hasChanges = children.contains { child in
            child.gitStatus != .unchanged || child.aggregatedGitStatus != .unchanged
        }
        return hasChanges ? .modified : .unchanged
    }

    /// Counts of children by git status (recursive).
    /// Used for folder badges to show [+x ~y -z] format.
    public var childStatusCounts: (added: Int, modified: Int, deleted: Int) {
        guard case .folder = type else { return (0, 0, 0) }

        var added = 0, modified = 0, deleted = 0

        for child in children {
            switch child.gitStatus {
            case .added: added += 1
            case .modified: modified += 1
            case .deleted: deleted += 1
            case .unchanged: break
            }

            // Add nested folder counts
            let nested = child.childStatusCounts
            added += nested.added
            modified += nested.modified
            deleted += nested.deleted
        }

        return (added, modified, deleted)
    }

    /// Whether folder has any children with changes.
    public var hasChildChanges: Bool {
        let counts = childStatusCounts
        return counts.added > 0 || counts.modified > 0 || counts.deleted > 0
    }

    /// Whether this item should display a git status badge.
    /// Folders never show badges; files show badges only when changed.
    public var shouldShowGitBadge: Bool {
        // Folders never show individual git badges
        if case .folder = type {
            return false
        }
        // Files show badges only when they have changes
        return gitStatus != .unchanged
    }
}

// MARK: - Git File Status

/// Represents the git status of a file
public enum GitFileStatus: Hashable, Sendable {
    case unchanged
    case added      // [A] - new file (green)
    case modified   // [M] - changed file (blue)
    case deleted    // [-] - removed file (red)

    /// Parses git status from porcelain format (first two characters of git status --porcelain output)
    public static func from(porcelainCode: String) -> GitFileStatus {
        guard porcelainCode.count >= 2 else { return .unchanged }

        let chars = Array(porcelainCode)
        let index = chars[0]
        let worktree = chars[1]

        // Untracked files
        if index == "?" && worktree == "?" {
            return .added
        }

        // Added to index
        if index == "A" {
            return .added
        }

        // Deleted
        if index == "D" || worktree == "D" {
            return .deleted
        }

        // Modified (in index or worktree)
        if index == "M" || worktree == "M" {
            return .modified
        }

        // Renamed or copied (treat as modified)
        if index == "R" || index == "C" {
            return .modified
        }

        return .unchanged
    }

    /// The letter to display in the badge (A, M, D, or empty)
    public var badgeLetter: String {
        switch self {
        case .added: return "A"
        case .modified: return "M"
        case .deleted: return "D"
        case .unchanged: return ""
        }
    }
}

// MARK: - EntityChangeStatus Conversion

extension GitFileStatus {
    /// Converts GitFileStatus to EntityChangeStatus for reusing existing badge components
    public var asEntityChangeStatus: EntityChangeStatus {
        switch self {
        case .unchanged: return .unchanged
        case .added: return .added
        case .modified: return .modified
        case .deleted: return .deleted
        }
    }
}
