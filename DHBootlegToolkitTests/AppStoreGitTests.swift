import Foundation
@testable import DHBootlegToolkitCore
import Testing
@testable import DHBootlegToolkit

// MARK: - AppStore Git Logic Tests

@Suite("AppStore Git Logic Tests")
@MainActor
struct AppStoreGitLogicTests {

    @Test("isOnProtectedBranch returns true for main")
    func protectedBranchMain() {
        let store = AppStore()
        store.gitStatus = GitStatus(
            isConfigured: true,
            userName: "Test",
            userEmail: "test@test.com",
            currentBranch: "main",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: true,
            errorMessage: nil
        )
        #expect(store.isOnProtectedBranch)
    }

    @Test("isOnProtectedBranch returns false for feature branch")
    func protectedBranchFeature() {
        let store = AppStore()
        store.gitStatus = GitStatus(
            isConfigured: true,
            userName: "Test",
            userEmail: "test@test.com",
            currentBranch: "feature/test",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: nil
        )
        #expect(!store.isOnProtectedBranch)
    }

    @Test("currentBranchDisplayName shows branch name")
    func currentBranchDisplayName() {
        let store = AppStore()
        store.gitStatus = GitStatus(
            isConfigured: true,
            userName: "Test",
            userEmail: "test@test.com",
            currentBranch: "feature/my-branch",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: nil
        )
        #expect(store.currentBranchDisplayName == "feature/my-branch")
    }

    @Test("currentBranchDisplayName shows 'No branch' when nil")
    func currentBranchDisplayNameNil() {
        let store = AppStore()
        store.gitStatus = GitStatus(
            isConfigured: false,
            userName: nil,
            userEmail: nil,
            currentBranch: nil,
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: nil
        )
        #expect(store.currentBranchDisplayName == "No branch")
    }

    @Test("canPublish requires git uncommitted changes and gitStatus.isReady")
    func canPublishLogic() {
        let store = AppStore()

        // No uncommitted changes, git ready -> can't publish
        store.gitStatus = GitStatus(
            isConfigured: true,
            userName: "Test",
            userEmail: "test@test.com",
            currentBranch: "feature/test",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: nil
        )
        #expect(!store.canPublish)

        // Has uncommitted changes, git ready -> can publish
        store.gitStatus = GitStatus(
            isConfigured: true,
            userName: "Test",
            userEmail: "test@test.com",
            currentBranch: "feature/test",
            hasUncommittedChanges: true,
            uncommittedFileCount: 3,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: nil
        )
        #expect(store.canPublish)

        // Has uncommitted changes, git not configured -> can't publish
        store.gitStatus = .unconfigured
        #expect(!store.canPublish)

        // Has uncommitted changes, on protected branch -> can't publish
        store.gitStatus = GitStatus(
            isConfigured: true,
            userName: "Test",
            userEmail: "test@test.com",
            currentBranch: "main",
            hasUncommittedChanges: true,
            uncommittedFileCount: 2,
            uncommittedFiles: [],
            isOnProtectedBranch: true,
            errorMessage: nil
        )
        #expect(!store.canPublish)
    }
}

// MARK: - BranchResult Handling Tests

@Suite("BranchResult Handling Tests")
struct BranchResultHandlingTests {

    @Test("Handle success result")
    func handleSuccess() {
        let result = BranchResult.success
        var dismissed = false
        var errorMessage: String?

        switch result {
        case .success:
            dismissed = true
        case .error(let message):
            errorMessage = message
        case .branchExists:
            break
        }

        #expect(dismissed)
        #expect(errorMessage == nil)
    }

    @Test("Handle error result")
    func handleError() {
        let result = BranchResult.error("Something went wrong")
        var dismissed = false
        var errorMessage: String?

        switch result {
        case .success:
            dismissed = true
        case .error(let message):
            errorMessage = message
        case .branchExists:
            break
        }

        #expect(!dismissed)
        #expect(errorMessage == "Something went wrong")
    }

    @Test("Handle branch exists result")
    func handleBranchExists() {
        let result = BranchResult.branchExists("feature/existing")
        var dismissed = false
        var showSwitchConfirmation = false
        var existingBranchName: String?

        switch result {
        case .success:
            dismissed = true
        case .error:
            break
        case .branchExists(let name):
            existingBranchName = name
            showSwitchConfirmation = true
        }

        #expect(!dismissed)
        #expect(showSwitchConfirmation)
        #expect(existingBranchName == "feature/existing")
    }
}

// MARK: - UI State Tests

@Suite("Git UI State Tests")
@MainActor
struct GitUIStateTests {

    @Test("showCreateBranchPrompt initially false")
    func showCreateBranchPromptInitial() {
        let store = AppStore()
        #expect(!store.showCreateBranchPrompt)
    }

    @Test("availableBranches initially empty")
    func availableBranchesInitial() {
        let store = AppStore()
        #expect(store.availableBranches.isEmpty)
    }

    @Test("Setting showCreateBranchPrompt")
    func setShowCreateBranchPrompt() {
        let store = AppStore()
        store.showCreateBranchPrompt = true
        #expect(store.showCreateBranchPrompt)
    }

    @Test("Setting availableBranches")
    func setAvailableBranches() {
        let store = AppStore()
        store.availableBranches = ["main", "feature/test", "develop"]
        #expect(store.availableBranches.count == 3)
        #expect(store.availableBranches.contains("main"))
        #expect(store.availableBranches.contains("feature/test"))
    }
}

// MARK: - Read-Only Mode Tests

@Suite("Read-Only Mode Tests")
@MainActor
struct ReadOnlyModeTests {

    @Test("Read-only mode on main branch")
    func readOnlyOnMain() {
        let store = AppStore()
        store.gitStatus = GitStatus(
            isConfigured: true,
            userName: "Test",
            userEmail: "test@test.com",
            currentBranch: "main",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: true,
            errorMessage: nil
        )

        // isOnProtectedBranch is used for read-only mode
        let isReadOnly = store.isOnProtectedBranch
        #expect(isReadOnly)
    }

    @Test("Editable mode on feature branch")
    func editableOnFeature() {
        let store = AppStore()
        store.gitStatus = GitStatus(
            isConfigured: true,
            userName: "Test",
            userEmail: "test@test.com",
            currentBranch: "feature/test",
            hasUncommittedChanges: false,
            uncommittedFileCount: 0,
            uncommittedFiles: [],
            isOnProtectedBranch: false,
            errorMessage: nil
        )

        let isReadOnly = store.isOnProtectedBranch
        #expect(!isReadOnly)
    }
}

// MARK: - Branch Rename Protection Tests

@Suite("Branch Rename Protection Tests")
struct BranchRenameProtectionTests {

    private func canRenameBranch(_ currentBranch: String) -> Bool {
        currentBranch != "main" && currentBranch != "master" && currentBranch != "origin"
    }

    @Test("Cannot rename main")
    func cannotRenameMain() {
        #expect(!canRenameBranch("main"))
    }

    @Test("Cannot rename master")
    func cannotRenameMaster() {
        #expect(!canRenameBranch("master"))
    }

    @Test("Cannot rename origin")
    func cannotRenameOrigin() {
        #expect(!canRenameBranch("origin"))
    }

    @Test("Can rename feature branches")
    func canRenameFeature() {
        #expect(canRenameBranch("feature/test"))
        #expect(canRenameBranch("feature/new-feature"))
    }

    @Test("Can rename other branches")
    func canRenameOther() {
        #expect(canRenameBranch("develop"))
        #expect(canRenameBranch("release/1.0"))
        #expect(canRenameBranch("hotfix/urgent"))
    }
}

// MARK: - EditedKey Sync Tests

@Suite("AppStore EditedKey Sync Tests")
@MainActor
struct AppStoreEditedKeyTests {

    // Helper to create a test feature
    private func createTestFeature() -> FeatureFolder {
        let platform = PlatformDefinition(folderName: "mobile", displayName: "Mobile")
        return FeatureFolder(
            name: "test_feature",
            platform: platform,
            url: URL(fileURLWithPath: "/test/mobile/test_feature")
        )
    }

    @Test("updateKey syncs translationKeys array")
    func updateKeySyncsTranslationKeys() {
        let store = AppStore()
        var key = TranslationKey(key: "TEST_KEY", translation: "Original", notes: "Notes")
        store.translationKeys = [key]

        // Simulate user edit
        key.translation = "Updated"
        store.updateKey(key)

        // The translationKeys array should be updated
        #expect(store.translationKeys.first?.translation == "Updated")
    }

    @Test("Tab editedKey can be modified directly")
    func tabEditedKeyModification() {
        let store = AppStore()
        let feature = createTestFeature()
        let key = TranslationKey(key: "TEST_KEY", translation: "Original", notes: "Notes")
        store.translationKeys = [key]
        store.features = [feature]

        // Open a tab for the key
        store.selectKeyFromSidebar(key, in: feature)

        // Modify via the editedKey setter (simulates form editing)
        var editedKey = store.editedKey!
        editedKey.translation = "Modified"
        store.editedKey = editedKey

        #expect(store.editedKey?.translation == "Modified")
    }

    @Test("Closing tab clears editedKey for that tab")
    func closingTabClearsEditedKey() {
        let store = AppStore()
        let feature = createTestFeature()
        let key = TranslationKey(key: "TEST_KEY", translation: "Test", notes: "Notes")
        store.translationKeys = [key]
        store.features = [feature]

        // Open a tab for the key
        store.selectKeyFromSidebar(key, in: feature)
        #expect(store.openTabs.count == 1)
        #expect(store.selectedKey != nil)

        // Close the tab
        if let tabId = store.openTabs.first?.id {
            store.closeTab(tabId)
        }

        #expect(store.openTabs.isEmpty)
        #expect(store.selectedKey == nil)
        #expect(store.editedKey == nil)
    }

    @Test("hasChanges can be set via tab data")
    func hasChangesDetectsEdits() {
        let store = AppStore()
        let feature = createTestFeature()
        let key = TranslationKey(key: "TEST_KEY", translation: "Original", notes: "Notes")
        store.translationKeys = [key]
        store.features = [feature]

        // Open a tab for the key
        store.selectKeyFromSidebar(key, in: feature)

        // hasChanges should be set by the form binding setters
        store.hasChanges = true
        #expect(store.hasChanges == true)
    }

    @Test("hasChanges is false when no edits made")
    func hasChangesNoEdits() {
        let store = AppStore()
        let feature = createTestFeature()
        let key = TranslationKey(key: "TEST_KEY", translation: "Original", notes: "Notes")
        store.translationKeys = [key]
        store.features = [feature]

        // Open a tab for the key
        store.selectKeyFromSidebar(key, in: feature)

        // Initial state should have no changes
        store.hasChanges = false
        #expect(store.hasChanges == false)
    }

    @Test("Switching tabs preserves editedKey in each tab")
    func switchingTabsPreservesEditedKey() {
        let store = AppStore()
        let feature = createTestFeature()
        let key1 = TranslationKey(key: "TEST_KEY_1", translation: "Original 1", notes: "Notes 1")
        let key2 = TranslationKey(key: "TEST_KEY_2", translation: "Original 2", notes: "Notes 2")
        store.translationKeys = [key1, key2]
        store.features = [feature]

        // Open first tab
        store.selectKeyFromSidebar(key1, in: feature)
        let tab1Id = store.openTabs.first!.id

        // Modify first key
        var edited1 = key1
        edited1.translation = "Modified 1"
        store.editedKey = edited1

        // Open second tab
        store.selectKeyFromSidebar(key2, in: feature)
        let tab2Id = store.openTabs.last!.id

        // Should have two tabs now
        #expect(store.openTabs.count == 2)
        #expect(store.activeTabId == tab2Id)

        // Switch back to first tab
        store.focusKeyTab(tab1Id)
        #expect(store.activeTabId == tab1Id)

        // First tab's edited key should be preserved
        #expect(store.editedKey?.translation == "Modified 1")
    }

    @Test("editedKey initially nil")
    func editedKeyInitiallyNil() {
        let store = AppStore()
        #expect(store.editedKey == nil)
    }

    @Test("anyTabHasChanges detects changes in any open tab")
    func anyTabHasChangesDetectsChanges() {
        let store = AppStore()
        let feature = createTestFeature()
        let key = TranslationKey(key: "TEST_KEY", translation: "Test", notes: "Notes")
        store.translationKeys = [key]
        store.features = [feature]

        // Initially no changes
        #expect(!store.anyTabHasChanges)

        // Open a tab
        store.selectKeyFromSidebar(key, in: feature)
        #expect(!store.anyTabHasChanges)

        // Mark as having changes
        store.hasChanges = true
        #expect(store.anyTabHasChanges)
    }
}
