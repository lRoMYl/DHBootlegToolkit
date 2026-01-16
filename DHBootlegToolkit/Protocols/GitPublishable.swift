import Foundation
import DHBootlegToolkitCore
import AppKit

/// Result of branch operations (create, rename, etc.)
enum BranchResult {
    case success
    case error(String)
    case branchExists(String)
}

/// Protocol for stores that support git operations, branch switching, and PR creation
@MainActor
protocol GitPublishable: AnyObject, Observable {
    // Git infrastructure
    var gitWorker: GitWorker? { get }
    var gitStatus: GitStatus { get set }
    var availableBranches: [String] { get set }
    var isLoadingBranches: Bool { get set }

    // Branch switch confirmation state
    var pendingBranchSwitch: String? { get set }
    var showUncommittedChangesConfirmation: Bool { get set }

    // Publish state
    var showPublishError: Bool { get set }
    var publishErrorMessage: String? { get set }
    var isLoading: Bool { get set }

    // Computed properties
    var canPublish: Bool { get }

    // Store-specific methods that must be implemented
    func saveAllModifications() async throws
    func generateCommitMessage() -> String
    func generatePRTitle() -> String
    func generatePRBody() -> String
    func performBranchSwitch(_ branchName: String) async -> String?
    func refreshAfterGitOperation() async

    // Store-specific data reload hooks
    func reloadDataAfterGitOperation() async
    func cleanupStateAfterDiscardAll() async
}

// MARK: - Default Implementations

extension GitPublishable {
    /// Computed property for enabling "Create PR" button
    var canPublish: Bool {
        gitStatus.hasUncommittedChanges && gitStatus.isReady
    }

    /// Attempts to switch branch, showing confirmation if uncommitted changes exist
    func requestBranchSwitch(_ branchName: String) {
        if gitStatus.hasUncommittedChanges {
            pendingBranchSwitch = branchName
            showUncommittedChangesConfirmation = true
        } else {
            Task { _ = await performBranchSwitch(branchName) }
        }
    }

    /// Commits current changes and then switches branch (called when user confirms)
    func commitAndSwitchBranch() async -> String? {
        guard let gitWorker, let targetBranch = pendingBranchSwitch else {
            return "No pending branch switch"
        }

        return await AppLogger.shared.timedGroup("Commit and Switch Branch") { ctx in
            isLoading = true
            defer { isLoading = false }

            // Check if current branch is protected
            if gitStatus.isOnProtectedBranch {
                pendingBranchSwitch = nil
                let branchName = gitStatus.currentBranch ?? "unknown"
                return "Cannot commit on protected branch '\(branchName)'. Please create a feature branch first."
            }

            // Save all modifications to disk (store-specific)
            do {
                try await ctx.time("Save modifications") {
                    try await saveAllModifications()
                }
            } catch {
                return "Failed to save changes: \(error.localizedDescription)"
            }

            // Auto-commit with WIP message
            do {
                try await ctx.time("Auto-commit changes") {
                    let commitMessage = "WIP: Auto-save before switching to \(targetBranch) - \(generateCommitMessage())"
                    try await gitWorker.commitAll(message: commitMessage)
                }
            } catch {
                return "Failed to commit changes: \(error.localizedDescription)"
            }

            // Switch branch
            let error = await ctx.time("Switch to \(targetBranch)") {
                await performBranchSwitch(targetBranch)
            }
            pendingBranchSwitch = nil
            return error
        }
    }

    /// Cancels pending branch switch
    func cancelBranchSwitch() {
        pendingBranchSwitch = nil
        showUncommittedChangesConfirmation = false
    }

    /// Discards all uncommitted changes and then switches branch
    func discardAndSwitchBranch() async -> String? {
        guard let gitWorker, let targetBranch = pendingBranchSwitch else {
            return "No pending branch switch"
        }

        return await AppLogger.shared.timedGroup("Discard and Switch Branch") { ctx in
            isLoading = true
            defer { isLoading = false }

            // Discard all uncommitted changes
            do {
                try await ctx.time("Discard all changes") {
                    try await gitWorker.discardAllChanges()
                }
            } catch {
                return "Failed to discard changes: \(error.localizedDescription)"
            }

            // Switch branch
            let error = await ctx.time("Switch to \(targetBranch)") {
                await performBranchSwitch(targetBranch)
            }
            pendingBranchSwitch = nil
            return error
        }
    }

    /// Creates a pull request with all uncommitted changes
    func publish() async {
        guard let gitWorker, canPublish else { return }

        await AppLogger.shared.timedGroup("Publish to GitHub") { ctx in
            isLoading = true
            defer { isLoading = false }

            // Save any unsaved changes to disk (store-specific)
            do {
                try await ctx.time("Save modifications") {
                    try await saveAllModifications()
                }
            } catch {
                publishErrorMessage = error.localizedDescription
                showPublishError = true
                return
            }

            do {
                // Generate PR metadata (store-specific)
                let commitMessage = await ctx.time("Generate commit message") {
                    generateCommitMessage()
                }
                let prTitle = await ctx.time("Generate PR title") {
                    generatePRTitle()
                }
                let prBody = await ctx.time("Generate PR body") {
                    generatePRBody()
                }

                // Use GitWorker's publish flow (commit, push, create PR)
                let prURL = try await ctx.time("Git publish workflow") {
                    try await gitWorker.publish(
                        commitMessage: commitMessage,
                        prTitle: prTitle,
                        prBody: prBody
                    )
                }

                // Open PR in browser
                NSWorkspace.shared.open(prURL)

                // Refresh git status after successful publish
                await ctx.time("Refresh git status") {
                    await refreshAfterGitOperation()
                }

            } catch {
                publishErrorMessage = error.localizedDescription
                showPublishError = true
            }
        }
    }

    // MARK: - Common Git Operations

    /// Refreshes git status
    func refreshGitStatus() async {
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

    /// Loads available branches for the branch selector
    func loadBranches() async {
        guard let gitWorker else { return }

        isLoadingBranches = true
        defer { isLoadingBranches = false }

        do {
            availableBranches = try await gitWorker.getRecentBranches(limit: 10)
        } catch {
            availableBranches = []
        }
    }

    /// Switch to an existing branch, returns error message if failed
    func switchToBranch(_ branchName: String) async -> String? {
        if gitStatus.hasUncommittedChanges {
            return "You have uncommitted changes. Please save your work first."
        }
        return await performBranchSwitch(branchName)
    }

    /// Converts git error messages to user-friendly text
    func userFriendlyGitError(_ error: Error) -> String {
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

    // MARK: - Branch Operations

    /// Creates a new branch from current branch
    func createBranchFromMain(_ branchName: String) async -> BranchResult {
        guard let gitWorker else { return .error("Git not configured") }

        return await AppLogger.shared.timedGroup("Create Branch: \(branchName)") { ctx in
            do {
                // Create new branch (git allows this with uncommitted changes)
                try await ctx.time("Create branch (git checkout -b)") {
                    try await gitWorker.createBranch(branchName)
                }

                // Refresh git status and branches
                await ctx.time("Refresh git status") {
                    await refreshGitStatus()
                }
                await ctx.time("Load branches") {
                    await loadBranches()
                }

                // Store-specific data reload
                await ctx.time("Reload data") {
                    await reloadDataAfterGitOperation()
                }

                return .success
            } catch {
                await ctx.time("Refresh git status (error path)") {
                    await refreshGitStatus()
                }
                let message = error.localizedDescription
                if message.contains("already exists") {
                    return .branchExists(branchName)
                }
                return .error(userFriendlyGitError(error))
            }
        }
    }

    /// Pulls latest changes from remote
    func pullLatestFromRemote() async {
        guard let gitWorker else { return }

        await AppLogger.shared.timedGroup("Pull Latest") { ctx in
            isLoading = true
            defer { isLoading = false }

            do {
                try await ctx.time("Pull with rebase") {
                    try await gitWorker.pullLatest()
                }
                await ctx.time("Refresh git status") {
                    await refreshGitStatus()
                }

                // Store-specific data reload
                await ctx.time("Reload data") {
                    await reloadDataAfterGitOperation()
                }

                publishErrorMessage = nil
            } catch {
                publishErrorMessage = "Failed to pull latest: \(userFriendlyGitError(error))"
                showPublishError = true
            }
        }
    }

    /// Discards all uncommitted changes across the entire repository
    func discardAllUncommittedChanges() async {
        guard let gitWorker else { return }

        await AppLogger.shared.timedGroup("Discard All Changes") { ctx in
            isLoading = true
            defer { isLoading = false }

            do {
                try await ctx.time("Discard changes (git reset)") {
                    try await gitWorker.discardAllChanges()
                }
                await ctx.time("Refresh git status") {
                    await refreshGitStatus()
                }

                // Store-specific data reload
                await ctx.time("Reload data") {
                    await reloadDataAfterGitOperation()
                }

                // Store-specific state cleanup
                await ctx.time("Cleanup state") {
                    await cleanupStateAfterDiscardAll()
                }
            } catch {
                publishErrorMessage = "Failed to discard changes: \(userFriendlyGitError(error))"
                showPublishError = true
            }
        }
    }
}
