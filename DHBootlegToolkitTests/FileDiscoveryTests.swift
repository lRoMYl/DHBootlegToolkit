import Foundation
@testable import DHBootlegToolkitCore
@testable import DHBootlegToolkit
import Testing

@Suite("File Discovery Tests")
struct FileDiscoveryTests {

    // MARK: - File Type Identification

    @Test("Primary JSON file is identified as en.json")
    func primaryJsonIdentified() {
        let items = createMockFeatureFiles()
        let primaryFile = items.first { item in
            if case .jsonFile(let isPrimary) = item.type {
                return isPrimary
            }
            return false
        }
        #expect(primaryFile?.name == "en.json")
    }

    @Test("Other JSON files are not marked as primary")
    func otherJsonNotPrimary() {
        let items = createMockFeatureFiles()
        let nonPrimaryJson = items.filter { item in
            if case .jsonFile(let isPrimary) = item.type {
                return !isPrimary
            }
            return false
        }
        #expect(nonPrimaryJson.count == 2)
        #expect(nonPrimaryJson.contains { $0.name == "de.json" })
        #expect(nonPrimaryJson.contains { $0.name == "fr.json" })
    }

    @Test("Images folder contains image files")
    func imagesFolderContainsImages() {
        let items = createMockFeatureFiles()
        let imagesFolder = items.first { $0.name == "images" && $0.type == .folder }
        #expect(imagesFolder != nil)
        #expect(imagesFolder?.children.count == 2)
        #expect(imagesFolder?.children.allSatisfy { $0.type == .image } == true)
    }

    @Test("Image files are correctly typed")
    func imageFilesTyped() {
        let items = createMockFeatureFiles()
        let imagesFolder = items.first { $0.name == "images" }
        let pngImage = imagesFolder?.children.first { $0.name == "screenshot.png" }
        let jpgImage = imagesFolder?.children.first { $0.name == "preview.jpg" }

        #expect(pngImage?.type == .image)
        #expect(jpgImage?.type == .image)
    }

    @Test("Text files are correctly typed")
    func textFilesTyped() {
        let items = createMockFeatureFiles()
        let readme = items.first { $0.name == "README.txt" }

        if case .otherFile(let ext) = readme?.type {
            #expect(ext == "txt")
        } else {
            Issue.record("Expected otherFile type for README.txt")
        }
    }

    // MARK: - File Sorting

    @Test("Primary JSON file is first in sorted order")
    func primaryJsonFirst() {
        let items = createMockFeatureFiles()
        #expect(items.first?.name == "en.json")
    }

    @Test("Folders come before other files")
    func foldersBeforeOtherFiles() {
        let items = createMockFeatureFiles()

        // Find positions
        let imagesIndex = items.firstIndex { $0.name == "images" }
        let readmeIndex = items.firstIndex { $0.name == "README.txt" }

        #expect(imagesIndex != nil)
        #expect(readmeIndex != nil)
        if let imgIdx = imagesIndex, let readIdx = readmeIndex {
            #expect(imgIdx < readIdx)
        }
    }

    // MARK: - Git Status Aggregation

    @Test("Feature files aggregate git status correctly")
    func featureFilesAggregateStatus() {
        var items = createMockFeatureFiles()

        // Modify one child in images folder to have added status
        if var imagesFolder = items.first(where: { $0.name == "images" }),
           let imagesIndex = items.firstIndex(where: { $0.name == "images" }) {
            imagesFolder.children[0] = FeatureFileItem(
                id: imagesFolder.children[0].id,
                name: imagesFolder.children[0].name,
                url: imagesFolder.children[0].url,
                type: .image,
                children: [],
                gitStatus: .added
            )
            items[imagesIndex] = imagesFolder

            #expect(imagesFolder.aggregatedGitStatus == .modified)
        }
    }

    @Test("Empty folder has unchanged aggregated status")
    func emptyFolderUnchangedStatus() {
        let emptyFolder = FeatureFileItem(
            id: "empty",
            name: "empty",
            url: URL(fileURLWithPath: "/test/empty"),
            type: .folder,
            children: [],
            gitStatus: .unchanged
        )

        #expect(emptyFolder.aggregatedGitStatus == .unchanged)
    }

    // MARK: - Icon Name Tests

    @Test("File icons are correct for each type")
    func fileIconsCorrect() {
        let items = createMockFeatureFiles()

        // Primary JSON files have filled icon
        let enJson = items.first { $0.name == "en.json" }
        #expect(enJson?.iconName == "doc.text.fill")

        // Folders have filled icon
        let folder = items.first { $0.name == "images" }
        #expect(folder?.iconName == "folder.fill")

        // Images
        let image = folder?.children.first { $0.name == "screenshot.png" }
        #expect(image?.iconName == "photo")

        // Text files
        let readme = items.first { $0.name == "README.txt" }
        #expect(readme?.iconName == "doc.plaintext")
    }

    // MARK: - Helpers

    private func createMockFeatureFiles() -> [FeatureFileItem] {
        let basePath = "/test/account_settings"

        return [
            // Primary JSON file (should be first)
            FeatureFileItem(
                id: "1",
                name: "en.json",
                url: URL(fileURLWithPath: "\(basePath)/en.json"),
                type: .jsonFile(isPrimary: true),
                children: [],
                gitStatus: .unchanged
            ),
            // Other JSON files
            FeatureFileItem(
                id: "2",
                name: "de.json",
                url: URL(fileURLWithPath: "\(basePath)/de.json"),
                type: .jsonFile(isPrimary: false),
                children: [],
                gitStatus: .unchanged
            ),
            FeatureFileItem(
                id: "3",
                name: "fr.json",
                url: URL(fileURLWithPath: "\(basePath)/fr.json"),
                type: .jsonFile(isPrimary: false),
                children: [],
                gitStatus: .modified
            ),
            // Images folder with children
            FeatureFileItem(
                id: "4",
                name: "images",
                url: URL(fileURLWithPath: "\(basePath)/images"),
                type: .folder,
                children: [
                    FeatureFileItem(
                        id: "4a",
                        name: "screenshot.png",
                        url: URL(fileURLWithPath: "\(basePath)/images/screenshot.png"),
                        type: .image,
                        children: [],
                        gitStatus: .unchanged
                    ),
                    FeatureFileItem(
                        id: "4b",
                        name: "preview.jpg",
                        url: URL(fileURLWithPath: "\(basePath)/images/preview.jpg"),
                        type: .image,
                        children: [],
                        gitStatus: .unchanged
                    )
                ],
                gitStatus: .unchanged
            ),
            // Other file
            FeatureFileItem(
                id: "5",
                name: "README.txt",
                url: URL(fileURLWithPath: "\(basePath)/README.txt"),
                type: .otherFile(fileExtension: "txt"),
                children: [],
                gitStatus: .added
            )
        ]
    }
}

@Suite("EditorTab Tests")
struct EditorTabTests {

    @Test("Key tab has correct display name")
    func keyTabDisplayName() {
        let key = TranslationKey(
            key: "TEST_Key_Name",
            translation: "Test translation",
            notes: "Test notes",
            targetLanguages: nil,
            charLimit: nil,
            isNew: false
        )

        let tabData = KeyTabData(key: key, featureId: "test_feature")
        let tab = EditorTab.key(tabData)

        #expect(tab.displayName == "TEST_Key_Name")
        #expect(tab.featureId == "test_feature")
        #expect(tab.isKeyTab == true)
        #expect(tab.isImageTab == false)
    }

    @Test("Image tab has correct display name")
    func imageTabDisplayName() {
        let tabData = ImageTabData(
            imageURL: URL(fileURLWithPath: "/test/screenshot.png"),
            featureId: "test_feature"
        )
        let tab = EditorTab.image(tabData)

        #expect(tab.displayName == "screenshot.png")
        #expect(tab.featureId == "test_feature")
        #expect(tab.isKeyTab == false)
        #expect(tab.isImageTab == true)
    }

    @Test("Key tab data is accessible")
    func keyTabDataAccessible() {
        let key = TranslationKey(
            key: "TEST_Key",
            translation: "Translation",
            notes: "Notes",
            targetLanguages: nil,
            charLimit: nil,
            isNew: false
        )

        let tabData = KeyTabData(key: key, featureId: "feature")
        let tab = EditorTab.key(tabData)

        #expect(tab.keyData != nil)
        #expect(tab.keyData?.keyName == "TEST_Key")
        #expect(tab.imageData == nil)
    }

    @Test("Image tab data is accessible")
    func imageTabDataAccessible() {
        let tabData = ImageTabData(
            imageURL: URL(fileURLWithPath: "/test/image.png"),
            featureId: "feature"
        )
        let tab = EditorTab.image(tabData)

        #expect(tab.imageData != nil)
        #expect(tab.imageData?.imageName == "image.png")
        #expect(tab.keyData == nil)
    }

    @Test("Tab equality based on id")
    func tabEqualityById() {
        let key = TranslationKey(
            key: "TEST",
            translation: "Test",
            notes: "",
            targetLanguages: nil,
            charLimit: nil,
            isNew: false
        )

        let tabData1 = KeyTabData(key: key, featureId: "feature")
        let tabData2 = KeyTabData(key: key, featureId: "feature")

        let tab1 = EditorTab.key(tabData1)
        let tab2 = EditorTab.key(tabData2)

        // Each tab gets a unique id, so they should not be equal
        #expect(tab1 != tab2)
        #expect(tab1.id != tab2.id)
    }

    @Test("Factory methods create correct tab types")
    func factoryMethods() {
        let key = TranslationKey(
            key: "KEY",
            translation: "Value",
            notes: "",
            targetLanguages: nil,
            charLimit: nil,
            isNew: false
        )

        let keyTab = EditorTab.keyTab(key: key, featureId: "f1")
        let imageTab = EditorTab.imageTab(url: URL(fileURLWithPath: "/img.png"), featureId: "f2")

        #expect(keyTab.isKeyTab == true)
        #expect(imageTab.isImageTab == true)
    }
}

@Suite("ImageTabData Tests")
struct ImageTabDataTests {

    @Test("Image name extracted from URL")
    func imageNameExtracted() {
        let tabData = ImageTabData(
            imageURL: URL(fileURLWithPath: "/path/to/my_screenshot.png"),
            featureId: "feature"
        )

        #expect(tabData.imageName == "my_screenshot.png")
    }

    @Test("Each ImageTabData gets unique id")
    func uniqueIds() {
        let url = URL(fileURLWithPath: "/test.png")

        let data1 = ImageTabData(imageURL: url, featureId: "f")
        let data2 = ImageTabData(imageURL: url, featureId: "f")

        #expect(data1.id != data2.id)
    }
}
