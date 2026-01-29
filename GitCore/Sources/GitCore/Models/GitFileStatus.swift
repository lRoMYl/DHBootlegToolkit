import Foundation

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
