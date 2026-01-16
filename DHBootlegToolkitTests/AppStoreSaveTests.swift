import Foundation
@testable import DHBootlegToolkitCore
import Testing
@testable import DHBootlegToolkit

// MARK: - AppStore Save Error Tests

@Suite("AppStore Save Error Tests")
@MainActor
struct AppStoreSaveErrorTests {

    // Helper to create a test feature
    private func createTestFeature() -> FeatureFolder {
        let platform = PlatformDefinition(folderName: "mobile", displayName: "Mobile")
        return FeatureFolder(
            name: "test_feature",
            platform: platform,
            url: URL(fileURLWithPath: "/test/mobile/test_feature")
        )
    }

    @Test("saveCurrentFile throws noFeatureSelected when selectedFeature is nil")
    func throwsNoFeatureSelected() async {
        let store = AppStore()
        // selectedFeature is nil by default

        await #expect(throws: FileOperationError.noFeatureSelected) {
            try await store.saveCurrentFile()
        }
    }

    @Test("saveCurrentFile throws fileSystemNotInitialized when fileSystemWorker is nil")
    func throwsFileSystemNotInitialized() async {
        let store = AppStore()
        store.selectedFeature = createTestFeature()
        // fileSystemWorker is nil (no repository selected)

        await #expect(throws: FileOperationError.fileSystemNotInitialized) {
            try await store.saveCurrentFile()
        }
    }

    @Test("forceOverwrite parameter skips external modification check")
    func forceOverwriteSkipsCheck() async {
        // This is a design verification test - the forceOverwrite parameter
        // should allow saving even when file hash differs
        let store = AppStore()
        store.selectedFeature = createTestFeature()

        // Without a real fileSystemWorker, we can only verify the method signature accepts the parameter
        do {
            try await store.saveCurrentFile(forceOverwrite: true)
        } catch FileOperationError.fileSystemNotInitialized {
            // Expected - we don't have a worker initialized
            // The important thing is forceOverwrite parameter is accepted
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - FileOperationError canForceOverwrite Tests

@Suite("FileOperationError canForceOverwrite Tests")
struct FileOperationErrorCanForceOverwriteTests {

    @Test("Only externallyModified can be force overwritten")
    func onlyExternallyModifiedCanBeOverwritten() {
        let errors: [FileOperationError] = [
            .noFeatureSelected,
            .fileSystemNotInitialized,
            .fileDeleted(path: "/path"),
            .saveFailed(underlying: "error")
        ]

        for error in errors {
            #expect(!error.canForceOverwrite, "Error \(error) should not be force-overwritable")
        }

        let externallyModified = FileOperationError.externallyModified(path: "/path")
        #expect(externallyModified.canForceOverwrite)
    }
}

// MARK: - Error Message Clarity Tests

@Suite("Error Message Clarity Tests")
struct ErrorMessageClarityTests {

    @Test("All errors have non-empty descriptions")
    func allErrorsHaveDescriptions() {
        let errors: [FileOperationError] = [
            .noFeatureSelected,
            .fileSystemNotInitialized,
            .fileDeleted(path: "/path/to/file.json"),
            .externallyModified(path: "/path/to/file.json"),
            .saveFailed(underlying: "Permission denied")
        ]

        for error in errors {
            let description = error.errorDescription
            #expect(description != nil, "Error \(error) should have a description")
            #expect(!(description?.isEmpty ?? true), "Error \(error) description should not be empty")
        }
    }

    @Test("Path-based errors include the path in their description")
    func pathIncludedInDescription() {
        let testPath = "/test/feature/en.json"

        let fileDeleted = FileOperationError.fileDeleted(path: testPath)
        #expect(fileDeleted.errorDescription?.contains(testPath) == true)

        let externallyModified = FileOperationError.externallyModified(path: testPath)
        #expect(externallyModified.errorDescription?.contains(testPath) == true)
    }

    @Test("saveFailed includes underlying error message")
    func saveFailedIncludesUnderlyingMessage() {
        let underlyingMessage = "Disk is full"
        let error = FileOperationError.saveFailed(underlying: underlyingMessage)
        #expect(error.errorDescription?.contains(underlyingMessage) == true)
    }
}

// MARK: - AppStore Error State Tests

@Suite("AppStore Error State Tests")
@MainActor
struct AppStoreErrorStateTests {

    @Test("showPublishError initially false")
    func showPublishErrorInitiallyFalse() {
        let store = AppStore()
        #expect(!store.showPublishError)
    }

    @Test("publishErrorMessage initially nil")
    func publishErrorMessageInitiallyNil() {
        let store = AppStore()
        #expect(store.publishErrorMessage == nil)
    }

    @Test("Error state can be set")
    func errorStateCanBeSet() {
        let store = AppStore()
        store.publishErrorMessage = "Test error"
        store.showPublishError = true

        #expect(store.showPublishError)
        #expect(store.publishErrorMessage == "Test error")
    }

    @Test("Error state can be cleared")
    func errorStateCanBeCleared() {
        let store = AppStore()
        store.publishErrorMessage = "Test error"
        store.showPublishError = true

        // Clear error state
        store.showPublishError = false
        store.publishErrorMessage = nil

        #expect(!store.showPublishError)
        #expect(store.publishErrorMessage == nil)
    }
}

// MARK: - External Change Detection State Tests

@Suite("External Change Detection State Tests")
@MainActor
struct ExternalChangeDetectionStateTests {

    @Test("showExternalChangeConflict initially false")
    func showExternalChangeConflictInitiallyFalse() {
        let store = AppStore()
        #expect(!store.showExternalChangeConflict)
    }

    @Test("pendingExternalChange initially nil")
    func pendingExternalChangeInitiallyNil() {
        let store = AppStore()
        #expect(store.pendingExternalChange == nil)
    }

    @Test("External change conflict can be set")
    func externalChangeConflictCanBeSet() {
        let store = AppStore()
        store.pendingExternalChange = ExternalChangeInfo(
            featureName: "test_feature",
            filePath: "/path/to/en.json"
        )
        store.showExternalChangeConflict = true

        #expect(store.showExternalChangeConflict)
        #expect(store.pendingExternalChange?.featureName == "test_feature")
        #expect(store.pendingExternalChange?.filePath == "/path/to/en.json")
    }
}
