import Foundation
@testable import DHBootlegToolkitCore
import Testing

@Suite("FeatureFileItem Tests")
struct FeatureFileItemTests {

    // MARK: - GitFileStatus Tests

    @Test("Git file status values are distinct")
    func gitFileStatusDistinct() {
        #expect(GitFileStatus.added != .unchanged)
        #expect(GitFileStatus.modified != .unchanged)
        #expect(GitFileStatus.deleted != .unchanged)
        #expect(GitFileStatus.added != .modified)
        #expect(GitFileStatus.added != .deleted)
        #expect(GitFileStatus.modified != .deleted)
    }

    // MARK: - File Type Detection Tests

    @Test("JSON file has correct icon")
    func jsonFileIcon() {
        // Primary JSON file has filled icon
        let primaryItem = FeatureFileItem(
            id: "test",
            name: "en.json",
            url: URL(fileURLWithPath: "/test/en.json"),
            type: .jsonFile(isPrimary: true),
            children: [],
            gitStatus: .unchanged
        )
        #expect(primaryItem.iconName == "doc.text.fill")

        // Non-primary JSON file has unfilled icon
        let secondaryItem = FeatureFileItem(
            id: "test2",
            name: "de.json",
            url: URL(fileURLWithPath: "/test/de.json"),
            type: .jsonFile(isPrimary: false),
            children: [],
            gitStatus: .unchanged
        )
        #expect(secondaryItem.iconName == "doc.text")
    }

    @Test("Primary JSON file is identified")
    func primaryJsonIdentified() {
        let primaryItem = FeatureFileItem(
            id: "primary",
            name: "en.json",
            url: URL(fileURLWithPath: "/test/en.json"),
            type: .jsonFile(isPrimary: true),
            children: [],
            gitStatus: .unchanged
        )

        let nonPrimaryItem = FeatureFileItem(
            id: "secondary",
            name: "de.json",
            url: URL(fileURLWithPath: "/test/de.json"),
            type: .jsonFile(isPrimary: false),
            children: [],
            gitStatus: .unchanged
        )

        if case .jsonFile(let isPrimary) = primaryItem.type {
            #expect(isPrimary == true)
        } else {
            Issue.record("Expected jsonFile type")
        }

        if case .jsonFile(let isPrimary) = nonPrimaryItem.type {
            #expect(isPrimary == false)
        } else {
            Issue.record("Expected jsonFile type")
        }
    }

    @Test("Image file has correct icon")
    func imageFileIcon() {
        let item = FeatureFileItem(
            id: "test",
            name: "screenshot.png",
            url: URL(fileURLWithPath: "/test/screenshot.png"),
            type: .image,
            children: [],
            gitStatus: .unchanged
        )
        #expect(item.iconName == "photo")
    }

    @Test("Folder has correct icon")
    func folderIcon() {
        let item = FeatureFileItem(
            id: "test",
            name: "images",
            url: URL(fileURLWithPath: "/test/images"),
            type: .folder,
            children: [],
            gitStatus: .unchanged
        )
        #expect(item.iconName == "folder.fill")
    }

    @Test("Other file has correct icon")
    func otherFileIcon() {
        let txtItem = FeatureFileItem(
            id: "test",
            name: "README.txt",
            url: URL(fileURLWithPath: "/test/README.txt"),
            type: .otherFile(fileExtension: "txt"),
            children: [],
            gitStatus: .unchanged
        )
        #expect(txtItem.iconName == "doc.plaintext")

        let unknownItem = FeatureFileItem(
            id: "test2",
            name: "data.bin",
            url: URL(fileURLWithPath: "/test/data.bin"),
            type: .otherFile(fileExtension: "bin"),
            children: [],
            gitStatus: .unchanged
        )
        #expect(unknownItem.iconName == "doc")
    }

    // MARK: - Aggregated Git Status Tests

    @Test("Folder with unchanged children has unchanged status")
    func folderUnchangedChildren() {
        let child1 = FeatureFileItem(
            id: "c1",
            name: "a.png",
            url: URL(fileURLWithPath: "/a.png"),
            type: .image,
            children: [],
            gitStatus: .unchanged
        )
        let child2 = FeatureFileItem(
            id: "c2",
            name: "b.png",
            url: URL(fileURLWithPath: "/b.png"),
            type: .image,
            children: [],
            gitStatus: .unchanged
        )

        let folder = FeatureFileItem(
            id: "f",
            name: "images",
            url: URL(fileURLWithPath: "/images"),
            type: .folder,
            children: [child1, child2],
            gitStatus: .unchanged
        )

        #expect(folder.aggregatedGitStatus == .unchanged)
    }

    @Test("Folder with added child shows modified status")
    func folderWithAddedChild() {
        let child1 = FeatureFileItem(
            id: "c1",
            name: "a.png",
            url: URL(fileURLWithPath: "/a.png"),
            type: .image,
            children: [],
            gitStatus: .added
        )
        let child2 = FeatureFileItem(
            id: "c2",
            name: "b.png",
            url: URL(fileURLWithPath: "/b.png"),
            type: .image,
            children: [],
            gitStatus: .unchanged
        )

        let folder = FeatureFileItem(
            id: "f",
            name: "images",
            url: URL(fileURLWithPath: "/images"),
            type: .folder,
            children: [child1, child2],
            gitStatus: .unchanged
        )

        #expect(folder.aggregatedGitStatus == .modified)
    }

    @Test("Folder with modified child shows modified status")
    func folderWithModifiedChild() {
        let child = FeatureFileItem(
            id: "c1",
            name: "a.png",
            url: URL(fileURLWithPath: "/a.png"),
            type: .image,
            children: [],
            gitStatus: .modified
        )

        let folder = FeatureFileItem(
            id: "f",
            name: "images",
            url: URL(fileURLWithPath: "/images"),
            type: .folder,
            children: [child],
            gitStatus: .unchanged
        )

        #expect(folder.aggregatedGitStatus == .modified)
    }

    @Test("Folder with deleted child shows modified status")
    func folderWithDeletedChild() {
        let child = FeatureFileItem(
            id: "c1",
            name: "a.png",
            url: URL(fileURLWithPath: "/a.png"),
            type: .image,
            children: [],
            gitStatus: .deleted
        )

        let folder = FeatureFileItem(
            id: "f",
            name: "images",
            url: URL(fileURLWithPath: "/images"),
            type: .folder,
            children: [child],
            gitStatus: .unchanged
        )

        #expect(folder.aggregatedGitStatus == .modified)
    }

    @Test("Non-folder item returns own status")
    func nonFolderReturnsOwnStatus() {
        let addedFile = FeatureFileItem(
            id: "f1",
            name: "test.json",
            url: URL(fileURLWithPath: "/test.json"),
            type: .jsonFile(isPrimary: false),
            children: [],
            gitStatus: .added
        )
        #expect(addedFile.aggregatedGitStatus == .added)

        let modifiedFile = FeatureFileItem(
            id: "f2",
            name: "test2.json",
            url: URL(fileURLWithPath: "/test2.json"),
            type: .jsonFile(isPrimary: false),
            children: [],
            gitStatus: .modified
        )
        #expect(modifiedFile.aggregatedGitStatus == .modified)

        let deletedFile = FeatureFileItem(
            id: "f3",
            name: "test3.json",
            url: URL(fileURLWithPath: "/test3.json"),
            type: .jsonFile(isPrimary: false),
            children: [],
            gitStatus: .deleted
        )
        #expect(deletedFile.aggregatedGitStatus == .deleted)
    }

    // MARK: - Nested Folder Status Tests

    @Test("Nested folder aggregates grandchild status")
    func nestedFolderAggregation() {
        let grandchild = FeatureFileItem(
            id: "gc",
            name: "deep.png",
            url: URL(fileURLWithPath: "/deep.png"),
            type: .image,
            children: [],
            gitStatus: .added
        )
        let childFolder = FeatureFileItem(
            id: "cf",
            name: "subfolder",
            url: URL(fileURLWithPath: "/subfolder"),
            type: .folder,
            children: [grandchild],
            gitStatus: .unchanged
        )
        let parentFolder = FeatureFileItem(
            id: "pf",
            name: "images",
            url: URL(fileURLWithPath: "/images"),
            type: .folder,
            children: [childFolder],
            gitStatus: .unchanged
        )

        #expect(parentFolder.aggregatedGitStatus == .modified)
    }

    @Test("Empty folder has unchanged status")
    func emptyFolderUnchanged() {
        let folder = FeatureFileItem(
            id: "f",
            name: "empty",
            url: URL(fileURLWithPath: "/empty"),
            type: .folder,
            children: [],
            gitStatus: .unchanged
        )

        #expect(folder.aggregatedGitStatus == .unchanged)
    }
}

@Suite("GitFileStatus Parsing Tests")
struct GitFileStatusParsingTests {

    @Test("Parse porcelain status A (staged added)")
    func parseAddedStatus() {
        let status = GitFileStatus.from(porcelainCode: "A ")
        #expect(status == .added)
    }

    @Test("Parse porcelain status ?? (untracked)")
    func parseUntrackedStatus() {
        let status = GitFileStatus.from(porcelainCode: "??")
        #expect(status == .added)
    }

    @Test("Parse porcelain status M (staged modified)")
    func parseStagedModifiedStatus() {
        let status = GitFileStatus.from(porcelainCode: "M ")
        #expect(status == .modified)
    }

    @Test("Parse porcelain status _M (worktree modified)")
    func parseWorktreeModifiedStatus() {
        let status = GitFileStatus.from(porcelainCode: " M")
        #expect(status == .modified)
    }

    @Test("Parse porcelain status MM (both modified)")
    func parseBothModifiedStatus() {
        let status = GitFileStatus.from(porcelainCode: "MM")
        #expect(status == .modified)
    }

    @Test("Parse porcelain status D (staged deleted)")
    func parseStagedDeletedStatus() {
        let status = GitFileStatus.from(porcelainCode: "D ")
        #expect(status == .deleted)
    }

    @Test("Parse porcelain status _D (worktree deleted)")
    func parseWorktreeDeletedStatus() {
        let status = GitFileStatus.from(porcelainCode: " D")
        #expect(status == .deleted)
    }

    @Test("Parse empty status as unchanged")
    func parseEmptyStatus() {
        let status = GitFileStatus.from(porcelainCode: "  ")
        #expect(status == .unchanged)
    }

    @Test("Parse unknown status as unchanged")
    func parseUnknownStatus() {
        let status = GitFileStatus.from(porcelainCode: "XX")
        #expect(status == .unchanged)
    }

    @Test("Parse renamed status as modified")
    func parseRenamedStatus() {
        let status = GitFileStatus.from(porcelainCode: "R ")
        #expect(status == .modified)
    }

    @Test("Parse copied status as modified")
    func parseCopiedStatus() {
        // Copied files are treated as modified in the implementation
        let status = GitFileStatus.from(porcelainCode: "C ")
        #expect(status == .modified)
    }
}

@Suite("FeatureFileItem Identifiable Tests")
struct FeatureFileItemIdentifiableTests {

    @Test("Items with same id are equal")
    func itemsWithSameIdEqual() {
        let item1 = FeatureFileItem(
            id: "same-id",
            name: "file1.json",
            url: URL(fileURLWithPath: "/file1.json"),
            type: .jsonFile(isPrimary: true),
            children: [],
            gitStatus: .unchanged
        )

        let item2 = FeatureFileItem(
            id: "same-id",
            name: "file2.json",
            url: URL(fileURLWithPath: "/file2.json"),
            type: .jsonFile(isPrimary: false),
            children: [],
            gitStatus: .modified
        )

        #expect(item1.id == item2.id)
    }

    @Test("Items with different ids are not equal")
    func itemsWithDifferentIdsNotEqual() {
        let item1 = FeatureFileItem(
            id: "id-1",
            name: "file.json",
            url: URL(fileURLWithPath: "/file.json"),
            type: .jsonFile(isPrimary: true),
            children: [],
            gitStatus: .unchanged
        )

        let item2 = FeatureFileItem(
            id: "id-2",
            name: "file.json",
            url: URL(fileURLWithPath: "/file.json"),
            type: .jsonFile(isPrimary: true),
            children: [],
            gitStatus: .unchanged
        )

        #expect(item1.id != item2.id)
    }
}

// MARK: - Badge Display Rules Tests

@Suite("Badge Display Rules")
struct BadgeDisplayRulesTests {

    // MARK: - File Badge Display Tests

    @Test("Primary JSON file shows badge when added")
    func primaryJsonAddedShowsBadge() {
        let item = FeatureFileItem(
            id: "en",
            name: "en.json",
            url: URL(fileURLWithPath: "/test/en.json"),
            type: .jsonFile(isPrimary: true),
            gitStatus: .added
        )

        #expect(item.gitStatus == .added)
        #expect(item.shouldShowGitBadge == true)
    }

    @Test("Primary JSON file shows badge when modified")
    func primaryJsonModifiedShowsBadge() {
        let item = FeatureFileItem(
            id: "en",
            name: "en.json",
            url: URL(fileURLWithPath: "/test/en.json"),
            type: .jsonFile(isPrimary: true),
            gitStatus: .modified
        )

        #expect(item.gitStatus == .modified)
        #expect(item.shouldShowGitBadge == true)
    }

    @Test("Primary JSON file shows badge when deleted")
    func primaryJsonDeletedShowsBadge() {
        let item = FeatureFileItem(
            id: "en",
            name: "en.json",
            url: URL(fileURLWithPath: "/test/en.json"),
            type: .jsonFile(isPrimary: true),
            gitStatus: .deleted
        )

        #expect(item.gitStatus == .deleted)
        #expect(item.shouldShowGitBadge == true)
    }

    @Test("Primary JSON file hides badge when unchanged")
    func primaryJsonUnchangedHidesBadge() {
        let item = FeatureFileItem(
            id: "en",
            name: "en.json",
            url: URL(fileURLWithPath: "/test/en.json"),
            type: .jsonFile(isPrimary: true),
            gitStatus: .unchanged
        )

        #expect(item.gitStatus == .unchanged)
        #expect(item.shouldShowGitBadge == false)
    }

    @Test("Secondary JSON file shows badge for all change statuses")
    func secondaryJsonShowsBadge() {
        let addedItem = FeatureFileItem(
            id: "de",
            name: "de.json",
            url: URL(fileURLWithPath: "/test/de.json"),
            type: .jsonFile(isPrimary: false),
            gitStatus: .added
        )
        #expect(addedItem.shouldShowGitBadge == true)

        let modifiedItem = FeatureFileItem(
            id: "fr",
            name: "fr.json",
            url: URL(fileURLWithPath: "/test/fr.json"),
            type: .jsonFile(isPrimary: false),
            gitStatus: .modified
        )
        #expect(modifiedItem.shouldShowGitBadge == true)

        let deletedItem = FeatureFileItem(
            id: "es",
            name: "es.json",
            url: URL(fileURLWithPath: "/test/es.json"),
            type: .jsonFile(isPrimary: false),
            gitStatus: .deleted
        )
        #expect(deletedItem.shouldShowGitBadge == true)
    }

    @Test("Image file shows badge for all change statuses")
    func imageFileShowsBadge() {
        let addedItem = FeatureFileItem(
            id: "img1",
            name: "icon.png",
            url: URL(fileURLWithPath: "/test/icon.png"),
            type: .image,
            gitStatus: .added
        )
        #expect(addedItem.shouldShowGitBadge == true)

        let modifiedItem = FeatureFileItem(
            id: "img2",
            name: "banner.jpg",
            url: URL(fileURLWithPath: "/test/banner.jpg"),
            type: .image,
            gitStatus: .modified
        )
        #expect(modifiedItem.shouldShowGitBadge == true)

        let deletedItem = FeatureFileItem(
            id: "img3",
            name: "old.gif",
            url: URL(fileURLWithPath: "/test/old.gif"),
            type: .image,
            gitStatus: .deleted
        )
        #expect(deletedItem.shouldShowGitBadge == true)
    }

    @Test("Other file shows badge for all change statuses")
    func otherFileShowsBadge() {
        let addedItem = FeatureFileItem(
            id: "txt1",
            name: "README.md",
            url: URL(fileURLWithPath: "/test/README.md"),
            type: .otherFile(fileExtension: "md"),
            gitStatus: .added
        )
        #expect(addedItem.shouldShowGitBadge == true)

        let modifiedItem = FeatureFileItem(
            id: "txt2",
            name: "config.xml",
            url: URL(fileURLWithPath: "/test/config.xml"),
            type: .otherFile(fileExtension: "xml"),
            gitStatus: .modified
        )
        #expect(modifiedItem.shouldShowGitBadge == true)

        let deletedItem = FeatureFileItem(
            id: "txt3",
            name: "legacy.txt",
            url: URL(fileURLWithPath: "/test/legacy.txt"),
            type: .otherFile(fileExtension: "txt"),
            gitStatus: .deleted
        )
        #expect(deletedItem.shouldShowGitBadge == true)
    }

    // MARK: - Folder Badge Display Tests (Folders should NEVER show badges)

    @Test("Folder never shows badge even when marked as added")
    func folderAddedNoBadge() {
        let folder = FeatureFileItem(
            id: "folder1",
            name: "images",
            url: URL(fileURLWithPath: "/test/images"),
            type: .folder,
            children: [],
            gitStatus: .added
        )

        #expect(folder.shouldShowGitBadge == false, "Folders should never show git badges")
    }

    @Test("Folder never shows badge even when marked as modified")
    func folderModifiedNoBadge() {
        let folder = FeatureFileItem(
            id: "folder1",
            name: "assets",
            url: URL(fileURLWithPath: "/test/assets"),
            type: .folder,
            children: [],
            gitStatus: .modified
        )

        #expect(folder.shouldShowGitBadge == false, "Folders should never show git badges")
    }

    @Test("Folder never shows badge even when marked as deleted")
    func folderDeletedNoBadge() {
        let folder = FeatureFileItem(
            id: "folder1",
            name: "old_stuff",
            url: URL(fileURLWithPath: "/test/old_stuff"),
            type: .folder,
            children: [],
            gitStatus: .deleted
        )

        #expect(folder.shouldShowGitBadge == false, "Folders should never show git badges")
    }

    @Test("Folder with changed children still shows no badge")
    func folderWithChangedChildrenNoBadge() {
        let addedChild = FeatureFileItem(
            id: "img1",
            name: "new.png",
            url: URL(fileURLWithPath: "/test/images/new.png"),
            type: .image,
            gitStatus: .added
        )
        let modifiedChild = FeatureFileItem(
            id: "img2",
            name: "edited.png",
            url: URL(fileURLWithPath: "/test/images/edited.png"),
            type: .image,
            gitStatus: .modified
        )

        let folder = FeatureFileItem(
            id: "folder1",
            name: "images",
            url: URL(fileURLWithPath: "/test/images"),
            type: .folder,
            children: [addedChild, modifiedChild],
            gitStatus: .modified  // Even if gitStatus is set
        )

        #expect(folder.shouldShowGitBadge == false, "Folders should never show git badges, even with changed children")
        // But the children themselves should show badges
        #expect(addedChild.shouldShowGitBadge == true)
        #expect(modifiedChild.shouldShowGitBadge == true)
    }

    @Test("Nested folder hierarchy - only files show badges")
    func nestedFolderOnlyFilesShowBadges() {
        let deepFile = FeatureFileItem(
            id: "deep",
            name: "nested.json",
            url: URL(fileURLWithPath: "/test/a/b/c/nested.json"),
            type: .jsonFile(isPrimary: false),
            gitStatus: .added
        )

        let innerFolder = FeatureFileItem(
            id: "innerFolder",
            name: "c",
            url: URL(fileURLWithPath: "/test/a/b/c"),
            type: .folder,
            children: [deepFile],
            gitStatus: .added  // Might be marked as added too
        )

        let middleFolder = FeatureFileItem(
            id: "middleFolder",
            name: "b",
            url: URL(fileURLWithPath: "/test/a/b"),
            type: .folder,
            children: [innerFolder],
            gitStatus: .unchanged
        )

        let outerFolder = FeatureFileItem(
            id: "outerFolder",
            name: "a",
            url: URL(fileURLWithPath: "/test/a"),
            type: .folder,
            children: [middleFolder],
            gitStatus: .unchanged
        )

        // Files should show badges
        #expect(deepFile.shouldShowGitBadge == true)

        // All folders should NOT show badges
        #expect(innerFolder.shouldShowGitBadge == false)
        #expect(middleFolder.shouldShowGitBadge == false)
        #expect(outerFolder.shouldShowGitBadge == false)
    }

    // MARK: - Badge Value Tests

    @Test("Git status badge letters are correct")
    func badgeLettersCorrect() {
        #expect(GitFileStatus.added.badgeLetter == "A")
        #expect(GitFileStatus.modified.badgeLetter == "M")
        #expect(GitFileStatus.deleted.badgeLetter == "D")
        #expect(GitFileStatus.unchanged.badgeLetter == "")
    }

    // MARK: - All File Type Permutations

    @Test("Badge display permutation matrix - all file types and statuses", arguments: [
        // (fileType, gitStatus, shouldShowBadge)
        (FeatureFileItem.FileItemType.jsonFile(isPrimary: true), GitFileStatus.added, true),
        (FeatureFileItem.FileItemType.jsonFile(isPrimary: true), GitFileStatus.modified, true),
        (FeatureFileItem.FileItemType.jsonFile(isPrimary: true), GitFileStatus.deleted, true),
        (FeatureFileItem.FileItemType.jsonFile(isPrimary: true), GitFileStatus.unchanged, false),

        (FeatureFileItem.FileItemType.jsonFile(isPrimary: false), GitFileStatus.added, true),
        (FeatureFileItem.FileItemType.jsonFile(isPrimary: false), GitFileStatus.modified, true),
        (FeatureFileItem.FileItemType.jsonFile(isPrimary: false), GitFileStatus.deleted, true),
        (FeatureFileItem.FileItemType.jsonFile(isPrimary: false), GitFileStatus.unchanged, false),

        (FeatureFileItem.FileItemType.image, GitFileStatus.added, true),
        (FeatureFileItem.FileItemType.image, GitFileStatus.modified, true),
        (FeatureFileItem.FileItemType.image, GitFileStatus.deleted, true),
        (FeatureFileItem.FileItemType.image, GitFileStatus.unchanged, false),

        (FeatureFileItem.FileItemType.otherFile(fileExtension: "txt"), GitFileStatus.added, true),
        (FeatureFileItem.FileItemType.otherFile(fileExtension: "txt"), GitFileStatus.modified, true),
        (FeatureFileItem.FileItemType.otherFile(fileExtension: "txt"), GitFileStatus.deleted, true),
        (FeatureFileItem.FileItemType.otherFile(fileExtension: "txt"), GitFileStatus.unchanged, false),

        // Folders should NEVER show badges regardless of status
        (FeatureFileItem.FileItemType.folder, GitFileStatus.added, false),
        (FeatureFileItem.FileItemType.folder, GitFileStatus.modified, false),
        (FeatureFileItem.FileItemType.folder, GitFileStatus.deleted, false),
        (FeatureFileItem.FileItemType.folder, GitFileStatus.unchanged, false),
    ] as [(FeatureFileItem.FileItemType, GitFileStatus, Bool)])
    func badgePermutationMatrix(fileType: FeatureFileItem.FileItemType, status: GitFileStatus, expected: Bool) {
        let item = FeatureFileItem(
            id: "test",
            name: "test",
            url: URL(fileURLWithPath: "/test"),
            type: fileType,
            gitStatus: status
        )

        #expect(item.shouldShowGitBadge == expected,
                "FileType \(fileType) with status \(status) should\(expected ? "" : " NOT") show badge")
    }
}
