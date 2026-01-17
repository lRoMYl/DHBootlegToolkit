@testable import DHBootlegToolkit
@testable import DHBootlegToolkitCore
import Testing
import Foundation

@Suite("Sparse Array Element Tests")
struct SparseArrayElementTests {

    @Test("Direct array element edit with primitive value")
    func directArrayElementPrimitive() async throws {
        // Arrange: Create JSON with array of primitives
        let fullJSON: [String: Any] = [
            "tags": ["tag1", "tag2", "tag3", "tag4"]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted, .sortedKeys])
        let fullContent = String(data: fullData, encoding: .utf8)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")

        var country = S3CountryConfig(
            countryCode: "test",
            configURL: tempURL,
            configData: fullData,
            originalContent: fullContent,
            hasChanges: false,
            gitStatus: .deleted,
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Act: Edit one array element
        country = country.withUpdatedValue("updated-tag", at: ["tags", "[2]"])!

        // Track the edited path
        country.editedPaths.insert("tags.[2]")

        // Construct sparse JSON
        guard let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths),
              let sparseJSON = sparseCountry.parseConfigJSON() else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Assert: Sparse JSON contains only the edited array element
        let tags = sparseJSON["tags"] as? [String]
        #expect(tags != nil)
        #expect(tags?.count == 3)  // Sparse array with index 2
        #expect(tags?[2] == "updated-tag")
    }

    @Test("Nested field in array element object - THE MAIN BUG")
    func nestedFieldInArrayElementObject() async throws {
        // Arrange: Create JSON with array of objects
        let fullJSON: [String: Any] = [
            "items": [
                ["name": "Item 1", "id": 1, "enabled": true],
                ["name": "Item 2", "id": 2, "enabled": false]
            ]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted, .sortedKeys])
        let fullContent = String(data: fullData, encoding: .utf8)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")

        var country = S3CountryConfig(
            countryCode: "test",
            configURL: tempURL,
            configData: fullData,
            originalContent: fullContent,
            hasChanges: false,
            gitStatus: .deleted,
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Act: Edit a nested field within array element
        country = country.withUpdatedValue("Updated Item 1", at: ["items", "[0]", "name"])!

        // Track the edited path
        country.editedPaths.insert("items.[0].name")

        // Construct sparse JSON
        guard let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths),
              let sparseJSON = sparseCountry.parseConfigJSON() else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Assert: Sparse JSON should preserve array structure, NOT replace with {}
        let items = sparseJSON["items"] as? [[String: Any]]
        #expect(items != nil, "Array should not be replaced with empty object")
        #expect(items?.count == 1, "Sparse array should contain one element")

        let item0 = items?[0]
        #expect(item0 != nil)
        #expect(item0?["name"] as? String == "Updated Item 1")

        // Other fields should NOT be present
        #expect(item0?["id"] == nil)
        #expect(item0?["enabled"] == nil)

        // Verify the bug is fixed: items should NOT be an empty object
        let itemsAsObject = sparseJSON["items"] as? [String: Any]
        #expect(itemsAsObject == nil, "Items should be array, not object")
    }

    @Test("Multiple fields in same array element")
    func multipleFieldsInSameElement() async throws {
        // Arrange: Create JSON with array of objects
        let fullJSON: [String: Any] = [
            "features": [
                ["id": "f1", "name": "Feature 1", "enabled": true, "description": "First feature"],
                ["id": "f2", "name": "Feature 2", "enabled": false, "description": "Second feature"]
            ]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted, .sortedKeys])
        let fullContent = String(data: fullData, encoding: .utf8)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")

        var country = S3CountryConfig(
            countryCode: "test",
            configURL: tempURL,
            configData: fullData,
            originalContent: fullContent,
            hasChanges: false,
            gitStatus: .deleted,
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Act: Edit multiple fields in the same array element
        country = country.withUpdatedValue("Updated Feature", at: ["features", "[0]", "name"])!
        country = country.withUpdatedValue(false, at: ["features", "[0]", "enabled"])!

        // Track the edited paths
        country.editedPaths.insert("features.[0].name")
        country.editedPaths.insert("features.[0].enabled")

        // Construct sparse JSON
        guard let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths),
              let sparseJSON = sparseCountry.parseConfigJSON() else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Assert: Sparse JSON contains both edited fields in same element
        let features = sparseJSON["features"] as? [[String: Any]]
        #expect(features != nil)
        #expect(features?.count == 1)

        let feature0 = features?[0]
        #expect(feature0 != nil)
        #expect(feature0?["name"] as? String == "Updated Feature")
        #expect(feature0?["enabled"] as? Bool == false)

        // Unedited fields should NOT be present
        #expect(feature0?["id"] == nil)
        #expect(feature0?["description"] == nil)
    }

    @Test("Multiple array elements edited")
    func multipleArrayElementsEdited() async throws {
        // Arrange: Create JSON with array of objects
        let fullJSON: [String: Any] = [
            "items": [
                ["name": "Item 1", "value": 100],
                ["name": "Item 2", "value": 200],
                ["name": "Item 3", "value": 300]
            ]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted, .sortedKeys])
        let fullContent = String(data: fullData, encoding: .utf8)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")

        var country = S3CountryConfig(
            countryCode: "test",
            configURL: tempURL,
            configData: fullData,
            originalContent: fullContent,
            hasChanges: false,
            gitStatus: .deleted,
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Act: Edit fields in different array elements
        country = country.withUpdatedValue("Updated Item 1", at: ["items", "[0]", "name"])!
        country = country.withUpdatedValue("Updated Item 3", at: ["items", "[2]", "name"])!

        // Track the edited paths
        country.editedPaths.insert("items.[0].name")
        country.editedPaths.insert("items.[2].name")

        // Construct sparse JSON
        guard let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths),
              let sparseJSON = sparseCountry.parseConfigJSON() else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Assert: Sparse JSON contains both edited elements at correct indices
        let items = sparseJSON["items"] as? [[String: Any]]
        #expect(items != nil)
        #expect(items?.count == 3)  // Sparse array with 3 elements to maintain indices

        let item0 = items?[0]
        #expect(item0 != nil)
        #expect(item0?["name"] as? String == "Updated Item 1")
        #expect(item0?["value"] == nil)  // Unedited field

        // Middle element should be empty placeholder
        let item1 = items?[1] as? [String: Any]
        #expect(item1?.isEmpty == true)

        let item2 = items?[2]
        #expect(item2 != nil)
        #expect(item2?["name"] as? String == "Updated Item 3")
        #expect(item2?["value"] == nil)  // Unedited field
    }

    @Test("Deeply nested array elements")
    func deeplyNestedArrayElements() async throws {
        // Arrange: Create JSON with deeply nested array structure
        let fullJSON: [String: Any] = [
            "data": [
                "items": [
                    [
                        "tags": ["tag1", "tag2", "tag3"],
                        "metadata": ["key": "value"]
                    ]
                ]
            ]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted, .sortedKeys])
        let fullContent = String(data: fullData, encoding: .utf8)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")

        var country = S3CountryConfig(
            countryCode: "test",
            configURL: tempURL,
            configData: fullData,
            originalContent: fullContent,
            hasChanges: false,
            gitStatus: .deleted,
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Act: Edit a deeply nested array element
        country = country.withUpdatedValue("updated-tag", at: ["data", "items", "[0]", "tags", "[1]"])!

        // Track the edited path
        country.editedPaths.insert("data.items.[0].tags.[1]")

        // Construct sparse JSON
        guard let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths),
              let sparseJSON = sparseCountry.parseConfigJSON() else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Assert: Sparse JSON preserves all parent structures as arrays/objects
        let data = sparseJSON["data"] as? [String: Any]
        #expect(data != nil)

        let items = data?["items"] as? [[String: Any]]
        #expect(items != nil)
        #expect(items?.count == 1)

        let item0 = items?[0]
        #expect(item0 != nil)

        let tags = item0?["tags"] as? [String]
        #expect(tags != nil)
        #expect(tags?.count == 2)  // Sparse array up to index 1
        #expect(tags?[1] == "updated-tag")

        // Other fields should NOT be present
        #expect(item0?["metadata"] == nil)
    }

    @Test("Array of primitives")
    func arrayOfPrimitives() async throws {
        // Arrange: Create JSON with array of primitives
        let fullJSON: [String: Any] = [
            "data": [
                "values": [10, 20, 30, 40, 50]
            ]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted, .sortedKeys])
        let fullContent = String(data: fullData, encoding: .utf8)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")

        var country = S3CountryConfig(
            countryCode: "test",
            configURL: tempURL,
            configData: fullData,
            originalContent: fullContent,
            hasChanges: false,
            gitStatus: .deleted,
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Act: Edit one primitive array element
        country = country.withUpdatedValue(999, at: ["data", "values", "[2]"])!

        // Track the edited path
        country.editedPaths.insert("data.values.[2]")

        // Construct sparse JSON
        guard let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths),
              let sparseJSON = sparseCountry.parseConfigJSON() else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Assert: Sparse JSON contains only the edited element
        let data = sparseJSON["data"] as? [String: Any]
        #expect(data != nil)

        let values = data?["values"] as? [Int]
        #expect(values != nil)
        #expect(values?.count == 3)  // Sparse array up to index 2
        #expect(values?[2] == 999)
    }

    @Test("Edge cases - empty array and invalid index")
    func edgeCases() async throws {
        // Arrange: Create JSON with various edge cases
        let fullJSON: [String: Any] = [
            "emptyArray": [] as [Any],
            "items": [
                ["name": "Item 1"],
                ["name": "Item 2"]
            ]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted, .sortedKeys])
        let fullContent = String(data: fullData, encoding: .utf8)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")

        var country = S3CountryConfig(
            countryCode: "test",
            configURL: tempURL,
            configData: fullData,
            originalContent: fullContent,
            hasChanges: false,
            gitStatus: .deleted,
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Act: Edit valid array element
        country = country.withUpdatedValue("Updated", at: ["items", "[1]", "name"])!

        // Track valid edited path (invalid paths won't be tracked)
        country.editedPaths.insert("items.[1].name")

        // Try to track invalid paths (out of bounds) - should be gracefully ignored
        country.editedPaths.insert("items.[99].name")  // Out of bounds
        country.editedPaths.insert("emptyArray.[0]")   // Empty array

        // Construct sparse JSON
        guard let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths),
              let sparseJSON = sparseCountry.parseConfigJSON() else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Assert: Valid edit is present
        let items = sparseJSON["items"] as? [[String: Any]]
        #expect(items != nil)
        #expect(items?.count == 2)

        let item1 = items?[1]
        #expect(item1?["name"] as? String == "Updated")

        // Invalid edits should be gracefully ignored
        #expect(sparseJSON["emptyArray"] == nil, "Empty array path should be ignored")

        // Out of bounds index should not cause crash or corrupt data
        let itemsCount = items?.count ?? 0
        #expect(itemsCount <= 2, "Out of bounds index should not extend array beyond valid edits")
    }
}
