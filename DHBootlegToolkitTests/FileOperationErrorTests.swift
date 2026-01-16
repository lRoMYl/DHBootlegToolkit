@testable import DHBootlegToolkitCore
import Testing

@Suite("FileOperationError Tests")
struct FileOperationErrorTests {

    @Test("noFeatureSelected has correct description")
    func noFeatureSelectedDescription() {
        let error = FileOperationError.noFeatureSelected
        #expect(error.errorDescription?.contains("No feature selected") == true)
    }

    @Test("fileSystemNotInitialized has correct description")
    func fileSystemNotInitializedDescription() {
        let error = FileOperationError.fileSystemNotInitialized
        #expect(error.errorDescription?.contains("File system not initialized") == true)
    }

    @Test("fileDeleted includes path in description")
    func fileDeletedDescription() {
        let error = FileOperationError.fileDeleted(path: "/path/to/file.json")
        #expect(error.errorDescription?.contains("/path/to/file.json") == true)
        #expect(error.errorDescription?.contains("deleted externally") == true)
    }

    @Test("externallyModified includes path in description")
    func externallyModifiedDescription() {
        let error = FileOperationError.externallyModified(path: "/path/to/file.json")
        #expect(error.errorDescription?.contains("/path/to/file.json") == true)
        #expect(error.errorDescription?.contains("modified externally") == true)
    }

    @Test("saveFailed includes underlying error in description")
    func saveFailedDescription() {
        let error = FileOperationError.saveFailed(underlying: "Permission denied")
        #expect(error.errorDescription?.contains("Permission denied") == true)
    }

    @Test("canForceOverwrite is true only for externallyModified")
    func canForceOverwriteExternallyModified() {
        let externallyModified = FileOperationError.externallyModified(path: "/path")
        #expect(externallyModified.canForceOverwrite == true)
    }

    @Test("canForceOverwrite is false for other errors")
    func canForceOverwriteOtherErrors() {
        #expect(FileOperationError.noFeatureSelected.canForceOverwrite == false)
        #expect(FileOperationError.fileSystemNotInitialized.canForceOverwrite == false)
        #expect(FileOperationError.fileDeleted(path: "/path").canForceOverwrite == false)
        #expect(FileOperationError.saveFailed(underlying: "error").canForceOverwrite == false)
    }

    @Test("Equatable - same cases with same values are equal")
    func equatableSameValues() {
        let error1 = FileOperationError.externallyModified(path: "/path")
        let error2 = FileOperationError.externallyModified(path: "/path")
        #expect(error1 == error2)
    }

    @Test("Equatable - same cases with different values are not equal")
    func equatableDifferentValues() {
        let error1 = FileOperationError.externallyModified(path: "/path1")
        let error2 = FileOperationError.externallyModified(path: "/path2")
        #expect(error1 != error2)
    }

    @Test("Equatable - different cases are not equal")
    func equatableDifferentCases() {
        let error1 = FileOperationError.noFeatureSelected
        let error2 = FileOperationError.fileSystemNotInitialized
        #expect(error1 != error2)
    }
}
