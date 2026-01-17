@testable import DHBootlegToolkit
@testable import DHBootlegToolkitCore
import Testing
import Foundation

// MARK: - JSON Tree Badge Computation Tests

@Suite("JSON Tree Badge Computation Tests")
struct JSONTreeBadgeComputationTests {

    /// Helper to create a JSONTreeViewModel with given JSON and original JSON
    private func createViewModel(
        json: [String: Any],
        originalJSON: [String: Any]? = nil,
        fileGitStatus: GitFileStatus? = nil,
        editedPaths: Set<String> = []
    ) -> JSONTreeViewModel {
        let viewModel = JSONTreeViewModel()
        viewModel.configure(
            json: json,
            expandAllByDefault: false,
            manuallyCollapsed: [],
            originalJSON: originalJSON,
            fileGitStatus: fileGitStatus,
            hasInMemoryChanges: !editedPaths.isEmpty,
            editedPaths: editedPaths,
            showChangedFieldsOnly: false
        )
        return viewModel
    }

    // MARK: - Basic Badge Tests

    @Test("Unchanged fields show no badge")
    func unchangedFieldsShowNoBadge() {
        // Arrange: Same JSON in both current and original
        let json: [String: Any] = [
            "field1": "value1",
            "field2": true,
            "field3": 42
        ]

        let viewModel = createViewModel(
            json: json,
            originalJSON: json,
            fileGitStatus: .unchanged
        )

        // Assert: No badges on any field
        #expect(viewModel.pathChangeStatus["field1"] == nil)
        #expect(viewModel.pathChangeStatus["field2"] == nil)
        #expect(viewModel.pathChangeStatus["field3"] == nil)
    }

    @Test("Modified field shows [M] badge")
    func modifiedFieldShowsBadge() {
        // Arrange: Field value changed
        let original: [String: Any] = [
            "field1": "original_value",
            "field2": true
        ]

        let current: [String: Any] = [
            "field1": "modified_value",  // Changed
            "field2": true               // Unchanged
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Only modified field has badge
        #expect(viewModel.pathChangeStatus["field1"] == .modified)
        #expect(viewModel.pathChangeStatus["field2"] == nil)
    }

    @Test("Added field shows [A] badge")
    func addedFieldShowsBadge() {
        // Arrange: New field added
        let original: [String: Any] = [
            "existing_field": "value"
        ]

        let current: [String: Any] = [
            "existing_field": "value",
            "new_field": "new_value"  // Added
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Only new field has added badge
        #expect(viewModel.pathChangeStatus["existing_field"] == nil)
        #expect(viewModel.pathChangeStatus["new_field"] == .added)
    }

    @Test("Deleted field shows [D] badge")
    func deletedFieldShowsBadge() {
        // Arrange: Field removed
        let original: [String: Any] = [
            "field1": "value1",
            "field2": "value2"
        ]

        let current: [String: Any] = [
            "field1": "value1"
            // field2 deleted
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Deleted field has badge, remaining field doesn't
        #expect(viewModel.pathChangeStatus["field1"] == nil)
        #expect(viewModel.pathChangeStatus["field2"] == .deleted)
    }

    // MARK: - Nested Structure Tests

    @Test("Modified nested field shows [M] badge")
    func modifiedNestedFieldShowsBadge() {
        // Arrange: Nested field changed
        let original: [String: Any] = [
            "parent": [
                "child": "original_value",
                "other": "unchanged"
            ]
        ]

        let current: [String: Any] = [
            "parent": [
                "child": "modified_value",
                "other": "unchanged"
            ]
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Only modified nested field has badge
        #expect(viewModel.pathChangeStatus["parent"] == nil)
        #expect(viewModel.pathChangeStatus["parent.child"] == .modified)
        #expect(viewModel.pathChangeStatus["parent.other"] == nil)
    }

    @Test("Deleted nested object shows [D] on all children")
    func deletedNestedObjectShowsBadgeOnAllChildren() {
        // Arrange: Entire nested object deleted
        let original: [String: Any] = [
            "keep": "value",
            "delete_parent": [
                "child1": "value1",
                "child2": [
                    "grandchild": "value2"
                ]
            ]
        ]

        let current: [String: Any] = [
            "keep": "value"
            // delete_parent removed entirely
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Parent and all children show deleted badge
        #expect(viewModel.pathChangeStatus["keep"] == nil)
        #expect(viewModel.pathChangeStatus["delete_parent"] == .deleted)
        #expect(viewModel.pathChangeStatus["delete_parent.child1"] == .deleted)
        #expect(viewModel.pathChangeStatus["delete_parent.child2"] == .deleted)
        #expect(viewModel.pathChangeStatus["delete_parent.child2.grandchild"] == .deleted)
    }

    @Test("Added nested object shows [A] on all children")
    func addedNestedObjectShowsBadgeOnAllChildren() {
        // Arrange: New nested object added
        let original: [String: Any] = [
            "existing": "value"
        ]

        let current: [String: Any] = [
            "existing": "value",
            "new_parent": [
                "child1": "value1",
                "child2": [
                    "grandchild": "value2"
                ]
            ]
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Leaf nodes show added badge (parent containers don't get badges)
        #expect(viewModel.pathChangeStatus["existing"] == nil)
        // Parent containers (objects) don't get change status badges
        #expect(viewModel.pathChangeStatus["new_parent"] == nil)
        #expect(viewModel.pathChangeStatus["new_parent.child1"] == .added)
        #expect(viewModel.pathChangeStatus["new_parent.child2"] == nil)
        #expect(viewModel.pathChangeStatus["new_parent.child2.grandchild"] == .added)
    }

    // MARK: - Sparse Restoration Tests

    @Test("Sparse JSON after deletion shows [D] on all original fields")
    func sparseJSONShowsDeletedBadgeOnAllOriginalFields() {
        // Arrange: Sparse JSON with only one edited field
        let original: [String: Any] = [
            "data": [
                "feature_flags": [
                    "dark_mode": false,
                    "new_ui": true
                ],
                "subscription": [
                    "enabled": false,
                    "plans": ["basic", "premium"]
                ]
            ]
        ]

        let sparse: [String: Any] = [
            "data": [
                "feature_flags": [
                    "dark_mode": true  // Only edited field
                ]
            ]
        ]

        let viewModel = createViewModel(
            json: sparse,
            originalJSON: original,
            fileGitStatus: .deleted,
            editedPaths: ["data.feature_flags.dark_mode"]
        )

        // Assert: Edited field shows its actual change (modified), unedited fields show deleted
        #expect(viewModel.pathChangeStatus["data.feature_flags.dark_mode"] == .modified)  // Edited: false -> true
        #expect(viewModel.pathChangeStatus["data.feature_flags.new_ui"] == .deleted)      // Not in sparse, deleted
        #expect(viewModel.pathChangeStatus["data.subscription"] == .deleted)              // Not in sparse, deleted
        #expect(viewModel.pathChangeStatus["data.subscription.enabled"] == .deleted)
        #expect(viewModel.pathChangeStatus["data.subscription.plans"] == .deleted)
    }

    @Test("Editing deleted field in sparse JSON shows correct badge")
    func editingDeletedFieldInSparseJSONShowsCorrectBadge() {
        // Arrange: Sparse JSON with edited field (simulating user edit after restore)
        let original: [String: Any] = [
            "data": [
                "field1": "original",
                "field2": "original"
            ]
        ]

        let sparse: [String: Any] = [
            "data": [
                "field1": "edited"  // User edited this after restore
            ]
        ]

        let viewModel = createViewModel(
            json: sparse,
            originalJSON: original,
            fileGitStatus: .deleted,
            editedPaths: ["data.field1"]
        )

        // Assert: Edited field shows its actual change (modified), unedited shows deleted
        #expect(viewModel.pathChangeStatus["data.field1"] == .modified)  // original -> edited
        #expect(viewModel.pathChangeStatus["data.field2"] == .deleted)   // Not in current, deleted
    }

    // MARK: - EditedPaths Integration Tests

    @Test("Deleted file shows [D] on unchanged fields, [M] on edited fields")
    func deletedFileShowsCorrectBadgesForEditedAndUnchangedFields() {
        // Arrange: Deleted file with some edits
        let original: [String: Any] = [
            "field1": "value1",
            "field2": "value2",
            "field3": "value3"
        ]

        let current: [String: Any] = [
            "field1": "modified",  // Edited
            "field2": "value2",    // Not edited, same value
            "field3": "value3"     // Not edited, same value
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .deleted,
            editedPaths: ["field1"]
        )

        // Assert: Edited field shows modified, unchanged fields show deleted (file is deleted)
        #expect(viewModel.pathChangeStatus["field1"] == .modified)  // value1 -> modified
        #expect(viewModel.pathChangeStatus["field2"] == .deleted)   // File deleted, so field deleted
        #expect(viewModel.pathChangeStatus["field3"] == .deleted)   // File deleted, so field deleted
    }

    @Test("EditedPaths track field-level changes for modified files")
    func editedPathsTrackFieldLevelChangesForModifiedFiles() {
        // Arrange: Modified file with some edits
        let original: [String: Any] = [
            "field1": "value1",
            "field2": "value2"
        ]

        let current: [String: Any] = [
            "field1": "modified",
            "field2": "value2"
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified,
            editedPaths: ["field1"]
        )

        // Assert: Modified field shows modified badge
        #expect(viewModel.pathChangeStatus["field1"] == .modified)
        #expect(viewModel.pathChangeStatus["field2"] == nil)
    }

    // MARK: - Array Handling Tests

    @Test("Array element modification shows [M] badge")
    func arrayElementModificationShowsBadge() {
        // Arrange: Array element changed
        let original: [String: Any] = [
            "items": ["apple", "banana", "cherry"]
        ]

        let current: [String: Any] = [
            "items": ["apple", "orange", "cherry"]  // banana -> orange
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Changed element has badge
        #expect(viewModel.pathChangeStatus["items"] == nil)
        #expect(viewModel.pathChangeStatus["items.[0]"] == nil)  // unchanged
        #expect(viewModel.pathChangeStatus["items.[1]"] == .modified)  // changed
        #expect(viewModel.pathChangeStatus["items.[2]"] == nil)  // unchanged
    }

    @Test("Array with new element shows [A] badge on new element")
    func arrayWithNewElementShowsBadge() {
        // Arrange: New element added to array
        let original: [String: Any] = [
            "items": ["item1", "item2"]
        ]

        let current: [String: Any] = [
            "items": ["item1", "item2", "item3"]
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Only new element has badge
        #expect(viewModel.pathChangeStatus["items.[0]"] == nil)
        #expect(viewModel.pathChangeStatus["items.[1]"] == nil)
        #expect(viewModel.pathChangeStatus["items.[2]"] == .added)
    }

    @Test("Deleted array shows [D] on all elements")
    func deletedArrayShowsBadgeOnAllElements() {
        // Arrange: Entire array deleted
        let original: [String: Any] = [
            "keep": "value",
            "delete_array": ["item1", "item2", "item3"]
        ]

        let current: [String: Any] = [
            "keep": "value"
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Array and all elements show deleted
        #expect(viewModel.pathChangeStatus["delete_array"] == .deleted)
        #expect(viewModel.pathChangeStatus["delete_array.[0]"] == .deleted)
        #expect(viewModel.pathChangeStatus["delete_array.[1]"] == .deleted)
        #expect(viewModel.pathChangeStatus["delete_array.[2]"] == .deleted)
    }

    // MARK: - Complex Scenarios

    @Test("Mixed changes show correct badges")
    func mixedChangesShowCorrectBadges() {
        // Arrange: Multiple types of changes
        let original: [String: Any] = [
            "unchanged": "value",
            "modified": "old_value",
            "deleted": "will_be_deleted",
            "nested": [
                "keep": "value",
                "change": "old"
            ]
        ]

        let current: [String: Any] = [
            "unchanged": "value",
            "modified": "new_value",
            "new": "added_value",
            "nested": [
                "keep": "value",
                "change": "new",
                "added": "new_nested"
            ]
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Each field has correct badge
        #expect(viewModel.pathChangeStatus["unchanged"] == nil)
        #expect(viewModel.pathChangeStatus["modified"] == .modified)
        #expect(viewModel.pathChangeStatus["deleted"] == .deleted)
        #expect(viewModel.pathChangeStatus["new"] == .added)
        #expect(viewModel.pathChangeStatus["nested.keep"] == nil)
        #expect(viewModel.pathChangeStatus["nested.change"] == .modified)
        #expect(viewModel.pathChangeStatus["nested.added"] == .added)
    }

    @Test("Deeply nested modifications show correct badges")
    func deeplyNestedModificationsShowCorrectBadges() {
        // Arrange: Changes at various nesting levels
        let original: [String: Any] = [
            "level1": [
                "level2": [
                    "level3": [
                        "level4": [
                            "deep_field": "original"
                        ]
                    ]
                ]
            ]
        ]

        let current: [String: Any] = [
            "level1": [
                "level2": [
                    "level3": [
                        "level4": [
                            "deep_field": "modified"
                        ]
                    ]
                ]
            ]
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Only the deep field has badge, parents don't
        #expect(viewModel.pathChangeStatus["level1"] == nil)
        #expect(viewModel.pathChangeStatus["level1.level2"] == nil)
        #expect(viewModel.pathChangeStatus["level1.level2.level3"] == nil)
        #expect(viewModel.pathChangeStatus["level1.level2.level3.level4"] == nil)
        #expect(viewModel.pathChangeStatus["level1.level2.level3.level4.deep_field"] == .modified)
    }

    // MARK: - File Status Override Tests

    @Test("File status .added makes all fields show [A]")
    func fileStatusAddedMakesAllFieldsShowAdded() {
        // Arrange: New file (no original)
        let current: [String: Any] = [
            "field1": "value1",
            "nested": [
                "field2": "value2"
            ]
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: nil,
            fileGitStatus: .added
        )

        // Assert: All fields show added
        #expect(viewModel.pathChangeStatus["field1"] == .added)
        #expect(viewModel.pathChangeStatus["nested"] == .added)
        #expect(viewModel.pathChangeStatus["nested.field2"] == .added)
    }

    @Test("File status .deleted makes all fields show [D]")
    func fileStatusDeletedMakesAllFieldsShowDeleted() {
        // Arrange: Deleted file with original
        let original: [String: Any] = [
            "field1": "value1",
            "nested": [
                "field2": "value2"
            ]
        ]

        let viewModel = createViewModel(
            json: [:],  // Empty current (file deleted)
            originalJSON: original,
            fileGitStatus: .deleted
        )

        // Assert: All fields from original show deleted
        #expect(viewModel.pathChangeStatus["field1"] == .deleted)
        #expect(viewModel.pathChangeStatus["nested"] == .deleted)
        #expect(viewModel.pathChangeStatus["nested.field2"] == .deleted)
    }

    // MARK: - Edge Cases

    @Test("Empty JSON objects show no badges")
    func emptyJSONObjectsShowNoBadges() {
        let viewModel = createViewModel(
            json: [:],
            originalJSON: [:],
            fileGitStatus: .unchanged
        )

        // Assert: No badges for empty JSON
        #expect(viewModel.pathChangeStatus.isEmpty)
    }

    @Test("Null value changes show correct badge")
    func nullValueChangesShowCorrectBadge() {
        // Arrange: Null value changed
        let original: [String: Any] = [
            "nullable_field": NSNull()
        ]

        let current: [String: Any] = [
            "nullable_field": "now_has_value"
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Null to value shows modified
        #expect(viewModel.pathChangeStatus["nullable_field"] == .modified)
    }

    @Test("Boolean value flip shows [M] badge")
    func booleanValueFlipShowsBadge() {
        // Arrange: Boolean flipped
        let original: [String: Any] = [
            "enabled": false
        ]

        let current: [String: Any] = [
            "enabled": true
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Boolean change shows modified
        #expect(viewModel.pathChangeStatus["enabled"] == .modified)
    }

    @Test("Number type change shows [M] badge")
    func numberTypeChangeShowsBadge() {
        // Arrange: Number value changed
        let original: [String: Any] = [
            "count": 42
        ]

        let current: [String: Any] = [
            "count": 100
        ]

        let viewModel = createViewModel(
            json: current,
            originalJSON: original,
            fileGitStatus: .modified
        )

        // Assert: Number change shows modified
        #expect(viewModel.pathChangeStatus["count"] == .modified)
    }

    // MARK: - Hybrid Mode Tests (Deleted/Added Files with Sparse JSON)

    @Test("Deleted file with array elements shows [D] badges in hybrid mode")
    func deletedFileWithArrayElementsShowsDeletedBadges() {
        // Arrange: Deleted file with array of objects, sparse restore
        let original: [String: Any] = [
            "items": [
                ["name": "Item 1", "id": 1],
                ["name": "Item 2", "id": 2]
            ]
        ]

        let sparse: [String: Any] = [
            "items": [
                ["name": "Updated Item 1"]  // Only edited field
            ]
        ]

        let viewModel = createViewModel(
            json: sparse,
            originalJSON: original,
            fileGitStatus: .deleted,
            editedPaths: ["items.[0].name"]
        )

        // Assert: Leaf values show correct badges (focus on leaf values, not containers)
        #expect(viewModel.pathChangeStatus["items.[0].name"] == .modified)  // Edited field
        #expect(viewModel.pathChangeStatus["items.[0].id"] == .deleted)  // Not in sparse
        #expect(viewModel.pathChangeStatus["items.[1].name"] == .deleted)  // Element not in sparse
        #expect(viewModel.pathChangeStatus["items.[1].id"] == .deleted)  // Element not in sparse
    }

    @Test("Deleted file with primitive array shows [D] badges")
    func deletedFileWithPrimitiveArrayShowsDeletedBadges() {
        // Arrange: Deleted file with primitive array
        let original: [String: Any] = [
            "tags": ["tag1", "tag2", "tag3"]
        ]

        let sparse: [String: Any] = [
            "tags": ["tag1", "updated-tag"]
        ]

        let viewModel = createViewModel(
            json: sparse,
            originalJSON: original,
            fileGitStatus: .deleted,
            editedPaths: ["tags.[1]"]
        )

        // Assert: Array elements (leaf values) show correct badges
        #expect(viewModel.pathChangeStatus["tags.[0]"] == .deleted)  // Unchanged, file deleted
        #expect(viewModel.pathChangeStatus["tags.[1]"] == .modified)  // Edited
        #expect(viewModel.pathChangeStatus["tags.[2]"] == .deleted)  // Not in sparse
    }
}
