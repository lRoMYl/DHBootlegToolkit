import Foundation

/// GitCore provides generic git operations for macOS applications.
///
/// This package includes:
/// - `GitWorker`: Actor for executing git commands
/// - `ProcessExecutor`: Low-level process execution
/// - `GitStatus`, `GitCommit`, `GitFileStatus`: Models for git state
/// - `GitConfiguration`: Protocol for repository configuration
/// - `GitPublishable`: Protocol for git-enabled view models
public enum GitCore {
    /// The version of this package
    public static let version = "1.0.0"
}
