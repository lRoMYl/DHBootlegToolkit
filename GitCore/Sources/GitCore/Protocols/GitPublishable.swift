import Foundation

/// Protocol for view models/stores that support git operations and PR creation.
///
/// This protocol provides default implementations for common git workflows while
/// allowing apps to customize specific behaviors like commit message generation.
///
/// ## Example Implementation
/// ```swift
/// @Observable
/// @MainActor
/// final class MyStore: GitPublishable {
///     var gitWorker: GitWorker?
///     var gitStatus: GitStatus = .unconfigured
///
///     func generateCommitMessage() -> String {
///         "Update configuration"
///     }
///
///     func generatePRTitle() -> String {
///         "Configuration updates"
///     }
///
///     func generatePRBody() -> String {
///         "This PR contains configuration updates."
///     }
/// }
/// ```
@MainActor
public protocol GitPublishable: AnyObject, Observable {
    // MARK: - Git Infrastructure (Required)

    /// The git worker instance for performing git operations
    var gitWorker: GitWorker? { get }

    /// Current git status of the repository
    var gitStatus: GitStatus { get set }

    // MARK: - Store-Specific Methods (Must Implement)

    /// Generates a commit message based on current changes
    func generateCommitMessage() -> String

    /// Generates a pull request title
    func generatePRTitle() -> String

    /// Generates a pull request body/description
    func generatePRBody() -> String
}

// MARK: - Default Implementations

extension GitPublishable {
    /// Whether the store can create a pull request (has uncommitted changes and is ready)
    public var canPublish: Bool {
        gitStatus.hasUncommittedChanges && gitStatus.isReady
    }

    /// Refreshes git status
    public func refreshGitStatus() async {
        guard let gitWorker else {
            gitStatus = .unconfigured
            return
        }
        do {
            gitStatus = try await gitWorker.checkConfiguration()
        } catch {
            gitStatus = .unconfigured
        }
    }

    /// Creates a pull request with all uncommitted changes.
    ///
    /// This method:
    /// 1. Generates commit message, PR title, and PR body using store-specific methods
    /// 2. Uses GitWorker to commit, push, and create the PR
    /// 3. Returns the PR URL for the app to handle (e.g., open in browser)
    ///
    /// - Returns: URL of the created pull request
    /// - Throws: GitError if any git operation fails
    public func publish() async throws -> URL {
        guard let gitWorker, canPublish else {
            throw GitWorker.GitError.notConfigured("Cannot publish: git not ready")
        }

        // Generate PR metadata using store-specific methods
        let commitMessage = generateCommitMessage()
        let prTitle = generatePRTitle()
        let prBody = generatePRBody()

        // Use GitWorker's publish flow (commit, push, create PR)
        let prURL = try await gitWorker.publish(
            commitMessage: commitMessage,
            prTitle: prTitle,
            prBody: prBody
        )

        // Refresh git status after successful publish
        await refreshGitStatus()

        return prURL
    }

    /// Converts git error messages to user-friendly text
    public func userFriendlyGitError(_ error: Error) -> String {
        let message = error.localizedDescription

        // Branch already exists
        if message.contains("already exists") {
            return "A branch with this name already exists."
        }

        // Uncommitted changes blocking checkout/pull
        if message.contains("unstaged changes") || message.contains("uncommitted changes") ||
           message.contains("Please commit or stash") || message.contains("would be overwritten") {
            return "You have uncommitted changes. Please save your work first."
        }

        // Cannot pull with rebase
        if message.contains("cannot pull with rebase") {
            return "Cannot update branch: you have local changes. Save your work first."
        }

        // Branch not found
        if message.contains("did not match any") || message.contains("not found") {
            return "Branch not found. It may have been deleted."
        }

        // Network/remote issues
        if message.contains("Could not resolve host") || message.contains("unable to access") {
            return "Unable to connect to remote repository. Check your internet connection."
        }

        // Authentication issues
        if message.contains("Authentication failed") || message.contains("Permission denied") {
            return "Authentication failed. Please check your git credentials."
        }

        // Default: return original message
        return message
    }
}
