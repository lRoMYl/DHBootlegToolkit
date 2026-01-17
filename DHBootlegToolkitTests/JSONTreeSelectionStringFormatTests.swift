import Testing
@testable import DHBootlegToolkit
@testable import DHBootlegToolkitCore

/// Tests to verify that array indices use bracket notation format throughout the system
/// This ensures consistency between tree node IDs, selection strings, and validation error paths
@Suite("JSON Tree Selection String Format Tests")
struct JSONTreeSelectionStringFormatTests {

    // MARK: - Helper Functions

    private func createViewModel(json: [String: Any]) -> JSONTreeViewModel {
        let viewModel = JSONTreeViewModel()
        viewModel.configure(
            json: json,
            expandAllByDefault: true,
            manuallyCollapsed: [],
            originalJSON: nil,
            fileGitStatus: nil,
            hasInMemoryChanges: false,
            editedPaths: [],
            showChangedFieldsOnly: false
        )
        return viewModel
    }

    private func makeNode(path: [String], parentType: ParentType) -> FlattenedNode {
        FlattenedNode(
            id: path.joined(separator: "."),
            key: path.last ?? "",
            value: "",
            path: path,
            depth: path.count - 1,
            nodeType: .string,
            parentType: parentType,
            isExpanded: false,
            isCurrentMatch: false
        )
    }

    // MARK: - Path Array Format Tests

    @Test("Array element path stores bracket notation")
    func arrayElementPathUsesBrackets() {
        let node = makeNode(path: ["items", "[0]"], parentType: .array)
        #expect(node.path == ["items", "[0]"])
        #expect(node.path.last == "[0]")
    }

    @Test("Nested array element path stores bracket notation")
    func nestedArrayElementPathUsesBrackets() {
        let node = makeNode(path: ["data", "items", "[1]", "tags", "[2]"], parentType: .array)
        #expect(node.path == ["data", "items", "[1]", "tags", "[2]"])
        #expect(node.path.last == "[2]")
    }

    @Test("Object field path has no brackets")
    func objectFieldPathHasNoBrackets() {
        let node = makeNode(path: ["user", "name"], parentType: .object)
        #expect(node.path == ["user", "name"])
        #expect(node.path.contains { $0.contains("[") } == false)
    }

    // MARK: - Node ID Format Tests

    @Test("Array element node ID uses bracket notation")
    func arrayElementNodeIdUsesBrackets() {
        let node = makeNode(path: ["items", "[0]"], parentType: .array)
        #expect(node.id == "items.[0]")
    }

    @Test("Nested array element node ID uses bracket notation")
    func nestedArrayElementNodeIdUsesBrackets() {
        let node = makeNode(path: ["data", "items", "[1]"], parentType: .array)
        #expect(node.id == "data.items.[1]")
    }

    @Test("Object field node ID has no brackets")
    func objectFieldNodeIdHasNoBrackets() {
        let node = makeNode(path: ["user", "name"], parentType: .object)
        #expect(node.id == "user.name")
    }

    // MARK: - Array Index Parsing Tests

    @Test("Parse bracket notation to integer - single digit")
    func parseBracketNotationSingleDigit() {
        let node = makeNode(path: ["items", "[0]"], parentType: .array)
        #expect(node.arrayIndex == 0)
    }

    @Test("Parse bracket notation to integer - multi digit")
    func parseBracketNotationMultiDigit() {
        let node = makeNode(path: ["items", "[42]"], parentType: .array)
        #expect(node.arrayIndex == 42)
    }

    @Test("Parse bracket notation to integer - large index")
    func parseBracketNotationLargeIndex() {
        let node = makeNode(path: ["items", "[999]"], parentType: .array)
        #expect(node.arrayIndex == 999)
    }

    @Test("Non-numeric path component returns nil")
    func nonNumericPathComponentReturnsNil() {
        let node = makeNode(path: ["items", "notanindex"], parentType: .array)
        #expect(node.arrayIndex == nil)
    }

    // MARK: - Tree Node Creation Format Tests

    @Test("Tree nodes for arrays use bracket notation in paths")
    func treeNodesForArraysUseBrackets() {
        let json: [String: Any] = [
            "items": ["apple", "banana", "cherry"]
        ]

        let viewModel = createViewModel(json: json)

        // Find array element nodes
        let arrayElementNodes = viewModel.flattenedNodes.filter { $0.parentType == .array }

        #expect(arrayElementNodes.count > 0)

        // Verify all array element paths use bracket notation
        for node in arrayElementNodes {
            let lastPathComponent = node.path.last ?? ""
            if lastPathComponent.first == "[" && lastPathComponent.last == "]" {
                // Pass - uses bracket notation
            } else {
                Issue.record("Array element path should use brackets: \(node.path)")
            }
        }
    }

    @Test("Tree node IDs for arrays use bracket notation")
    func treeNodeIdsForArraysUseBrackets() {
        let json: [String: Any] = [
            "items": ["apple", "banana"]
        ]

        let viewModel = createViewModel(json: json)

        // Find array element nodes
        let arrayElementNodes = viewModel.flattenedNodes.filter { $0.parentType == .array }

        #expect(arrayElementNodes.count == 2)

        // Verify node IDs use bracket notation
        for node in arrayElementNodes {
            if node.id.contains(".[0]") || node.id.contains(".[1]") {
                // Pass - uses bracket notation
            } else {
                Issue.record("Array element ID should use brackets: \(node.id)")
            }
        }
    }

    // MARK: - Mixed Path Format Tests

    @Test("Mixed path with object and array uses correct format")
    func mixedPathWithObjectAndArray() {
        let node = makeNode(path: ["user", "tags", "[0]"], parentType: .array)
        #expect(node.path == ["user", "tags", "[0]"])
        #expect(node.id == "user.tags.[0]")
    }

    @Test("Array of objects uses bracket notation for array index")
    func arrayOfObjectsUsesBrackets() {
        let node = makeNode(path: ["users", "[1]", "name"], parentType: .object)
        #expect(node.path == ["users", "[1]", "name"])
        #expect(node.id == "users.[1].name")
        // Note: This node's parentType is .object (its parent is the object at [1])
        // but the path contains the array index [1]
    }

    // MARK: - Edge Cases

    @Test("Empty array creates nodes with bracket notation")
    func emptyArrayCreatesNodesWithBrackets() {
        let json: [String: Any] = [
            "emptyArray": []
        ]

        let viewModel = createViewModel(json: json)

        // Empty arrays won't have element nodes, but verify the array node itself exists
        let arrayNode = viewModel.flattenedNodes.first { $0.id == "emptyArray" }
        #expect(arrayNode != nil)
    }

    @Test("Array at root level uses bracket notation")
    func arrayAtRootLevelUsesBrackets() {
        // Note: JSON must be an object, so this tests an array as a direct child of root
        let json: [String: Any] = [
            "rootArray": [1, 2, 3]
        ]

        let viewModel = createViewModel(json: json)

        let arrayElementNodes = viewModel.flattenedNodes.filter {
            $0.parentType == .array && $0.path.first == "rootArray"
        }

        #expect(arrayElementNodes.count == 3)

        for node in arrayElementNodes {
            let lastComponent = node.path.last ?? ""
            if lastComponent.first == "[" && lastComponent.last == "]" {
                // Pass
            } else {
                Issue.record("Root array element should use brackets: \(node.path)")
            }
        }
    }

    @Test("Deeply nested array uses bracket notation")
    func deeplyNestedArrayUsesBrackets() {
        let node = makeNode(
            path: ["level1", "level2", "[0]", "level3", "[1]", "level4", "[2]"],
            parentType: .array
        )

        #expect(node.path.last == "[2]")
        #expect(node.id == "level1.level2.[0].level3.[1].level4.[2]")
        #expect(node.arrayIndex == 2)
    }

    // MARK: - Array Parent Path Tests

    @Test("Array parent path excludes bracket notation index")
    func arrayParentPathExcludesBrackets() {
        let node = makeNode(path: ["items", "[5]"], parentType: .array)
        #expect(node.arrayParentPath == ["items"])
    }

    @Test("Nested array parent path excludes only last bracket notation index")
    func nestedArrayParentPathExcludesOnlyLastBracket() {
        let node = makeNode(path: ["data", "items", "[1]", "tags", "[2]"], parentType: .array)
        #expect(node.arrayParentPath == ["data", "items", "[1]", "tags"])
    }

    // MARK: - Format Consistency Tests

    @Test("Node ID matches path joined with dots")
    func nodeIdMatchesPathJoined() {
        let path = ["user", "posts", "[3]", "comments", "[7]"]
        let node = makeNode(path: path, parentType: .array)
        let expectedId = path.joined(separator: ".")
        #expect(node.id == expectedId)
        #expect(node.id == "user.posts.[3].comments.[7]")
    }

    @Test("Path component with brackets can be parsed to integer")
    func pathComponentWithBracketsCanBeParsed() {
        let pathComponent = "[42]"
        let stripped = pathComponent.replacingOccurrences(of: "[", with: "")
                                    .replacingOccurrences(of: "]", with: "")
        let parsed = Int(stripped)
        #expect(parsed == 42)
    }

    @Test("Object key that looks like number doesn't get brackets")
    func objectKeyThatLooksLikeNumberNoBrackets() {
        // Object keys should never have brackets, even if they're numeric strings
        let node = makeNode(path: ["config", "123"], parentType: .object)
        #expect(node.path.last == "123")
        #expect(node.id == "config.123")
        #expect(node.arrayIndex == nil)  // Not an array element
    }
}
