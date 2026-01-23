import Foundation

/// Protocol defining minimal git configuration for repository operations.
///
/// Implement this protocol to customize git behavior, particularly
/// for protecting certain branches from direct commits.
///
/// ## Example Implementation
/// ```swift
/// struct MyAppGitConfig: GitConfiguration {
///     let protectedBranches: Set<String> = ["main", "master", "production"]
/// }
/// ```
public protocol GitConfiguration: Sendable {
    /// Branch names that are protected from direct commits.
    ///
    /// Example: ["main", "master", "production"]
    var protectedBranches: Set<String> { get }
}

// MARK: - Default Implementation

extension GitConfiguration {
    /// Default protected branches (main, master, origin)
    public var protectedBranches: Set<String> {
        ["main", "master", "origin"]
    }

    /// Checks if a branch name is protected.
    public func isProtectedBranch(_ branchName: String) -> Bool {
        protectedBranches.contains(branchName)
    }
}
