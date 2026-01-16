@testable import DHBootlegToolkitCore
import Testing
import Foundation

/// Test configuration for FileSystemWorker tests
private struct TestConfiguration: RepositoryConfiguration {
    let basePath = "test"
    let platforms = [PlatformDefinition(folderName: "mobile", displayName: "Mobile")]
    let entitySchema = EntitySchema.translation
}

@Suite("FileSystemWorker Hash Tests")
struct FileSystemWorkerHashTests {

    let configuration: any RepositoryConfiguration = TestConfiguration()

    @Test("computeFileHash returns consistent hash for same file")
    func consistentHash() async throws {
        let worker = FileSystemWorker(configuration: configuration)

        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_hash_\(UUID().uuidString).json")

        try "test content".write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        // Hash the same file twice
        let hash1 = worker.computeFileHash(testFile)
        let hash2 = worker.computeFileHash(testFile)

        #expect(hash1 != nil)
        #expect(hash2 != nil)
        #expect(hash1 == hash2)
    }

    @Test("computeFileHash returns different hash for different content")
    func differentContentDifferentHash() async throws {
        let worker = FileSystemWorker(configuration: configuration)

        let tempDir = FileManager.default.temporaryDirectory
        let testFile1 = tempDir.appendingPathComponent("test_hash1_\(UUID().uuidString).json")
        let testFile2 = tempDir.appendingPathComponent("test_hash2_\(UUID().uuidString).json")

        try "content A".write(to: testFile1, atomically: true, encoding: .utf8)
        try "content B".write(to: testFile2, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: testFile1)
            try? FileManager.default.removeItem(at: testFile2)
        }

        let hash1 = worker.computeFileHash(testFile1)
        let hash2 = worker.computeFileHash(testFile2)

        #expect(hash1 != nil)
        #expect(hash2 != nil)
        #expect(hash1 != hash2)
    }

    @Test("computeFileHash returns nil for non-existent file")
    func nonExistentFileReturnsNil() async throws {
        let worker = FileSystemWorker(configuration: configuration)

        let nonExistentFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("non_existent_\(UUID().uuidString).json")

        let hash = worker.computeFileHash(nonExistentFile)

        #expect(hash == nil)
    }

    @Test("hasFileChanged returns false when file is unchanged")
    func unchangedFileReturnsFalse() async throws {
        let worker = FileSystemWorker(configuration: configuration)

        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_change_\(UUID().uuidString).json")

        try "original content".write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let originalHash = worker.computeFileHash(testFile)

        // Check if file has changed (it hasn't)
        let hasChanged = worker.hasFileChanged(at: testFile, since: originalHash)

        #expect(hasChanged == false)
    }

    @Test("hasFileChanged returns true when file is modified")
    func modifiedFileReturnsTrue() async throws {
        let worker = FileSystemWorker(configuration: configuration)

        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_change_\(UUID().uuidString).json")

        try "original content".write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let originalHash = worker.computeFileHash(testFile)

        // Modify the file
        try "modified content".write(to: testFile, atomically: true, encoding: .utf8)

        // Check if file has changed
        let hasChanged = worker.hasFileChanged(at: testFile, since: originalHash)

        #expect(hasChanged == true)
    }

    @Test("hasFileChanged returns false when no base hash provided")
    func noBaseHashReturnsFalse() async throws {
        let worker = FileSystemWorker(configuration: configuration)

        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_no_hash_\(UUID().uuidString).json")

        try "some content".write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        // Check with nil hash - should return false (no change detection)
        let hasChanged = worker.hasFileChanged(at: testFile, since: nil)

        #expect(hasChanged == false)
    }

    @Test("Hash changes when file size changes")
    func hashChangesWithFileSize() async throws {
        let worker = FileSystemWorker(configuration: configuration)

        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_size_\(UUID().uuidString).json")

        try "short".write(to: testFile, atomically: true, encoding: .utf8)
        let hash1 = worker.computeFileHash(testFile)

        try "a much longer content string".write(to: testFile, atomically: true, encoding: .utf8)
        let hash2 = worker.computeFileHash(testFile)

        defer { try? FileManager.default.removeItem(at: testFile) }

        #expect(hash1 != hash2)
    }
}
