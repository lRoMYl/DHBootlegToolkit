@testable import DHBootlegToolkitCore
import Testing
import Foundation

@Suite("Wizard Save Flow Tests")
struct WizardSaveFlowTests {

    @Test("New key is appended to existing keys, not replacing them")
    func newKeyAppendsToExisting() async throws {
        // Setup: Create temp file with existing keys
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID()).json")

        let existingContent = """
        {
            "EXISTING_KEY_1": {
                "translation": "Existing translation 1",
                "notes": "Existing notes 1"
            },
            "EXISTING_KEY_2": {
                "translation": "Existing translation 2",
                "notes": "Existing notes 2"
            }
        }
        """
        try existingContent.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        // Create configuration and worker
        let config = TestConfiguration()
        let worker = FileSystemWorker(configuration: config)

        // Load existing keys
        let existingKeys = try await worker.loadEntities(from: testFile)
        #expect(existingKeys.count == 2)

        // Add new key
        let newKey = TranslationEntity(
            key: "NEW_KEY",
            translation: "New translation",
            notes: "New notes"
        )
        var allKeys = existingKeys
        allKeys.append(newKey)

        // Save all keys
        try await worker.saveEntities(allKeys, to: testFile)

        // Verify: File should contain all 3 keys
        let savedKeys = try await worker.loadEntities(from: testFile)
        #expect(savedKeys.count == 3)
        #expect(savedKeys.contains { $0.key == "EXISTING_KEY_1" })
        #expect(savedKeys.contains { $0.key == "EXISTING_KEY_2" })
        #expect(savedKeys.contains { $0.key == "NEW_KEY" })
    }

    @Test("Loading keys from fresh file works correctly")
    func loadingKeysFromFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_load_\(UUID()).json")

        let content = """
        {
            "KEY_A": {
                "translation": "Translation A",
                "notes": "Notes A"
            },
            "KEY_B": {
                "translation": "Translation B",
                "notes": "Notes B",
                "char_limit": 50
            }
        }
        """
        try content.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let config = TestConfiguration()
        let worker = FileSystemWorker(configuration: config)

        let keys = try await worker.loadEntities(from: testFile)
        #expect(keys.count == 2)

        let keyA = keys.first { $0.key == "KEY_A" }
        #expect(keyA?.translation == "Translation A")
        #expect(keyA?.notes == "Notes A")

        let keyB = keys.first { $0.key == "KEY_B" }
        #expect(keyB?.charLimit == 50)
    }

    @Test("Saving to new file creates file correctly")
    func savingToNewFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_new_\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: testFile) }

        let config = TestConfiguration()
        let worker = FileSystemWorker(configuration: config)

        // File doesn't exist initially
        #expect(!worker.fileExists(at: testFile))

        // Create and save a new key
        let newKey = TranslationEntity(
            key: "FIRST_KEY",
            translation: "First translation",
            notes: "First notes"
        )

        try await worker.saveEntities([newKey], to: testFile)

        // File should now exist
        #expect(worker.fileExists(at: testFile))

        // Load and verify
        let savedKeys = try await worker.loadEntities(from: testFile)
        #expect(savedKeys.count == 1)
        #expect(savedKeys.first?.key == "FIRST_KEY")
    }
}

private struct TestConfiguration: RepositoryConfiguration {
    let basePath = "test"
    let platforms = [PlatformDefinition(folderName: "mobile", displayName: "Mobile")]
    let entitySchema = EntitySchema.translation
}
