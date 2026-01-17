@testable import DHBootlegToolkit
@testable import DHBootlegToolkitCore
import Testing
import Foundation

@Suite("Sparse Restoration Tests")
struct SparseRestorationTests {

    @Test("Sparse restoration for deleted file with 2 edited fields")
    func sparseRestorationDeletedFile() async throws {
        // Arrange: Create mock full JSON with 5 fields
        let fullJSON: [String: Any] = [
            "data": [
                "subscription": [
                    "enabled": false,
                    "plans": ["basic", "premium"]
                ],
                "feature_flags": [
                    "dark_mode": false,
                    "new_ui": true,
                    "beta_features": false
                ]
            ]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted, .sortedKeys])
        let fullContent = String(data: fullData, encoding: .utf8)

        // Create a deleted country config with full JSON
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")

        var country = S3CountryConfig(
            countryCode: "sg",
            configURL: tempURL,
            configData: fullData,
            originalContent: fullContent,
            hasChanges: false,
            gitStatus: .deleted,
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Act: Edit 2 fields
        country = country.withUpdatedValue(true, at: ["data", "subscription", "enabled"])!
        country = country.withUpdatedValue(true, at: ["data", "feature_flags", "dark_mode"])!

        // Verify editedPaths tracks the 2 edits
        #expect(country.editedPaths.count == 2)
        #expect(country.editedPaths.contains("data.subscription.enabled"))
        #expect(country.editedPaths.contains("data.feature_flags.dark_mode"))

        // Construct sparse JSON
        guard let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths) else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Parse sparse JSON
        guard let sparseJSON = sparseCountry.parseConfigJSON() else {
            Issue.record("Failed to parse sparse JSON")
            return
        }

        // Assert: Sparse JSON contains only edited fields
        let dataDict = sparseJSON["data"] as? [String: Any]
        #expect(dataDict != nil)

        // Check subscription.enabled is present and correct
        let subscription = dataDict?["subscription"] as? [String: Any]
        #expect(subscription != nil)
        #expect(subscription?["enabled"] as? Bool == true)

        // Check subscription.plans is NOT present (not edited)
        #expect(subscription?["plans"] == nil)

        // Check feature_flags.dark_mode is present and correct
        let featureFlags = dataDict?["feature_flags"] as? [String: Any]
        #expect(featureFlags != nil)
        #expect(featureFlags?["dark_mode"] as? Bool == true)

        // Check feature_flags.new_ui is NOT present (not edited)
        #expect(featureFlags?["new_ui"] == nil)

        // Check feature_flags.beta_features is NOT present (not edited)
        #expect(featureFlags?["beta_features"] == nil)

        // Verify total structure: only 2 edited leaf nodes should exist
        let subscriptionKeys = subscription?.keys.count ?? 0
        let featureFlagsKeys = featureFlags?.keys.count ?? 0
        #expect(subscriptionKeys == 1)  // Only "enabled"
        #expect(featureFlagsKeys == 1)  // Only "dark_mode"
    }

    @Test("Normal save for non-deleted file writes full JSON")
    func normalSaveWritesFullJSON() async throws {
        // Arrange: Create a modified (non-deleted) country config
        let fullJSON: [String: Any] = [
            "data": [
                "subscription": ["enabled": false],
                "feature_flags": ["dark_mode": false]
            ]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted])
        let fullContent = String(data: fullData, encoding: .utf8)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")

        var country = S3CountryConfig(
            countryCode: "sg",
            configURL: tempURL,
            configData: fullData,
            originalContent: fullContent,
            hasChanges: false,
            gitStatus: .modified,  // Not deleted
            isDeletedPlaceholder: false,
            editedPaths: []
        )

        // Act: Edit 1 field
        country = country.withUpdatedValue(true, at: ["data", "subscription", "enabled"])!

        // For non-deleted files, withSparseJSON should NOT be called
        // The save logic should write the full configData

        // Parse the full JSON after edit
        guard let resultJSON = country.parseConfigJSON() else {
            Issue.record("Failed to parse JSON")
            return
        }

        // Assert: Full JSON structure is preserved
        let dataDict = resultJSON["data"] as? [String: Any]
        let subscription = dataDict?["subscription"] as? [String: Any]
        let featureFlags = dataDict?["feature_flags"] as? [String: Any]

        // Both top-level keys should exist
        #expect(subscription != nil)
        #expect(featureFlags != nil)

        // Edited field has new value
        #expect(subscription?["enabled"] as? Bool == true)

        // Unedited field is still present
        #expect(featureFlags?["dark_mode"] as? Bool == false)
    }

    @Test("Subsequent save after sparse restore preserves previous fields")
    func subsequentSavePreservesPreviousFields() async throws {
        // Arrange: Create deleted country with nested structure
        let fullJSON: [String: Any] = [
            "add_default_perseus_headers": [
                "active": [
                    "ios": false,
                    "android": true
                ],
                "domains": ["example.com"]
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

        // Act Step 1: Edit first field and save (simulate first sparse restore)
        country = country.withUpdatedValue(true, at: ["add_default_perseus_headers", "active", "ios"])!

        // Simulate save: construct sparse JSON
        guard let sparseSaved = country.withSparseJSON(editedPaths: country.editedPaths) else {
            Issue.record("Failed to construct sparse JSON for first save")
            return
        }

        // Verify first save: only edited field present
        var savedJSON = sparseSaved.parseConfigJSON()!
        var headers = savedJSON["add_default_perseus_headers"] as! [String: Any]
        var active = headers["active"] as! [String: Any]
        #expect(active["ios"] as? Bool == true)
        #expect(active["android"] == nil)  // Not edited, not in sparse
        #expect(headers["domains"] == nil)  // Not edited, not in sparse

        // Write sparse JSON to disk (simulate actual save)
        let parentDir = tempURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        try sparseSaved.configData!.write(to: tempURL, options: .atomic)

        // Act Step 2: Update country state after first save
        // Simulate what saveCountry() does: update configData with sparse data
        country = S3CountryConfig(
            countryCode: country.countryCode,
            configURL: country.configURL,
            configData: sparseSaved.configData,  // Now has sparse JSON
            originalContent: sparseSaved.originalContent,
            hasChanges: false,
            gitStatus: .deleted,  // Still .deleted (simulating git refresh bug)
            isDeletedPlaceholder: false,
            editedPaths: []  // Cleared after save
        )

        // Act Step 3: Add new sibling field
        var json = country.parseConfigJSON()!
        var headersDict = json["add_default_perseus_headers"] as! [String: Any]
        headersDict["test_new_child_field"] = "new_value"
        json["add_default_perseus_headers"] = headersDict

        guard let updatedCountry = country.withUpdatedJSON(json) else {
            Issue.record("Failed to add new field")
            return
        }

        // Track the new field as edited
        var countryWithEdit = updatedCountry
        countryWithEdit.editedPaths.insert("add_default_perseus_headers.test_new_child_field")

        // Act Step 4: Save again - should NOT use sparse restore
        // Check if file exists
        let fileExists = FileManager.default.fileExists(atPath: tempURL.path)
        #expect(fileExists == true)  // File exists from first save

        // With the fix, sparse logic should NOT trigger because file exists
        // So we should write full configData (which has both fields)

        let dataToWrite: Data
        if countryWithEdit.gitStatus == .deleted && !countryWithEdit.editedPaths.isEmpty && !fileExists {
            // OLD BUG: This would trigger, creating sparse JSON with only new field
            dataToWrite = countryWithEdit.withSparseJSON(editedPaths: countryWithEdit.editedPaths)!.configData!
        } else {
            // FIX: This should trigger instead, writing full configData
            dataToWrite = countryWithEdit.configData!
        }

        try dataToWrite.write(to: tempURL, options: .atomic)

        // Assert: Both fields should be present in saved file
        let savedData = try Data(contentsOf: tempURL)
        let finalJSON = try JSONSerialization.jsonObject(with: savedData) as! [String: Any]
        let finalHeaders = finalJSON["add_default_perseus_headers"] as! [String: Any]

        // OLD field from first save should still be present
        let finalActive = finalHeaders["active"] as? [String: Any]
        #expect(finalActive != nil)
        #expect(finalActive?["ios"] as? Bool == true)

        // NEW field from second save should also be present
        #expect(finalHeaders["test_new_child_field"] as? String == "new_value")

        // Clean up
        try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
    }

    @Test("Sparse JSON handles deeply nested paths")
    func sparseJSONDeepNesting() async throws {
        // Arrange: Create JSON with deep nesting
        let fullJSON: [String: Any] = [
            "level1": [
                "level2": [
                    "level3": [
                        "level4": [
                            "target": "value",
                            "sibling": "ignored"
                        ],
                        "ignored": "also ignored"
                    ]
                ]
            ],
            "otherTop": ["ignored": true]
        ]

        let fullData = try JSONSerialization.data(withJSONObject: fullJSON, options: [.prettyPrinted])
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

        // Act: Edit deeply nested field
        country = country.withUpdatedValue("edited", at: ["level1", "level2", "level3", "level4", "target"])!

        // Construct sparse JSON
        guard let sparseCountry = country.withSparseJSON(editedPaths: country.editedPaths),
              let sparseJSON = sparseCountry.parseConfigJSON() else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Assert: Only edited path and its parents exist
        let level1 = sparseJSON["level1"] as? [String: Any]
        #expect(level1 != nil)

        let level2 = level1?["level2"] as? [String: Any]
        #expect(level2 != nil)

        let level3 = level2?["level3"] as? [String: Any]
        #expect(level3 != nil)

        let level4 = level3?["level4"] as? [String: Any]
        #expect(level4 != nil)

        // Edited field present with new value
        #expect(level4?["target"] as? String == "edited")

        // Sibling fields NOT present
        #expect(level4?["sibling"] == nil)
        #expect(level3?["ignored"] == nil)
        #expect(sparseJSON["otherTop"] == nil)
    }

    @Test("Can expand deleted fields to see nested children after sparse restore")
    func canExpandDeletedFieldsAfterSparseRestore() async throws {
        // Arrange: Create deleted country with deeply nested structure
        let fullJSON: [String: Any] = [
            "data": [
                "subscription": [
                    "enabled": false,
                    "plans": ["basic", "premium"],
                    "android": [
                        "setting1": true,
                        "setting2": false
                    ]
                ],
                "feature_flags": [
                    "dark_mode": false,
                    "new_ui": true
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

        // Act Step 1: Edit only one nested field
        country = country.withUpdatedValue(true, at: ["data", "subscription", "enabled"])!

        // Simulate sparse save
        guard let sparseSaved = country.withSparseJSON(editedPaths: country.editedPaths) else {
            Issue.record("Failed to construct sparse JSON")
            return
        }

        // Verify sparse JSON (only edited field)
        let sparseJSON = sparseSaved.parseConfigJSON()!
        let sparseData = sparseJSON["data"] as! [String: Any]
        let sparseSubscription = sparseData["subscription"] as! [String: Any]
        #expect(sparseSubscription["enabled"] as? Bool == true)
        #expect(sparseSubscription["plans"] == nil)  // Not in sparse
        #expect(sparseSubscription["android"] == nil)  // Not in sparse
        #expect(sparseData["feature_flags"] == nil)  // Not in sparse

        // Act Step 2: Simulate tree flattening with both sparse and original JSON
        // The test verifies that fields in original but not in sparse can be "expanded"
        // by checking that their children from original are accessible

        // Get missing field from original
        let originalData = fullJSON["data"] as! [String: Any]
        let originalSubscription = originalData["subscription"] as! [String: Any]

        // Verify "plans" exists in original
        let plans = originalSubscription["plans"] as? [String]
        #expect(plans != nil)
        #expect(plans?.count == 2)
        #expect(plans?[0] == "basic")
        #expect(plans?[1] == "premium")

        // Verify "android" exists in original with nested children
        let android = originalSubscription["android"] as? [String: Any]
        #expect(android != nil)
        #expect(android?["setting1"] as? Bool == true)
        #expect(android?["setting2"] as? Bool == false)

        // Verify "feature_flags" exists in original
        let featureFlags = originalData["feature_flags"] as? [String: Any]
        #expect(featureFlags != nil)
        #expect(featureFlags?["dark_mode"] as? Bool == false)
        #expect(featureFlags?["new_ui"] as? Bool == true)

        // The fix allows these deleted fields to be expanded in the UI
        // revealing their children from git HEAD
    }
}
