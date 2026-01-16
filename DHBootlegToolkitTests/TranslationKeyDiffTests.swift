@testable import DHBootlegToolkitCore
import Testing
@testable import DHBootlegToolkit

@Suite("TranslationKeyDiff Tests")
struct TranslationKeyDiffTests {

    @Test("Empty diff has no changes")
    func emptyDiff() {
        let diff = TranslationKeyDiff.empty
        #expect(!diff.hasChanges)
        #expect(diff.totalChanges == 0)
        #expect(diff.featureId.isEmpty)
        #expect(diff.filePath.isEmpty)
    }

    @Test("Added keys are detected")
    func addedKeys() {
        let diff = TranslationKeyDiff(
            featureId: "test",
            filePath: "test/en.json",
            addedKeys: ["NEW_KEY", "ANOTHER_NEW"],
            modifiedKeys: [],
            deletedKeys: [],
            isNewFile: false,
            isDeletedFile: false
        )

        #expect(diff.hasChanges)
        #expect(diff.addedKeys.count == 2)
        #expect(diff.status(for: "NEW_KEY") == .added)
        #expect(diff.status(for: "ANOTHER_NEW") == .added)
        #expect(diff.status(for: "EXISTING_KEY") == .unchanged)
    }

    @Test("Modified keys are detected")
    func modifiedKeys() {
        let diff = TranslationKeyDiff(
            featureId: "test",
            filePath: "test/en.json",
            addedKeys: [],
            modifiedKeys: ["CHANGED_KEY", "UPDATED_KEY"],
            deletedKeys: [],
            isNewFile: false,
            isDeletedFile: false
        )

        #expect(diff.hasChanges)
        #expect(diff.modifiedKeys.count == 2)
        #expect(diff.status(for: "CHANGED_KEY") == .modified)
        #expect(diff.status(for: "UPDATED_KEY") == .modified)
    }

    @Test("Deleted keys are detected")
    func deletedKeys() {
        let diff = TranslationKeyDiff(
            featureId: "test",
            filePath: "test/en.json",
            addedKeys: [],
            modifiedKeys: [],
            deletedKeys: ["REMOVED_KEY"],
            isNewFile: false,
            isDeletedFile: false
        )

        #expect(diff.hasChanges)
        #expect(diff.deletedKeys.count == 1)
        #expect(diff.status(for: "REMOVED_KEY") == .deleted)
    }

    @Test("New file marks all keys as added")
    func newFile() {
        let diff = TranslationKeyDiff(
            featureId: "test",
            filePath: "test/en.json",
            addedKeys: ["KEY1", "KEY2", "KEY3"],
            modifiedKeys: [],
            deletedKeys: [],
            isNewFile: true,
            isDeletedFile: false
        )

        #expect(diff.isNewFile)
        #expect(!diff.isDeletedFile)
        #expect(diff.addedKeys.count == 3)
        #expect(diff.hasChanges)
    }

    @Test("Deleted file marks all keys as deleted")
    func deletedFile() {
        let diff = TranslationKeyDiff(
            featureId: "test",
            filePath: "test/en.json",
            addedKeys: [],
            modifiedKeys: [],
            deletedKeys: ["KEY1", "KEY2"],
            isNewFile: false,
            isDeletedFile: true
        )

        #expect(diff.isDeletedFile)
        #expect(!diff.isNewFile)
        #expect(diff.deletedKeys.count == 2)
        #expect(diff.hasChanges)
    }

    @Test("Total changes count")
    func totalChanges() {
        let diff = TranslationKeyDiff(
            featureId: "test",
            filePath: "test/en.json",
            addedKeys: ["A", "B"],
            modifiedKeys: ["C"],
            deletedKeys: ["D", "E", "F"],
            isNewFile: false,
            isDeletedFile: false
        )

        #expect(diff.totalChanges == 6)
        #expect(diff.addedKeys.count == 2)
        #expect(diff.modifiedKeys.count == 1)
        #expect(diff.deletedKeys.count == 3)
    }

    @Test("Mixed changes")
    func mixedChanges() {
        let diff = TranslationKeyDiff(
            featureId: "feature_login",
            filePath: "mobile/login/en.json",
            addedKeys: ["NEW_KEY"],
            modifiedKeys: ["EDITED_KEY"],
            deletedKeys: ["OLD_KEY"],
            isNewFile: false,
            isDeletedFile: false
        )

        #expect(diff.hasChanges)
        #expect(diff.status(for: "NEW_KEY") == .added)
        #expect(diff.status(for: "EDITED_KEY") == .modified)
        #expect(diff.status(for: "OLD_KEY") == .deleted)
        #expect(diff.status(for: "UNCHANGED_KEY") == .unchanged)
    }
}

@Suite("KeyChangeStatus Tests")
struct KeyChangeStatusTests {

    @Test("Added status properties")
    func addedStatus() {
        let status = KeyChangeStatus.added
        #expect(status.systemImage == "plus.circle.fill")
    }

    @Test("Modified status properties")
    func modifiedStatus() {
        let status = KeyChangeStatus.modified
        #expect(status.systemImage == "pencil.circle.fill")
    }

    @Test("Deleted status properties")
    func deletedStatus() {
        let status = KeyChangeStatus.deleted
        #expect(status.systemImage == "minus.circle.fill")
    }

    @Test("Unchanged status has no indicator")
    func unchangedStatus() {
        let status = KeyChangeStatus.unchanged
        #expect(status.systemImage == nil)
    }
}
