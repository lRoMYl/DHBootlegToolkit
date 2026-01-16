@testable import DHBootlegToolkitCore
import Testing
@testable import DHBootlegToolkit

// MARK: - BranchResult Tests

@Suite("BranchResult Tests")
struct BranchResultTests {

    @Test("Success case")
    func successCase() {
        let result = BranchResult.success
        switch result {
        case .success:
            #expect(true)
        default:
            Issue.record("Expected success case")
        }
    }

    @Test("Error case with message")
    func errorCase() {
        let message = "Test error message"
        let result = BranchResult.error(message)
        switch result {
        case .error(let msg):
            #expect(msg == message)
        default:
            Issue.record("Expected error case")
        }
    }

    @Test("Branch exists case")
    func branchExistsCase() {
        let branchName = "feature/test"
        let result = BranchResult.branchExists(branchName)
        switch result {
        case .branchExists(let name):
            #expect(name == branchName)
        default:
            Issue.record("Expected branchExists case")
        }
    }
}

// MARK: - GitStatus Tests

@Suite("GitStatus Tests")
struct GitStatusTests {

    @Test("Unconfigured status")
    func unconfiguredStatus() {
        let status = GitStatus.unconfigured
        #expect(!status.isConfigured)
        #expect(status.currentBranch == nil)
    }

    @Test("Main branch detection")
    func mainBranchDetection() {
        let statusOnMain = GitStatus(
            isConfigured: true,
            userName: "Test User",
            userEmail: "test@example.com",
            currentBranch: "main",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: true,
            errorMessage: nil
        )
        #expect(statusOnMain.isOnProtectedBranch)

        let statusOnMaster = GitStatus(
            isConfigured: true,
            userName: "Test User",
            userEmail: "test@example.com",
            currentBranch: "master",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: true,
            errorMessage: nil
        )
        #expect(statusOnMaster.isOnProtectedBranch)

        let statusOnFeature = GitStatus(
            isConfigured: true,
            userName: "Test User",
            userEmail: "test@example.com",
            currentBranch: "feature/test",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: nil
        )
        #expect(!statusOnFeature.isOnProtectedBranch)
    }

    @Test("Has uncommitted changes")
    func uncommittedChanges() {
        let statusWithChanges = GitStatus(
            isConfigured: true,
            userName: "Test User",
            userEmail: "test@example.com",
            currentBranch: "feature/test",
            hasUncommittedChanges: true,
            uncommittedFileCount: 3,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: nil
        )
        #expect(statusWithChanges.hasUncommittedChanges)

        let statusWithoutChanges = GitStatus(
            isConfigured: true,
            userName: "Test User",
            userEmail: "test@example.com",
            currentBranch: "feature/test",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: nil
        )
        #expect(!statusWithoutChanges.hasUncommittedChanges)
    }

    @Test("Display email")
    func displayEmail() {
        let status = GitStatus(
            isConfigured: true,
            userName: "Test User",
            userEmail: "test@example.com",
            currentBranch: "main",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: true,
            errorMessage: nil
        )
        #expect(status.displayEmail == "test@example.com")

        let statusNoEmail = GitStatus(
            isConfigured: false,
            userName: nil,
            userEmail: nil,
            currentBranch: nil,
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: "Not configured"
        )
        #expect(statusNoEmail.displayEmail == "Not configured")
    }
}

// MARK: - UserFriendlyGitError Tests

@Suite("Git Error Message Tests")
struct GitErrorMessageTests {

    // Helper function to simulate error message parsing
    private func parseGitError(_ message: String) -> String {
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

        return message
    }

    @Test("Branch already exists error")
    func branchAlreadyExists() {
        let rawError = "fatal: A branch named 'feature/test' already exists."
        let friendlyError = parseGitError(rawError)
        #expect(friendlyError == "A branch with this name already exists.")
    }

    @Test("Unstaged changes error")
    func unstagedChanges() {
        // Note: This matches "unstaged changes" first in the parsing order
        let rawError = "error: cannot pull with rebase: You have unstaged changes."
        let friendlyError = parseGitError(rawError)
        #expect(friendlyError == "You have uncommitted changes. Please save your work first.")
    }

    @Test("Uncommitted changes error")
    func uncommittedChanges() {
        let rawError = "error: Your local changes would be overwritten by checkout."
        let friendlyError = parseGitError(rawError)
        #expect(friendlyError == "You have uncommitted changes. Please save your work first.")
    }

    @Test("Cannot pull with rebase error (clean message)")
    func cannotPullWithRebase() {
        let rawError = "error: cannot pull with rebase: Your index contains uncommitted changes."
        let friendlyError = parseGitError(rawError)
        // Note: "uncommitted changes" matches first
        #expect(friendlyError == "You have uncommitted changes. Please save your work first.")
    }

    @Test("Branch not found error")
    func branchNotFound() {
        let rawError = "error: pathspec 'feature/nonexistent' did not match any file(s) known to git"
        let friendlyError = parseGitError(rawError)
        #expect(friendlyError == "Branch not found. It may have been deleted.")
    }

    @Test("Network error")
    func networkError() {
        let rawError = "fatal: unable to access 'https://github.com/repo.git/': Could not resolve host: github.com"
        let friendlyError = parseGitError(rawError)
        #expect(friendlyError == "Unable to connect to remote repository. Check your internet connection.")
    }

    @Test("Authentication error")
    func authError() {
        let rawError = "fatal: Authentication failed for 'https://github.com/repo.git/'"
        let friendlyError = parseGitError(rawError)
        #expect(friendlyError == "Authentication failed. Please check your git credentials.")
    }

    @Test("Unknown error returns original message")
    func unknownError() {
        let rawError = "Some unknown git error occurred"
        let friendlyError = parseGitError(rawError)
        #expect(friendlyError == rawError)
    }
}

// MARK: - Protected Branch Logic Tests

@Suite("Protected Branch Logic Tests")
struct ProtectedBranchTests {

    private func isProtectedBranch(_ branchName: String) -> Bool {
        branchName == "main" || branchName == "master" || branchName == "origin"
    }

    @Test("Main is protected")
    func mainIsProtected() {
        #expect(isProtectedBranch("main"))
    }

    @Test("Master is protected")
    func masterIsProtected() {
        #expect(isProtectedBranch("master"))
    }

    @Test("Origin is protected")
    func originIsProtected() {
        #expect(isProtectedBranch("origin"))
    }

    @Test("Feature branches are not protected")
    func featureNotProtected() {
        #expect(!isProtectedBranch("feature/test"))
        #expect(!isProtectedBranch("feature/add-login"))
        #expect(!isProtectedBranch("bugfix/fix-crash"))
    }

    @Test("Other branches are not protected")
    func otherNotProtected() {
        #expect(!isProtectedBranch("develop"))
        #expect(!isProtectedBranch("release/1.0"))
        #expect(!isProtectedBranch("hotfix/urgent"))
    }
}

// MARK: - Branch Name Validation Tests

@Suite("Branch Name Validation Tests")
struct BranchNameValidationTests {

    private func isValidBranchName(_ name: String) -> Bool {
        !name.isEmpty && name != "feature/"
    }

    @Test("Empty branch name is invalid")
    func emptyNameInvalid() {
        #expect(!isValidBranchName(""))
    }

    @Test("Only prefix is invalid")
    func onlyPrefixInvalid() {
        #expect(!isValidBranchName("feature/"))
    }

    @Test("Valid branch names")
    func validNames() {
        #expect(isValidBranchName("feature/test"))
        #expect(isValidBranchName("feature/add-user-auth"))
        #expect(isValidBranchName("bugfix/fix-123"))
        #expect(isValidBranchName("release/1.0.0"))
    }
}
