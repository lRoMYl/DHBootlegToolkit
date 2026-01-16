import Foundation

/// Represents the current git status of a repository.
///
/// This struct captures information about git configuration,
/// the current branch, and uncommitted changes.
public struct GitStatus: Sendable {
    /// Whether git is properly configured with user name and email
    public let isConfigured: Bool

    /// Configured git user name
    public let userName: String?

    /// Configured git user email
    public let userEmail: String?

    /// Currently checked out branch name
    public let currentBranch: String?

    /// Whether there are uncommitted changes
    public let hasUncommittedChanges: Bool

    /// Number of uncommitted files
    public let uncommittedFileCount: Int

    /// List of uncommitted file paths
    public let uncommittedFiles: [String]

    /// Number of local commits not yet pushed to remote
    public let commitsAhead: Int

    /// Number of remote commits not yet pulled
    public let commitsBehind: Int

    /// Detailed list of local commits ahead of remote
    public let commitsAheadDetails: [GitCommit]

    /// Detailed list of remote commits behind local
    public let commitsBehindDetails: [GitCommit]

    /// Whether the current branch is a protected branch
    public let isOnProtectedBranch: Bool

    /// Optional error message if git operations failed
    public let errorMessage: String?

    /// Whether the repository is ready for editing (configured and not on protected branch)
    public var isReady: Bool {
        isConfigured && !isOnProtectedBranch
    }

    /// Display-friendly email string
    public var displayEmail: String {
        userEmail ?? "Not configured"
    }

    /// Display-friendly user name string
    public var displayName: String {
        userName ?? "Unknown"
    }

    public init(
        isConfigured: Bool,
        userName: String? = nil,
        userEmail: String? = nil,
        currentBranch: String? = nil,
        hasUncommittedChanges: Bool = false,
        uncommittedFileCount: Int = 0,
        uncommittedFiles: [String] = [],
        commitsAhead: Int = 0,
        commitsBehind: Int = 0,
        commitsAheadDetails: [GitCommit] = [],
        commitsBehindDetails: [GitCommit] = [],
        isOnProtectedBranch: Bool = false,
        errorMessage: String? = nil
    ) {
        self.isConfigured = isConfigured
        self.userName = userName
        self.userEmail = userEmail
        self.currentBranch = currentBranch
        self.hasUncommittedChanges = hasUncommittedChanges
        self.uncommittedFileCount = uncommittedFileCount
        self.uncommittedFiles = uncommittedFiles
        self.commitsAhead = commitsAhead
        self.commitsBehind = commitsBehind
        self.commitsAheadDetails = commitsAheadDetails
        self.commitsBehindDetails = commitsBehindDetails
        self.isOnProtectedBranch = isOnProtectedBranch
        self.errorMessage = errorMessage
    }

    /// Unconfigured git status
    public static let unconfigured = GitStatus(
        isConfigured: false,
        errorMessage: "Git not configured"
    )
}

// MARK: - Factory Methods

extension GitStatus {
    /// Creates a GitStatus by checking if the current branch is protected.
    ///
    /// - Parameters:
    ///   - isConfigured: Whether git is configured
    ///   - userName: Git user name
    ///   - userEmail: Git user email
    ///   - currentBranch: Current branch name
    ///   - hasUncommittedChanges: Whether there are uncommitted changes
    ///   - uncommittedFileCount: Number of uncommitted files
    ///   - uncommittedFiles: List of uncommitted file paths
    ///   - protectedBranches: Set of branch names considered protected
    ///   - errorMessage: Optional error message
    public static func create(
        isConfigured: Bool,
        userName: String?,
        userEmail: String?,
        currentBranch: String?,
        hasUncommittedChanges: Bool,
        uncommittedFileCount: Int,
        uncommittedFiles: [String],
        commitsAhead: Int,
        commitsBehind: Int,
        commitsAheadDetails: [GitCommit] = [],
        commitsBehindDetails: [GitCommit] = [],
        protectedBranches: Set<String>,
        errorMessage: String? = nil
    ) -> GitStatus {
        let isOnProtectedBranch = currentBranch.map { protectedBranches.contains($0) } ?? false

        return GitStatus(
            isConfigured: isConfigured,
            userName: userName,
            userEmail: userEmail,
            currentBranch: currentBranch,
            hasUncommittedChanges: hasUncommittedChanges,
            uncommittedFileCount: uncommittedFileCount,
            uncommittedFiles: uncommittedFiles,
            commitsAhead: commitsAhead,
            commitsBehind: commitsBehind,
            commitsAheadDetails: commitsAheadDetails,
            commitsBehindDetails: commitsBehindDetails,
            isOnProtectedBranch: isOnProtectedBranch,
            errorMessage: errorMessage
        )
    }
}
