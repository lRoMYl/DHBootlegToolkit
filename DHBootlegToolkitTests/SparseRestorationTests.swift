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
}
