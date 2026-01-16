@testable import DHBootlegToolkitCore
import Testing
import Foundation

// MARK: - Targeted Replacement Tests

@Suite("S3JSONSerializer Targeted Replacement Tests")
struct S3JSONSerializerTargetedReplacementTests {

    @Test("Replace string value only changes that value")
    func replaceStringValue() {
        let original = """
        {
          "name": "Singapore",
          "code": "sg",
          "enabled": true
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["name"],
            with: "Malaysia"
        )

        let expected = """
        {
          "name": "Malaysia",
          "code": "sg",
          "enabled": true
        }
        """

        #expect(result == expected)
    }

    @Test("Replace boolean value only changes that value")
    func replaceBooleanValue() {
        let original = """
        {
          "name": "Singapore",
          "enabled": true,
          "visible": false
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["enabled"],
            with: false
        )

        let expected = """
        {
          "name": "Singapore",
          "enabled": false,
          "visible": false
        }
        """

        #expect(result == expected)
    }

    @Test("Replace integer value only changes that value")
    func replaceIntegerValue() {
        let original = """
        {
          "name": "Config",
          "count": 42,
          "enabled": true
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["count"],
            with: 100
        )

        let expected = """
        {
          "name": "Config",
          "count": 100,
          "enabled": true
        }
        """

        #expect(result == expected)
    }

    @Test("Replace float value only changes that value")
    func replaceFloatValue() {
        let original = """
        {
          "name": "Config",
          "ratio": 3.14,
          "enabled": true
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["ratio"],
            with: 2.718
        )

        let expected = """
        {
          "name": "Config",
          "ratio": 2.718,
          "enabled": true
        }
        """

        #expect(result == expected)
    }

    @Test("Replace null value")
    func replaceNullValue() {
        let original = """
        {
          "name": "Config",
          "data": null,
          "enabled": true
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["data"],
            with: "value"
        )

        let expected = """
        {
          "name": "Config",
          "data": "value",
          "enabled": true
        }
        """

        #expect(result == expected)
    }

    @Test("Replace nested value preserves parent formatting")
    func replaceNestedValue() {
        let original = """
        {
          "features": {
            "darkMode": {
              "enabled": true,
              "default": false
            }
          }
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["features", "darkMode", "enabled"],
            with: false
        )

        let expected = """
        {
          "features": {
            "darkMode": {
              "enabled": false,
              "default": false
            }
          }
        }
        """

        #expect(result == expected)
    }

    @Test("Replace last property without trailing comma")
    func replaceLastProperty() {
        let original = """
        {
          "first": "one",
          "last": "two"
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["last"],
            with: "updated"
        )

        let expected = """
        {
          "first": "one",
          "last": "updated"
        }
        """

        #expect(result == expected)
    }
}

// MARK: - Array Handling Tests

@Suite("S3JSONSerializer Array Handling Tests")
struct S3JSONSerializerArrayHandlingTests {

    @Test("Replace value in simple array")
    func replaceValueInSimpleArray() {
        let original = """
        {
          "items": ["apple", "banana", "cherry"]
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["items", "1"],
            with: "orange"
        )

        let expected = """
        {
          "items": ["apple", "orange", "cherry"]
        }
        """

        #expect(result == expected)
    }

    @Test("Replace value in multiline array")
    func replaceValueInMultilineArray() {
        let original = """
        {
          "items": [
            "apple",
            "banana",
            "cherry"
          ]
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["items", "1"],
            with: "orange"
        )

        let expected = """
        {
          "items": [
            "apple",
            "orange",
            "cherry"
          ]
        }
        """

        #expect(result == expected)
    }

    @Test("Replace object property in array")
    func replaceObjectPropertyInArray() {
        let original = """
        {
          "users": [
            {
              "name": "Alice",
              "age": 30
            },
            {
              "name": "Bob",
              "age": 25
            }
          ]
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["users", "0", "name"],
            with: "Carol"
        )

        let expected = """
        {
          "users": [
            {
              "name": "Carol",
              "age": 30
            },
            {
              "name": "Bob",
              "age": 25
            }
          ]
        }
        """

        #expect(result == expected)
    }

    @Test("Replace entire array formats with one element per line")
    func replaceEntireArrayFormatsMultiLine() {
        let original = """
        {
          "items": ["old1", "old2"],
          "other": "unchanged"
        }
        """

        let newArray = ["new1", "new2", "new3"]
        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["items"],
            with: newArray
        )

        // Array should be formatted with one element per line
        let expected = """
        {
          "items": [
            "new1",
            "new2",
            "new3"
          ],
          "other": "unchanged"
        }
        """

        #expect(result == expected)
    }

    @Test("Replace entire array with objects formats multi-line")
    func replaceEntireArrayWithObjectsFormatsMultiLine() {
        let original = """
        {
          "users": []
        }
        """

        let newArray: [[String: Any]] = [
            ["name": "Alice", "age": 30],
            ["name": "Bob", "age": 25]
        ]
        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["users"],
            with: newArray
        )

        #expect(result != nil)
        #expect(result?.contains("[\n") == true, "Array should open with newline")
        #expect(result?.contains("\"Alice\"") == true)
        #expect(result?.contains("\"Bob\"") == true)
    }
}

// MARK: - Indentation Detection Tests

@Suite("S3JSONSerializer Indentation Tests")
struct S3JSONSerializerIndentationTests {

    @Test("Preserves 2-space indentation")
    func preserve2SpaceIndentation() {
        let original = """
        {
          "name": "test",
          "nested": {
            "value": true
          }
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["name"],
            with: "updated"
        )

        // Should still use 2-space indentation
        #expect(result?.contains("  \"name\"") == true)
    }

    @Test("Preserves 4-space indentation")
    func preserve4SpaceIndentation() {
        let original = """
        {
            "name": "test",
            "nested": {
                "value": true
            }
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["name"],
            with: "updated"
        )

        // Should still use 4-space indentation
        #expect(result?.contains("    \"name\"") == true)
    }

    @Test("Preserves tab indentation")
    func preserveTabIndentation() {
        let original = "{\n\t\"name\": \"test\",\n\t\"value\": 42\n}"

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["name"],
            with: "updated"
        )

        // Should still use tab indentation
        #expect(result?.contains("\t\"name\"") == true)
    }

    @Test("Detects 4-space indentation correctly")
    func detectsIndentation() {
        let original = """
        {
            "data": {
                "name": "test"
            }
        }
        """

        let indent = S3JSONSerializer.detectIndentation(from: original)
        #expect(indent == "    ")
    }

    @Test("Detects 2-space indentation correctly")
    func detects2SpaceIndentation() {
        let original = """
        {
          "name": "test",
          "nested": {
            "value": true
          }
        }
        """

        let indent = S3JSONSerializer.detectIndentation(from: original)
        #expect(indent == "  ")
    }
}

// MARK: - Edge Case Tests

@Suite("S3JSONSerializer Edge Case Tests")
struct S3JSONSerializerEdgeCaseTests {

    @Test("Handles strings with colons")
    func stringWithColons() {
        let original = """
        {
          "url": "https://example.com",
          "name": "test"
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["url"],
            with: "https://updated.com:8080"
        )

        let expected = """
        {
          "url": "https://updated.com:8080",
          "name": "test"
        }
        """

        #expect(result == expected)
    }

    @Test("Handles strings with escaped quotes")
    func stringWithEscapedQuotes() {
        let original = """
        {
          "message": "Say \\"hello\\"",
          "name": "test"
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["message"],
            with: "Say \"goodbye\""
        )

        let expected = """
        {
          "message": "Say \\"goodbye\\"",
          "name": "test"
        }
        """

        #expect(result == expected)
    }

    @Test("Handles strings with newlines")
    func stringWithNewlines() {
        let original = """
        {
          "text": "line1\\nline2",
          "name": "test"
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["text"],
            with: "updated\ntext"
        )

        let expected = """
        {
          "text": "updated\\ntext",
          "name": "test"
        }
        """

        #expect(result == expected)
    }

    @Test("Handles deeply nested paths")
    func deeplyNestedPath() {
        let original = """
        {
          "level1": {
            "level2": {
              "level3": {
                "level4": {
                  "value": "deep"
                }
              }
            }
          }
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["level1", "level2", "level3", "level4", "value"],
            with: "updated"
        )

        let expected = """
        {
          "level1": {
            "level2": {
              "level3": {
                "level4": {
                  "value": "updated"
                }
              }
            }
          }
        }
        """

        #expect(result == expected)
    }

    @Test("Returns nil for non-existent path")
    func nonExistentPath() {
        let original = """
        {
          "name": "test"
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["nonexistent"],
            with: "value"
        )

        #expect(result == nil)
    }

    @Test("Handles empty string value")
    func emptyStringValue() {
        let original = """
        {
          "name": "test",
          "value": "something"
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["value"],
            with: ""
        )

        let expected = """
        {
          "name": "test",
          "value": ""
        }
        """

        #expect(result == expected)
    }

    @Test("Handles value with special JSON characters")
    func valueWithSpecialCharacters() {
        let original = """
        {
          "data": "simple",
          "name": "test"
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["data"],
            with: "tab\there\nand\\backslash"
        )

        let expected = """
        {
          "data": "tab\\there\\nand\\\\backslash",
          "name": "test"
        }
        """

        #expect(result == expected)
    }
}

// MARK: - Key Order Preservation Tests (Fallback)

@Suite("S3JSONSerializer Key Order Preservation Tests")
struct S3JSONSerializerKeyOrderTests {

    @Test("Preserves original key order")
    func preservesKeyOrder() {
        let original = """
        {
          "zebra": 1,
          "apple": 2,
          "mango": 3
        }
        """

        let json: [String: Any] = ["zebra": 1, "apple": 2, "mango": 3]
        let result = S3JSONSerializer.serialize(json, preservingOrderFrom: original)

        // Keys should be in original order (zebra, apple, mango), not alphabetical
        let zebraIndex = result.range(of: "zebra")?.lowerBound
        let appleIndex = result.range(of: "apple")?.lowerBound
        let mangoIndex = result.range(of: "mango")?.lowerBound

        #expect(zebraIndex != nil)
        #expect(appleIndex != nil)
        #expect(mangoIndex != nil)
        #expect(zebraIndex! < appleIndex!)
        #expect(appleIndex! < mangoIndex!)
    }

    @Test("New keys are appended at end")
    func newKeysAppendedAtEnd() {
        let original = """
        {
          "existing1": 1,
          "existing2": 2
        }
        """

        let json: [String: Any] = ["existing1": 1, "existing2": 2, "newKey": 3]
        let result = S3JSONSerializer.serialize(json, preservingOrderFrom: original)

        // New key should appear after existing keys
        let existing2Index = result.range(of: "existing2")?.lowerBound
        let newKeyIndex = result.range(of: "newKey")?.lowerBound

        #expect(existing2Index != nil)
        #expect(newKeyIndex != nil)
        #expect(existing2Index! < newKeyIndex!)
    }

    @Test("No duplicate keys in output")
    func noDuplicateKeysInOutput() {
        let original = """
        {
          "name": "test",
          "value": 42
        }
        """

        let json: [String: Any] = ["name": "updated", "value": 100]
        let result = S3JSONSerializer.serialize(json, preservingOrderFrom: original)

        // Count occurrences of "name" key
        let nameCount = result.components(separatedBy: "\"name\"").count - 1

        #expect(nameCount == 1)
    }
}

// MARK: - Sequential Edit Tests

@Suite("S3JSONSerializer Sequential Edit Tests")
struct S3JSONSerializerSequentialEditTests {

    @Test("Multiple sequential edits only change their respective values")
    func multipleSequentialEdits() {
        let original = """
        {
          "name": "Singapore",
          "code": "sg",
          "enabled": true,
          "count": 42
        }
        """

        // First edit - change name
        let result1 = S3JSONSerializer.replaceValue(
            in: original,
            at: ["name"],
            with: "Malaysia"
        )
        #expect(result1 != nil)
        #expect(result1?.contains("\"name\": \"Malaysia\"") == true)
        #expect(result1?.contains("\"code\": \"sg\"") == true)
        #expect(result1?.contains("\"enabled\": true") == true)

        // Second edit - change enabled (using result from first edit)
        let result2 = S3JSONSerializer.replaceValue(
            in: result1!,
            at: ["enabled"],
            with: false
        )
        #expect(result2 != nil)
        #expect(result2?.contains("\"name\": \"Malaysia\"") == true)
        #expect(result2?.contains("\"enabled\": false") == true)

        // Third edit - change count (using result from second edit)
        let result3 = S3JSONSerializer.replaceValue(
            in: result2!,
            at: ["count"],
            with: 100
        )
        #expect(result3 != nil)
        #expect(result3?.contains("\"name\": \"Malaysia\"") == true)
        #expect(result3?.contains("\"enabled\": false") == true)
        #expect(result3?.contains("\"count\": 100") == true)

        // Verify the final result has the same structure as original
        let originalLines = original.components(separatedBy: .newlines).count
        let resultLines = result3!.components(separatedBy: .newlines).count
        #expect(originalLines == resultLines)
    }

    @Test("S3CountryConfig withUpdatedValue preserves originalContent")
    func countryConfigPreservesOriginalContent() {
        let original = """
        {
          "name": "Singapore",
          "enabled": true
        }
        """

        let config = S3CountryConfig(
            countryCode: "sg",
            configURL: URL(fileURLWithPath: "/tmp/test.json"),
            configData: original.data(using: .utf8),
            originalContent: original,
            hasChanges: false
        )

        // First update
        let updated1 = config.withUpdatedValue("Malaysia", at: ["name"])
        #expect(updated1 != nil)
        #expect(updated1?.originalContent?.contains("\"name\": \"Malaysia\"") == true)

        // Second update (using result from first)
        let updated2 = updated1?.withUpdatedValue(false, at: ["enabled"])
        #expect(updated2 != nil)
        #expect(updated2?.originalContent?.contains("\"name\": \"Malaysia\"") == true)
        #expect(updated2?.originalContent?.contains("\"enabled\": false") == true)
    }
}

// MARK: - Real File Structure Tests

@Suite("S3JSONSerializer Real File Structure Tests")
struct S3JSONSerializerRealFileStructureTests {

    // Simulates the actual S3 config file structure with "data" wrapper
    let realConfigStructure = """
    {
        "data": {
            "fwf-use-optimized-load": true,
            "disco_base_url": "https://staging.disco.deliveryhero.io",
            "nested_feature": {
                "active": {
                    "ios": true,
                    "and": false
                }
            }
        }
    }
    """

    @Test("Replace boolean value in data wrapper")
    func replaceValueInDataWrapper() {
        let result = S3JSONSerializer.replaceValue(
            in: realConfigStructure,
            at: ["data", "fwf-use-optimized-load"],
            with: false
        )

        #expect(result != nil)
        #expect(result?.contains("\"fwf-use-optimized-load\": false") == true)
        // Ensure other values are unchanged
        #expect(result?.contains("\"disco_base_url\": \"https://staging.disco.deliveryhero.io\"") == true)
    }

    @Test("Replace string value in data wrapper")
    func replaceStringValueInDataWrapper() {
        let result = S3JSONSerializer.replaceValue(
            in: realConfigStructure,
            at: ["data", "disco_base_url"],
            with: "https://prod.disco.deliveryhero.io"
        )

        #expect(result != nil)
        #expect(result?.contains("\"disco_base_url\": \"https://prod.disco.deliveryhero.io\"") == true)
        // Ensure other values are unchanged
        #expect(result?.contains("\"fwf-use-optimized-load\": true") == true)
    }

    @Test("Replace deeply nested value in data wrapper")
    func replaceDeeplyNestedValueInDataWrapper() {
        let result = S3JSONSerializer.replaceValue(
            in: realConfigStructure,
            at: ["data", "nested_feature", "active", "ios"],
            with: false
        )

        #expect(result != nil)
        #expect(result?.contains("\"ios\": false") == true)
        // Ensure other values are unchanged
        #expect(result?.contains("\"and\": false") == true)
        #expect(result?.contains("\"fwf-use-optimized-load\": true") == true)
    }

    @Test("Replace value with hyphenated key")
    func replaceValueWithHyphenatedKey() {
        let original = """
        {
            "data": {
                "some-hyphenated-key": 42,
                "another-key": "value"
            }
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["data", "some-hyphenated-key"],
            with: 100
        )

        #expect(result != nil)
        #expect(result?.contains("\"some-hyphenated-key\": 100") == true)
        #expect(result?.contains("\"another-key\": \"value\"") == true)
    }

    @Test("Sequential edits on real config structure")
    func sequentialEditsOnRealConfig() {
        // First edit
        let result1 = S3JSONSerializer.replaceValue(
            in: realConfigStructure,
            at: ["data", "fwf-use-optimized-load"],
            with: false
        )
        #expect(result1 != nil)
        #expect(result1?.contains("\"fwf-use-optimized-load\": false") == true)

        // Second edit on the result
        let result2 = S3JSONSerializer.replaceValue(
            in: result1!,
            at: ["data", "nested_feature", "active", "ios"],
            with: false
        )
        #expect(result2 != nil)
        #expect(result2?.contains("\"fwf-use-optimized-load\": false") == true) // First change preserved
        #expect(result2?.contains("\"ios\": false") == true) // Second change applied

        // Verify structure is preserved
        let originalLines = realConfigStructure.components(separatedBy: .newlines).count
        let resultLines = result2!.components(separatedBy: .newlines).count
        #expect(originalLines == resultLines)
    }

    @Test("Detects 4-space indentation in real config")
    func detects4SpaceIndentationInRealConfig() {
        let indent = S3JSONSerializer.detectIndentation(from: realConfigStructure)
        #expect(indent == "    ")
    }

    @Test("Replace value in large real-world config")
    func replaceValueInLargeRealWorldConfig() {
        // This mirrors the actual S3 config file structure
        let realConfig = """
        {
            "data": {
                "sentry-variation-key-sampling-ratio": 1,
                "disco_base_url": "https://staging.disco.deliveryhero.io",
                "show-subtotal-in-view-cart-button": {
                    "active": {
                        "and": true,
                        "ios": true,
                        "web": true
                    }
                },
                "fwf-use-optimized-load": true,
                "fwf-use-optimized-load-ios": true,
                "fwf-fetch-multiple-attributes": true,
                "use_adjust_over_skan": true,
                "sentry_sdk_config": {
                    "app_hang_tracking": {
                        "active": {
                            "ios": true,
                            "and": false,
                            "web": false
                        },
                        "sample_rate": {
                            "ios": 0.1,
                            "and": 0
                        }
                    }
                }
            }
        }
        """

        // Test changing a top-level boolean in data
        let result1 = S3JSONSerializer.replaceValue(
            in: realConfig,
            at: ["data", "fwf-use-optimized-load"],
            with: false
        )
        #expect(result1 != nil)
        #expect(result1?.contains("\"fwf-use-optimized-load\": false") == true)
        // Verify other values are unchanged
        #expect(result1?.contains("\"disco_base_url\": \"https://staging.disco.deliveryhero.io\"") == true)
        #expect(result1?.contains("\"sentry-variation-key-sampling-ratio\": 1") == true)

        // Test changing a deeply nested boolean
        let result2 = S3JSONSerializer.replaceValue(
            in: realConfig,
            at: ["data", "sentry_sdk_config", "app_hang_tracking", "active", "ios"],
            with: false
        )
        #expect(result2 != nil)
        // Find the specific nested ios value (not the one in show-subtotal)
        let components = result2!.components(separatedBy: "app_hang_tracking")
        #expect(components.count > 1)
        let afterAppHang = components[1]
        #expect(afterAppHang.contains("\"ios\": false"))
        // Other values should be unchanged
        #expect(result2?.contains("\"fwf-use-optimized-load\": true") == true)

        // Verify line count is preserved (structure unchanged)
        let originalLines = realConfig.components(separatedBy: .newlines).count
        let result1Lines = result1!.components(separatedBy: .newlines).count
        let result2Lines = result2!.components(separatedBy: .newlines).count
        #expect(originalLines == result1Lines)
        #expect(originalLines == result2Lines)
    }

    @Test("S3CountryConfig integration with real file structure")
    func countryConfigIntegrationWithRealStructure() {
        let realConfig = """
        {
            "data": {
                "feature_flag": true,
                "settings": {
                    "enabled": false,
                    "value": 42
                }
            }
        }
        """

        let config = S3CountryConfig(
            countryCode: "sg",
            configURL: URL(fileURLWithPath: "/tmp/test.json"),
            configData: realConfig.data(using: .utf8),
            originalContent: realConfig,
            hasChanges: false
        )

        // First update - should use targeted replacement
        let updated1 = config.withUpdatedValue(false, at: ["data", "feature_flag"])
        #expect(updated1 != nil)
        #expect(updated1?.originalContent?.contains("\"feature_flag\": false") == true)
        // Verify structure preserved
        #expect(updated1?.originalContent?.contains("\"settings\"") == true)
        #expect(updated1?.originalContent?.contains("\"enabled\": false") == true)

        // Second update - should also use targeted replacement on updated content
        let updated2 = updated1?.withUpdatedValue(true, at: ["data", "settings", "enabled"])
        #expect(updated2 != nil)
        #expect(updated2?.originalContent?.contains("\"feature_flag\": false") == true) // First change preserved
        #expect(updated2?.originalContent?.contains("\"enabled\": true") == true) // Second change applied

        // Verify line counts match
        let originalLines = realConfig.components(separatedBy: .newlines).count
        let updated2Lines = updated2?.originalContent?.components(separatedBy: .newlines).count
        #expect(originalLines == updated2Lines)
    }

    @Test("Load and modify actual SG config file")
    func loadAndModifyActualSGConfig() throws {
        // Path to the actual SG config file
        let configPath = "/Users/romy.cheah/Repos/static.fd-api.com/s3root/feature-config/staging/sg/config.json"
        let configURL = URL(fileURLWithPath: configPath)

        // Skip if file doesn't exist (CI environments)
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: configPath) else {
            return
        }

        // Load the file content
        let originalContent = try String(contentsOf: configURL, encoding: .utf8)

        // Verify we can load and parse it
        guard let data = originalContent.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Issue.record("Failed to parse config file as JSON")
            return
        }

        // Test targeted replacement on the actual file content
        let result = S3JSONSerializer.replaceValue(
            in: originalContent,
            at: ["data", "fwf-use-optimized-load"],
            with: false
        )

        #expect(result != nil, "Targeted replacement should succeed on actual file")

        if let result = result {
            // Verify the change was made
            #expect(result.contains("\"fwf-use-optimized-load\": false"))

            // Verify other values are unchanged
            #expect(result.contains("\"disco_base_url\""))
            #expect(result.contains("staging.disco.deliveryhero.io"))

            // Verify line count is preserved
            let originalLines = originalContent.components(separatedBy: .newlines).count
            let resultLines = result.components(separatedBy: .newlines).count
            #expect(originalLines == resultLines, "Line count should be preserved: original=\(originalLines), result=\(resultLines)")

            // Verify character count is similar (should only differ by value length)
            let originalLength = originalContent.count
            let resultLength = result.count
            let lengthDiff = abs(originalLength - resultLength)
            // The difference should be minimal - just "true" vs "false" (1 char)
            #expect(lengthDiff <= 10, "Character count difference should be small: diff=\(lengthDiff)")
        }
    }

    @Test("S3CountryConfig full flow with actual file")
    func countryConfigFullFlowWithActualFile() throws {
        // Path to the actual SG config file
        let configPath = "/Users/romy.cheah/Repos/static.fd-api.com/s3root/feature-config/staging/sg/config.json"
        let configURL = URL(fileURLWithPath: configPath)

        // Skip if file doesn't exist (CI environments)
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: configPath) else {
            return
        }

        // Load the file exactly as S3Store does
        let configData = try Data(contentsOf: configURL)
        let originalContent = try String(contentsOf: configURL, encoding: .utf8)

        let config = S3CountryConfig(
            countryCode: "sg",
            configURL: configURL,
            configData: configData,
            originalContent: originalContent,
            hasChanges: false
        )

        // Verify original content is set
        #expect(config.originalContent != nil)
        #expect(config.configData != nil)

        // Perform an update using the same flow as the UI
        let updated = config.withUpdatedValue(false, at: ["data", "fwf-use-optimized-load"])

        #expect(updated != nil, "Update should succeed")

        if let updated = updated {
            #expect(updated.hasChanges == true)
            #expect(updated.originalContent != nil)

            // Verify targeted replacement worked by checking line counts
            let originalLines = originalContent.components(separatedBy: .newlines).count
            let updatedLines = updated.originalContent!.components(separatedBy: .newlines).count
            #expect(originalLines == updatedLines, "Line counts should match: original=\(originalLines), updated=\(updatedLines)")

            // Verify the value was changed
            #expect(updated.originalContent!.contains("\"fwf-use-optimized-load\": false"))

            // Verify character count difference is minimal
            let originalLength = originalContent.count
            let updatedLength = updated.originalContent!.count
            let lengthDiff = abs(originalLength - updatedLength)
            #expect(lengthDiff <= 10, "Length diff should be minimal: \(lengthDiff)")
        }
    }
}

// MARK: - Value Serialization Tests

@Suite("S3JSONSerializer Value Serialization Tests")
struct S3JSONSerializerValueSerializationTests {

    @Test("Serializes boolean true correctly")
    func serializesBooleanTrue() {
        let original = """
        {
          "enabled": false
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["enabled"],
            with: true
        )

        #expect(result?.contains("true") == true)
        #expect(result?.contains("\"true\"") == false) // Should not be quoted
    }

    @Test("Serializes boolean false correctly")
    func serializesBooleanFalse() {
        let original = """
        {
          "enabled": true
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["enabled"],
            with: false
        )

        #expect(result?.contains("false") == true)
        #expect(result?.contains("\"false\"") == false) // Should not be quoted
    }

    @Test("Serializes null correctly")
    func serializesNull() {
        let original = """
        {
          "data": "something"
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["data"],
            with: NSNull()
        )

        #expect(result?.contains("null") == true)
        #expect(result?.contains("\"null\"") == false) // Should not be quoted
    }

    @Test("Serializes negative number correctly")
    func serializesNegativeNumber() {
        let original = """
        {
          "value": 0
        }
        """

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["value"],
            with: -42
        )

        #expect(result?.contains("-42") == true)
    }
}

// MARK: - Targeted Field Update Tests (Direct Save & Multi-Country Flow)

@Suite("S3CountryConfig Targeted Field Update Tests")
struct S3CountryConfigTargetedFieldUpdateTests {

    /// Creates a test S3CountryConfig with the given JSON content
    private func createConfig(json: String) -> S3CountryConfig {
        let data = json.data(using: .utf8)!
        return S3CountryConfig(
            countryCode: "sg",
            configURL: URL(fileURLWithPath: "/tmp/sg/config.json"),
            configData: data,
            originalContent: json,
            hasChanges: false
        )
    }

    // MARK: - Direct Save Flow Tests (Detail Page)

    @Test("Direct save only changes specific string field")
    func directSaveOnlyChangesSpecificStringField() {
        let original = """
        {
          "country": "Singapore",
          "code": "sg",
          "settings": {
            "enabled": true,
            "name": "Original Name",
            "count": 42
          }
        }
        """

        let config = createConfig(json: original)
        let updated = config.withUpdatedValue("New Name", at: ["settings", "name"])

        #expect(updated != nil)
        guard let updated = updated else { return }

        // Verify only the target field changed
        let updatedContent = updated.originalContent!
        #expect(updatedContent.contains("\"name\": \"New Name\""))
        #expect(updatedContent.contains("\"country\": \"Singapore\""))
        #expect(updatedContent.contains("\"code\": \"sg\""))
        #expect(updatedContent.contains("\"enabled\": true"))
        #expect(updatedContent.contains("\"count\": 42"))

        // Verify line count is preserved (no structural changes)
        let originalLines = original.components(separatedBy: .newlines).count
        let updatedLines = updatedContent.components(separatedBy: .newlines).count
        #expect(originalLines == updatedLines, "Line count should be preserved")

        // Verify minimal character difference (only the value changed)
        let charDiff = abs(original.count - updatedContent.count)
        let expectedDiff = abs("Original Name".count - "New Name".count)
        #expect(charDiff == expectedDiff, "Only the value length should change")
    }

    @Test("Direct save only changes specific boolean field")
    func directSaveOnlyChangesSpecificBooleanField() {
        let original = """
        {
          "feature": {
            "enabled": true,
            "visible": false,
            "name": "Test Feature"
          }
        }
        """

        let config = createConfig(json: original)
        let updated = config.withUpdatedValue(false, at: ["feature", "enabled"])

        #expect(updated != nil)
        guard let updated = updated else { return }

        let updatedContent = updated.originalContent!
        #expect(updatedContent.contains("\"enabled\": false"))
        #expect(updatedContent.contains("\"visible\": false"))
        #expect(updatedContent.contains("\"name\": \"Test Feature\""))

        // Verify exact match except for the changed value
        let expected = """
        {
          "feature": {
            "enabled": false,
            "visible": false,
            "name": "Test Feature"
          }
        }
        """
        #expect(updatedContent == expected)
    }

    @Test("Direct save only changes specific numeric field")
    func directSaveOnlyChangesSpecificNumericField() {
        let original = """
        {
          "config": {
            "timeout": 30,
            "retries": 3,
            "enabled": true
          }
        }
        """

        let config = createConfig(json: original)
        let updated = config.withUpdatedValue(60, at: ["config", "timeout"])

        #expect(updated != nil)
        guard let updated = updated else { return }

        let updatedContent = updated.originalContent!
        #expect(updatedContent.contains("\"timeout\": 60"))
        #expect(updatedContent.contains("\"retries\": 3"))
        #expect(updatedContent.contains("\"enabled\": true"))
    }

    // MARK: - Multi-Country Flow Tests (Batch Update Wizard)

    @Test("Multi-country flow only changes specific field in each country")
    func multiCountryFlowOnlyChangesSpecificField() {
        // Simulate what applyFieldToCountries does
        let sgOriginal = """
        {
          "country": "Singapore",
          "settings": {
            "theme": "light",
            "language": "en"
          }
        }
        """

        let myOriginal = """
        {
          "country": "Malaysia",
          "settings": {
            "theme": "dark",
            "language": "ms"
          }
        }
        """

        let sgConfig = createConfig(json: sgOriginal)
        let myConfig = S3CountryConfig(
            countryCode: "my",
            configURL: URL(fileURLWithPath: "/tmp/my/config.json"),
            configData: myOriginal.data(using: .utf8)!,
            originalContent: myOriginal,
            hasChanges: false
        )

        // Apply "light" theme to both (simulating wizard flow)
        let valueToApply = "light"
        let pathComponents = ["settings", "theme"]

        let sgUpdated = sgConfig.withUpdatedValue(valueToApply, at: pathComponents)
        let myUpdated = myConfig.withUpdatedValue(valueToApply, at: pathComponents)

        #expect(sgUpdated != nil)
        #expect(myUpdated != nil)

        // Singapore should be unchanged (already has "light")
        #expect(sgUpdated!.originalContent!.contains("\"theme\": \"light\""))
        #expect(sgUpdated!.originalContent!.contains("\"country\": \"Singapore\""))
        #expect(sgUpdated!.originalContent!.contains("\"language\": \"en\""))

        // Malaysia should only have theme changed
        let myContent = myUpdated!.originalContent!
        #expect(myContent.contains("\"theme\": \"light\""))
        #expect(myContent.contains("\"country\": \"Malaysia\""))
        #expect(myContent.contains("\"language\": \"ms\""))

        // Verify line counts preserved
        let myOriginalLines = myOriginal.components(separatedBy: .newlines).count
        let myUpdatedLines = myContent.components(separatedBy: .newlines).count
        #expect(myOriginalLines == myUpdatedLines)
    }

    @Test("Multi-country flow preserves key order")
    func multiCountryFlowPreservesKeyOrder() {
        let original = """
        {
          "zebra": "last",
          "alpha": "first",
          "middle": {
            "zeta": 1,
            "beta": 2
          }
        }
        """

        let config = createConfig(json: original)
        let updated = config.withUpdatedValue(99, at: ["middle", "beta"])

        #expect(updated != nil)
        guard let updated = updated else { return }

        let updatedContent = updated.originalContent!

        // Verify key order is preserved (zebra before alpha, zeta before beta)
        let zebraIndex = updatedContent.range(of: "zebra")!.lowerBound
        let alphaIndex = updatedContent.range(of: "alpha")!.lowerBound
        let zetaIndex = updatedContent.range(of: "zeta")!.lowerBound
        let betaIndex = updatedContent.range(of: "beta")!.lowerBound

        #expect(zebraIndex < alphaIndex, "Key order should be preserved: zebra before alpha")
        #expect(zetaIndex < betaIndex, "Key order should be preserved: zeta before beta")
    }

    @Test("Multi-country flow preserves whitespace and formatting")
    func multiCountryFlowPreservesFormatting() {
        // Use specific indentation style
        let original = """
        {
            "config": {
                "value": "old",
                "other": "unchanged"
            }
        }
        """

        let config = createConfig(json: original)
        let updated = config.withUpdatedValue("new", at: ["config", "value"])

        #expect(updated != nil)
        guard let updated = updated else { return }

        let expected = """
        {
            "config": {
                "value": "new",
                "other": "unchanged"
            }
        }
        """
        #expect(updated.originalContent == expected)
    }

    @Test("Multi-country flow handles deeply nested fields")
    func multiCountryFlowHandlesDeeplyNestedFields() {
        let original = """
        {
          "level1": {
            "level2": {
              "level3": {
                "target": "original",
                "sibling": "untouched"
              }
            }
          }
        }
        """

        let config = createConfig(json: original)
        let updated = config.withUpdatedValue("updated", at: ["level1", "level2", "level3", "target"])

        #expect(updated != nil)
        guard let updated = updated else { return }

        let updatedContent = updated.originalContent!
        #expect(updatedContent.contains("\"target\": \"updated\""))
        #expect(updatedContent.contains("\"sibling\": \"untouched\""))

        // Verify exact structure preserved
        let expected = """
        {
          "level1": {
            "level2": {
              "level3": {
                "target": "updated",
                "sibling": "untouched"
              }
            }
          }
        }
        """
        #expect(updatedContent == expected)
    }

    @Test("Consecutive updates only change their respective fields")
    func consecutiveUpdatesOnlyChangeRespectiveFields() {
        let original = """
        {
          "field1": "value1",
          "field2": "value2",
          "field3": "value3"
        }
        """

        var config = createConfig(json: original)

        // First update
        let updated1 = config.withUpdatedValue("updated1", at: ["field1"])
        #expect(updated1 != nil)
        config = updated1!

        // Second update
        let updated2 = config.withUpdatedValue("updated2", at: ["field2"])
        #expect(updated2 != nil)
        config = updated2!

        // Third update
        let updated3 = config.withUpdatedValue("updated3", at: ["field3"])
        #expect(updated3 != nil)

        let finalContent = updated3!.originalContent!
        let expected = """
        {
          "field1": "updated1",
          "field2": "updated2",
          "field3": "updated3"
        }
        """
        #expect(finalContent == expected)
    }

    @Test("Apply array value via withUpdatedValue formats multi-line (wizard flow)")
    func applyArrayValueViaWithUpdatedValueFormatsMultiLine() {
        // This simulates exactly what the Batch Update wizard does
        let original = """
        {
          "features": ["feature1", "feature2"],
          "name": "Test Country"
        }
        """

        let config = createConfig(json: original)

        // Simulate applying a new array value (like wizard would do)
        let newArrayValue: [Any] = ["newFeature1", "newFeature2", "newFeature3"]
        let updated = config.withUpdatedValue(newArrayValue, at: ["features"])

        #expect(updated != nil)
        guard let updated = updated else { return }

        let updatedContent = updated.originalContent!

        // Array should be formatted with one element per line
        let expected = """
        {
          "features": [
            "newFeature1",
            "newFeature2",
            "newFeature3"
          ],
          "name": "Test Country"
        }
        """

        #expect(updatedContent == expected, "Array should be formatted with one element per line. Got:\n\(updatedContent)")
    }

    @Test("Apply nested array value via withUpdatedValue formats multi-line")
    func applyNestedArrayValueFormatsMultiLine() {
        let original = """
        {
          "config": {
            "items": ["a", "b"],
            "enabled": true
          }
        }
        """

        let config = createConfig(json: original)
        let newArrayValue: [Any] = ["x", "y", "z"]
        let updated = config.withUpdatedValue(newArrayValue, at: ["config", "items"])

        #expect(updated != nil)
        guard let updated = updated else { return }

        let updatedContent = updated.originalContent!

        // Should have multi-line array
        #expect(updatedContent.contains("\"items\": [\n"), "Array should open with newline")
        #expect(updatedContent.contains("\"x\""), "Should contain new values")
        #expect(updatedContent.contains("\"y\""))
        #expect(updatedContent.contains("\"z\""))
    }
}

// MARK: - Object Key Order Preservation Tests (Wizard Flow)

@Suite("S3JSONSerializer Object Key Order Preservation Tests")
struct S3JSONSerializerObjectKeyOrderTests {

    @Test("Replace object value preserves target key order")
    func replaceObjectPreservesTargetKeyOrder() {
        let original = """
        {
          "config": {
            "zebra": "z",
            "alpha": "a",
            "middle": "m"
          }
        }
        """

        // New value has different order and values
        let newValue: [String: Any] = [
            "alpha": "new_a",
            "zebra": "new_z",
            "middle": "new_m"
        ]

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["config"],
            with: newValue
        )

        #expect(result != nil)
        guard let result = result else { return }

        // Keys should maintain original order: zebra, alpha, middle
        let zebraIndex = result.range(of: "zebra")!.lowerBound
        let alphaIndex = result.range(of: "alpha")!.lowerBound
        let middleIndex = result.range(of: "middle")!.lowerBound

        #expect(zebraIndex < alphaIndex, "Key order should be preserved: zebra before alpha")
        #expect(alphaIndex < middleIndex, "Key order should be preserved: alpha before middle")
    }

    @Test("Replace nested object preserves key order at all levels")
    func replaceNestedObjectPreservesKeyOrder() {
        let original = """
        {
          "address_config": {
            "address_format": "old_format",
            "hidden_form_fields": ["field1"],
            "extra_address_format": "old_extra",
            "geocoding_format": "old_geocoding"
          }
        }
        """

        // New value with same keys but different order in Swift dict
        let newValue: [String: Any] = [
            "geocoding_format": "new_geocoding",
            "hidden_form_fields": ["field1", "field2"],
            "address_format": "new_format",
            "extra_address_format": "new_extra"
        ]

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["address_config"],
            with: newValue
        )

        #expect(result != nil)
        guard let result = result else { return }

        // Keys should maintain original order: address_format, hidden_form_fields, extra_address_format, geocoding_format
        let addressFormatIndex = result.range(of: "address_format")!.lowerBound
        let hiddenFormFieldsIndex = result.range(of: "hidden_form_fields")!.lowerBound
        let extraAddressFormatIndex = result.range(of: "extra_address_format")!.lowerBound
        let geocodingFormatIndex = result.range(of: "geocoding_format")!.lowerBound

        #expect(addressFormatIndex < hiddenFormFieldsIndex, "address_format should come before hidden_form_fields")
        #expect(hiddenFormFieldsIndex < extraAddressFormatIndex, "hidden_form_fields should come before extra_address_format")
        #expect(extraAddressFormatIndex < geocodingFormatIndex, "extra_address_format should come before geocoding_format")
    }

    @Test("New keys in replacement object are appended at end")
    func newKeysAppendedAtEnd() {
        let original = """
        {
          "config": {
            "existing1": "a",
            "existing2": "b"
          }
        }
        """

        // New value with extra key
        let newValue: [String: Any] = [
            "existing1": "new_a",
            "existing2": "new_b",
            "newKey": "c"
        ]

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["config"],
            with: newValue
        )

        #expect(result != nil)
        guard let result = result else { return }

        // New key should appear after existing keys
        let existing2Index = result.range(of: "existing2")!.lowerBound
        let newKeyIndex = result.range(of: "newKey")!.lowerBound

        #expect(existing2Index < newKeyIndex, "New key should be appended at end")
    }

    @Test("Replace deeply nested object preserves key order")
    func replaceDeeplyNestedObjectPreservesKeyOrder() {
        let original = """
        {
          "level1": {
            "level2": {
              "zebra": 1,
              "alpha": 2,
              "beta": 3
            }
          }
        }
        """

        let newValue: [String: Any] = [
            "beta": 30,
            "alpha": 20,
            "zebra": 10
        ]

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["level1", "level2"],
            with: newValue
        )

        #expect(result != nil)
        guard let result = result else { return }

        let zebraIndex = result.range(of: "zebra")!.lowerBound
        let alphaIndex = result.range(of: "alpha")!.lowerBound
        let betaIndex = result.range(of: "beta")!.lowerBound

        #expect(zebraIndex < alphaIndex, "Key order should be preserved: zebra before alpha")
        #expect(alphaIndex < betaIndex, "Key order should be preserved: alpha before beta")
    }

    @Test("Replace object with nested objects preserves all key orders")
    func replaceObjectWithNestedObjectsPreservesAllKeyOrders() {
        let original = """
        {
          "config": {
            "outer_z": "z",
            "outer_a": "a",
            "nested": {
              "inner_z": 1,
              "inner_a": 2
            }
          }
        }
        """

        let newValue: [String: Any] = [
            "outer_a": "new_a",
            "outer_z": "new_z",
            "nested": [
                "inner_a": 20,
                "inner_z": 10
            ]
        ]

        let result = S3JSONSerializer.replaceValue(
            in: original,
            at: ["config"],
            with: newValue
        )

        #expect(result != nil)
        guard let result = result else { return }

        // Check outer key order
        let outerZIndex = result.range(of: "outer_z")!.lowerBound
        let outerAIndex = result.range(of: "outer_a")!.lowerBound

        #expect(outerZIndex < outerAIndex, "Outer key order should be preserved")

        // Check inner key order
        let innerZIndex = result.range(of: "inner_z")!.lowerBound
        let innerAIndex = result.range(of: "inner_a")!.lowerBound

        #expect(innerZIndex < innerAIndex, "Inner key order should be preserved")
    }

    @Test("S3CountryConfig withUpdatedValue preserves object key order (wizard flow)")
    func countryConfigWithUpdatedValuePreservesObjectKeyOrder() {
        let original = """
        {
          "data": {
            "address_config": {
              "address_format": "old",
              "hidden_form_fields": [],
              "geocoding_format": "old_geo"
            }
          }
        }
        """

        let data = original.data(using: .utf8)!
        let config = S3CountryConfig(
            countryCode: "bg",
            configURL: URL(fileURLWithPath: "/tmp/bg/config.json"),
            configData: data,
            originalContent: original,
            hasChanges: false
        )

        // Apply new address_config (simulating wizard flow)
        let newAddressConfig: [String: Any] = [
            "geocoding_format": "new_geo",
            "hidden_form_fields": ["field1"],
            "address_format": "new"
        ]

        let updated = config.withUpdatedValue(newAddressConfig, at: ["data", "address_config"])

        #expect(updated != nil)
        guard let updated = updated else { return }

        let updatedContent = updated.originalContent!

        // Keys should maintain original order: address_format, hidden_form_fields, geocoding_format
        let addressFormatIndex = updatedContent.range(of: "address_format")!.lowerBound
        let hiddenFormFieldsIndex = updatedContent.range(of: "hidden_form_fields")!.lowerBound
        let geocodingFormatIndex = updatedContent.range(of: "geocoding_format")!.lowerBound

        #expect(addressFormatIndex < hiddenFormFieldsIndex, "address_format should come before hidden_form_fields")
        #expect(hiddenFormFieldsIndex < geocodingFormatIndex, "hidden_form_fields should come before geocoding_format")
    }

    @Test("Real-world address_config replacement preserves key order")
    func realWorldAddressConfigPreservesKeyOrder() {
        // Simulates the actual bg/config.json structure
        let bgOriginal = """
        {
          "data": {
            "address_config": {
              "address_format": "%houseNumber %street, %city, %zip",
              "hidden_form_fields": [
                "entrance",
                "floor",
                "company"
              ],
              "extra_address_format": "%houseNumber %street",
              "geocoding_format": "%street %houseNumber",
              "pin_distance_threshold_meters": 150,
              "pin_min_distance_threshold_meters": 5
            }
          }
        }
        """

        // Simulates applying sg's address_config
        let newAddressConfig: [String: Any] = [
            "pin_min_distance_threshold_meters": 10,
            "address_format": "%houseNumber %street, %postalCode",
            "hidden_form_fields": ["entrance"],
            "extra_address_format": "%street %houseNumber",
            "geocoding_format": "%street",
            "pin_distance_threshold_meters": 200
        ]

        let result = S3JSONSerializer.replaceValue(
            in: bgOriginal,
            at: ["data", "address_config"],
            with: newAddressConfig
        )

        #expect(result != nil)
        guard let result = result else { return }

        // Verify keys are in bg's original order, not scrambled
        let addressFormatIndex = result.range(of: "address_format")!.lowerBound
        let hiddenFormFieldsIndex = result.range(of: "hidden_form_fields")!.lowerBound
        let extraAddressFormatIndex = result.range(of: "extra_address_format")!.lowerBound
        let geocodingFormatIndex = result.range(of: "geocoding_format")!.lowerBound
        let pinDistanceIndex = result.range(of: "pin_distance_threshold_meters")!.lowerBound
        let pinMinDistanceIndex = result.range(of: "pin_min_distance_threshold_meters")!.lowerBound

        // Order should be: address_format, hidden_form_fields, extra_address_format, geocoding_format, pin_distance, pin_min_distance
        #expect(addressFormatIndex < hiddenFormFieldsIndex, "address_format should come first")
        #expect(hiddenFormFieldsIndex < extraAddressFormatIndex, "hidden_form_fields should come before extra_address_format")
        #expect(extraAddressFormatIndex < geocodingFormatIndex, "extra_address_format should come before geocoding_format")
        #expect(geocodingFormatIndex < pinDistanceIndex, "geocoding_format should come before pin_distance_threshold_meters")
        #expect(pinDistanceIndex < pinMinDistanceIndex, "pin_distance should come before pin_min_distance")
    }
}
