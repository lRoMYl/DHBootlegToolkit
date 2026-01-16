import Foundation

/// Manages git operations for a repository.
///
/// GitWorker provides methods for common git operations like branch management,
/// commits, and PR creation. It uses the configuration to determine which
/// branches are protected.
public actor GitWorker {

    /// Errors that can occur during git operations.
    public enum GitError: LocalizedError, Sendable {
        case notConfigured(String)
        case commandFailed(String)
        case repositoryNotFound
        case onProtectedBranch

        public var errorDescription: String? {
            switch self {
            case .notConfigured(let message):
                return "Git not configured: \(message)"
            case .commandFailed(let message):
                return "Git command failed: \(message)"
            case .repositoryNotFound:
                return "Not a git repository"
            case .onProtectedBranch:
                return "Cannot perform this operation on a protected branch"
            }
        }
    }

    private let repositoryURL: URL
    private let configuration: RepositoryConfiguration

    /// The path to the repository root directory.
    public var repositoryPath: String {
        repositoryURL.path
    }

    public init(repositoryURL: URL, configuration: RepositoryConfiguration) {
        self.repositoryURL = repositoryURL
        self.configuration = configuration
    }

    // MARK: - Git Configuration Check

    /// Checks the git configuration and returns the current status.
    public func checkConfiguration() async throws -> GitStatus {
        // Check if it's a git repo
        let isRepoResult = try? await runGit(["rev-parse", "--is-inside-work-tree"])
        let isRepo = isRepoResult?.trimmingCharacters(in: .whitespacesAndNewlines) == "true"

        guard isRepo else {
            return GitStatus(
                isConfigured: false,
                errorMessage: "Not a git repository"
            )
        }

        // Get user config
        let userName = try? await runGit(["config", "user.name"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let userEmail = try? await runGit(["config", "user.email"])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Check configuration
        let isConfigured = !(userName?.isEmpty ?? true) && !(userEmail?.isEmpty ?? true)

        // Get current branch
        let currentBranch = try? await runGit(["branch", "--show-current"])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for uncommitted changes
        let status = try? await runGit(["status", "--porcelain"])
        let statusLines = status?.components(separatedBy: .newlines).filter { !$0.isEmpty } ?? []
        let hasChanges = !statusLines.isEmpty
        let fileCount = statusLines.count

        // Extract file paths from porcelain output (format: "XY filename")
        let filePaths = statusLines.compactMap { line -> String? in
            guard line.count > 3 else { return nil }
            return String(line.dropFirst(3))
        }

        // Get commits ahead/behind remote
        let commitsAhead: Int
        let commitsBehind: Int
        var commitsAheadDetails: [GitCommit] = []
        var commitsBehindDetails: [GitCommit] = []

        if let currentBranch, !currentBranch.isEmpty {
            // Check if branch has an upstream
            let hasUpstream = (try? await runGit(["rev-parse", "--abbrev-ref", "@{u}"])) != nil
            if hasUpstream {
                // Count commits ahead using git rev-list
                let aheadOutput = try? await runGit(["rev-list", "@{u}..HEAD", "--count"])
                commitsAhead = Int(aheadOutput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0

                // Count commits behind using git rev-list
                let behindOutput = try? await runGit(["rev-list", "HEAD..@{u}", "--count"])
                commitsBehind = Int(behindOutput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0

                // Fetch commit details only if counts > 0
                if commitsAhead > 0 {
                    commitsAheadDetails = (try? await getCommitsAhead(limit: 10)) ?? []
                }
                if commitsBehind > 0 {
                    commitsBehindDetails = (try? await getCommitsBehind(limit: 10)) ?? []
                }
            } else {
                commitsAhead = 0
                commitsBehind = 0
            }
        } else {
            commitsAhead = 0
            commitsBehind = 0
        }

        return GitStatus.create(
            isConfigured: isConfigured,
            userName: userName,
            userEmail: userEmail,
            currentBranch: currentBranch,
            hasUncommittedChanges: hasChanges,
            uncommittedFileCount: fileCount,
            uncommittedFiles: filePaths,
            commitsAhead: commitsAhead,
            commitsBehind: commitsBehind,
            commitsAheadDetails: commitsAheadDetails,
            commitsBehindDetails: commitsBehindDetails,
            protectedBranches: configuration.protectedBranches,
            errorMessage: isConfigured ? nil : "Please configure git user.name and user.email"
        )
    }

    // MARK: - Branch Operations

    /// Creates a new branch.
    public func createBranch(_ name: String) async throws {
        _ = try await runGit(["checkout", "-b", name])
    }

    /// Switches to an existing branch.
    public func switchToBranch(_ name: String) async throws {
        _ = try await runGit(["checkout", name])
    }

    /// Renames a branch.
    public func renameBranch(from oldName: String, to newName: String) async throws {
        _ = try await runGit(["branch", "-m", oldName, newName])
    }

    /// Returns the current branch name.
    public func getCurrentBranch() async throws -> String {
        let branch = try await runGit(["branch", "--show-current"])
        return branch.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns recently used branches, sorted by most recently committed.
    /// - Parameter limit: Maximum number of branches to return
    /// - Parameter fetchRemote: Whether to fetch from remote before listing branches (defaults to false for performance)
    public func getRecentBranches(limit: Int = 10, fetchRemote: Bool = false) async throws -> [String] {
        // Optionally fetch latest from remote (can be slow over network)
        if fetchRemote {
            _ = try? await runGit(["fetch", "--prune"])
        }

        // Get local branches
        let localResult = try await runGit([
            "for-each-ref",
            "--sort=-committerdate",
            "--format=%(refname:short)",
            "refs/heads/"
        ])
        let localBranches = localResult.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Get remote branches
        let remoteResult = try? await runGit([
            "for-each-ref",
            "--sort=-committerdate",
            "--format=%(refname:short)",
            "refs/remotes/origin/"
        ])
        let remoteBranches = (remoteResult ?? "").components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.contains("HEAD") }
            .map { $0.replacingOccurrences(of: "origin/", with: "") }

        // Combine: local branches first, then remote-only branches
        var seen = Set<String>()
        var combined: [String] = []

        for branch in localBranches {
            if !seen.contains(branch) {
                seen.insert(branch)
                combined.append(branch)
            }
        }

        for branch in remoteBranches {
            if !seen.contains(branch) {
                seen.insert(branch)
                combined.append(branch)
            }
        }

        return Array(combined.prefix(limit))
    }

    /// Returns local commits that are ahead of the remote
    public func getCommitsAhead(limit: Int = 10) async throws -> [GitCommit] {
        let output = try await runGit([
            "log",
            "@{u}..HEAD",
            "--format=%H%n%s%n%an%n%at",
            "--max-count=\(limit)"
        ])
        return parseCommitLog(output)
    }

    /// Returns remote commits that are behind (not pulled yet)
    public func getCommitsBehind(limit: Int = 10) async throws -> [GitCommit] {
        let output = try await runGit([
            "log",
            "HEAD..@{u}",
            "--format=%H%n%s%n%an%n%at",
            "--max-count=\(limit)"
        ])
        return parseCommitLog(output)
    }

    /// Parses git log output into GitCommit objects
    private func parseCommitLog(_ output: String) -> [GitCommit] {
        let lines = output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var commits: [GitCommit] = []
        var i = 0

        while i + 3 < lines.count {
            let hash = lines[i]
            let message = lines[i + 1]
            let author = lines[i + 2]
            let timestampString = lines[i + 3]

            if let timestamp = TimeInterval(timestampString) {
                let date = Date(timeIntervalSince1970: timestamp)
                commits.append(GitCommit(
                    hash: hash,
                    message: message,
                    author: author,
                    timestamp: date
                ))
            }

            i += 4
        }

        return commits
    }

    /// Pulls latest changes with rebase.
    public func pullLatest() async throws {
        _ = try await runGit(["pull", "--rebase"])
    }

    // MARK: - File Content Operations

    /// Retrieves file content from HEAD (last committed version).
    /// Marked nonisolated to allow parallel execution.
    ///
    /// - Parameter relativePath: Path relative to repository root
    /// - Returns: File content as Data, or nil if file doesn't exist in HEAD
    public nonisolated func getHeadFileContent(relativePath: String) async -> Data? {
        let repoURL = repositoryURL
        do {
            let output = try await runGitNonisolated(["show", "HEAD:\(relativePath)"], in: repoURL)
            return output.data(using: .utf8)
        } catch {
            // File doesn't exist in HEAD (new file) or other error
            return nil
        }
    }

    // MARK: - File Status Operations

    /// Gets git status for all files in a directory relative to repository root.
    ///
    /// - Parameter relativePath: Path relative to repository root (e.g., "translations/mobile/login")
    /// - Returns: Dictionary mapping relative file paths to their git status
    public func getFileStatuses(inDirectory relativePath: String) async throws -> [String: GitFileStatus] {
        let output = try await runGit(["status", "--porcelain", relativePath])

        var statuses: [String: GitFileStatus] = [:]

        for line in output.components(separatedBy: .newlines) {
            guard line.count >= 3 else { continue }

            let statusCode = String(line.prefix(2))
            let filePath = String(line.dropFirst(3))

            // Handle renamed files (R  oldpath -> newpath)
            let actualPath: String
            if filePath.contains(" -> ") {
                actualPath = String(filePath.split(separator: " -> ").last ?? "")
            } else {
                actualPath = filePath
            }

            guard !actualPath.isEmpty else { continue }

            let status = GitFileStatus.from(porcelainCode: statusCode)
            statuses[actualPath] = status
        }

        return statuses
    }

    /// Returns paths of deleted files in a directory (files that exist in git but not on disk).
    ///
    /// - Parameter relativePath: Path relative to repository root
    /// - Returns: Array of relative file paths that have been deleted
    public func getDeletedFiles(inDirectory relativePath: String) async throws -> [String] {
        let statuses = try await getFileStatuses(inDirectory: relativePath)
        return statuses.compactMap { path, status in
            status == .deleted ? path : nil
        }
    }

    /// Updates git status for a list of FeatureFileItems based on their paths.
    ///
    /// - Parameters:
    ///   - items: Array of FeatureFileItem to update
    ///   - basePath: Base path of the feature folder relative to repository root
    /// - Returns: Updated array with git status populated
    public func updateFileItemStatuses(_ items: [FeatureFileItem], basePath: String) async throws -> [FeatureFileItem] {
        let rawStatuses = try await getFileStatuses(inDirectory: basePath)

        // Convert full paths to paths relative to feature folder
        // Git outputs: "translations/mobile/login/test/en.json"
        // We need: "test/en.json" (relative to feature folder)
        let prefix = basePath.isEmpty ? "" : basePath + "/"
        var statuses: [String: GitFileStatus] = [:]
        for (path, status) in rawStatuses {
            if path.hasPrefix(prefix) {
                let relativePath = String(path.dropFirst(prefix.count))
                statuses[relativePath] = status
            } else {
                statuses[path] = status
            }
        }

        return items.map { item in
            updateItemStatus(item, statuses: statuses, relativePath: "")
        }
    }

    /// Recursively updates git status for a file item and its children.
    ///
    /// - Parameters:
    ///   - item: The file item to update
    ///   - statuses: Dictionary of relative paths to git status (relative to feature folder)
    ///   - relativePath: Current path relative to feature folder root
    private func updateItemStatus(_ item: FeatureFileItem, statuses: [String: GitFileStatus], relativePath: String) -> FeatureFileItem {
        var updatedItem = item

        // Build path relative to feature root (matches statuses dict keys)
        let itemPath = relativePath.isEmpty ? item.name : "\(relativePath)/\(item.name)"

        // Check if this exact path has a status
        if let status = statuses[itemPath] {
            updatedItem.gitStatus = status
        } else if case .folder = item.type {
            // For folders: check if any child paths start with this folder path
            // This handles folders that contain new/changed files
            let matchingStatus = statuses.first { path, _ in
                path.hasPrefix(itemPath + "/")
            }
            if let (_, status) = matchingStatus {
                updatedItem.gitStatus = status
            }
        }

        // Recursively update children with updated relative path
        if case .folder = item.type {
            updatedItem.children = item.children.map { child in
                updateItemStatus(child, statuses: statuses, relativePath: itemPath)
            }
        }

        return updatedItem
    }

    // MARK: - Discard Operations

    /// Restores a file to its HEAD state (discards uncommitted changes).
    ///
    /// - Parameter relativePath: Path relative to repository root
    public func restoreFile(relativePath: String) async throws {
        _ = try await runGit(["restore", relativePath])
    }

    /// Restores a deleted file from HEAD to both index and worktree.
    /// This handles both staged and unstaged deletions.
    ///
    /// - Parameter relativePath: Path relative to repository root
    public func restoreDeletedFile(relativePath: String) async throws {
        _ = try await runGit(["restore", "--staged", "--worktree", relativePath])
    }

    /// Restores multiple files to their HEAD state (discards uncommitted changes).
    ///
    /// - Parameter relativePaths: Paths relative to repository root
    public func restoreFiles(relativePaths: [String]) async throws {
        guard !relativePaths.isEmpty else { return }
        _ = try await runGit(["restore"] + relativePaths)
    }

    /// Discards all uncommitted changes (both staged and unstaged) and removes untracked files.
    /// This is a destructive operation that cannot be undone.
    public func discardAllChanges() async throws {
        // Reset all staged and unstaged changes
        _ = try await runGit(["reset", "--hard", "HEAD"])

        // Remove untracked files and directories
        _ = try await runGit(["clean", "-fd"])
    }

    // MARK: - Commit Operations

    /// Stages specific files.
    public func addFiles(_ files: [URL]) async throws {
        let relativePaths = files.map { $0.path.replacingOccurrences(of: repositoryURL.path + "/", with: "") }
        _ = try await runGit(["add"] + relativePaths)
    }

    /// Stages all changes.
    public func addAll() async throws {
        _ = try await runGit(["add", "-A"])
    }

    /// Creates a commit with the given message.
    public func commit(message: String) async throws {
        // Check if current branch is protected
        let currentBranch = try await getCurrentBranch()
        guard !configuration.isProtectedBranch(currentBranch) else {
            throw GitError.onProtectedBranch
        }

        _ = try await runGit(["commit", "-m", message])
    }

    /// Stages all changes and creates a commit.
    public func commitAll(message: String) async throws {
        // Check if current branch is protected
        let currentBranch = try await getCurrentBranch()
        guard !configuration.isProtectedBranch(currentBranch) else {
            throw GitError.onProtectedBranch
        }

        try await addAll()
        try await commit(message: message)
    }

    /// Pushes the branch to remote.
    public func push(branch: String, setUpstream: Bool = true) async throws {
        var args = ["push"]
        if setUpstream {
            args += ["-u", "origin", branch]
        } else {
            args += ["origin", branch]
        }
        _ = try await runGit(args)
    }

    // MARK: - PR Creation

    /// Creates a pull request using the GitHub CLI.
    public func createPullRequest(title: String, body: String, baseBranch: String? = nil) async throws -> URL {
        let base = baseBranch ?? configuration.protectedBranches.first ?? "main"

        let prOutput = try await runCommand(
            executable: "/usr/bin/env",
            arguments: [
                "gh", "pr", "create",
                "--title", title,
                "--body", body,
                "--base", base
            ]
        )

        // Extract PR URL from output
        let lines = prOutput.components(separatedBy: .newlines)
        guard let prURLString = lines.first(where: { $0.contains("github.com") }),
              let prURL = URL(string: prURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw GitError.commandFailed("Could not parse PR URL from output: \(prOutput)")
        }

        return prURL
    }

    // MARK: - Full Publish Flow

    /// Commits all changes, pushes, and creates a pull request.
    ///
    /// - Parameters:
    ///   - commitMessage: Message for the commit
    ///   - prTitle: Title for the pull request
    ///   - prBody: Body for the pull request
    /// - Returns: URL of the created pull request
    public func publish(commitMessage: String, prTitle: String, prBody: String) async throws -> URL {
        // Get current branch
        let branch = try await getCurrentBranch()

        // Ensure not on protected branch
        guard !configuration.isProtectedBranch(branch) else {
            throw GitError.onProtectedBranch
        }

        // Add all changes
        try await addAll()

        // Commit
        try await commit(message: commitMessage)

        // Push
        try await push(branch: branch)

        // Create PR
        let prURL = try await createPullRequest(title: prTitle, body: prBody)

        return prURL
    }

    // MARK: - Private Helpers

    @discardableResult
    private func runGit(_ arguments: [String]) async throws -> String {
        try await runCommand(
            executable: "/usr/bin/git",
            arguments: arguments
        )
    }

    /// Nonisolated version for parallel execution
    @discardableResult
    private nonisolated func runGitNonisolated(_ arguments: [String], in repoURL: URL) async throws -> String {
        do {
            return try await ProcessExecutor.run(
                executable: "/usr/bin/git",
                arguments: arguments,
                workingDirectory: repoURL
            )
        } catch let error as ProcessExecutor.ProcessError {
            throw GitError.commandFailed(error.localizedDescription)
        }
    }

    private func runCommand(executable: String, arguments: [String]) async throws -> String {
        do {
            return try await ProcessExecutor.run(
                executable: executable,
                arguments: arguments,
                workingDirectory: repositoryURL
            )
        } catch let error as ProcessExecutor.ProcessError {
            throw GitError.commandFailed(error.localizedDescription)
        }
    }
}
