import Testing
@testable import DHBootlegToolkit

// MARK: - Context Menu Permutation Tests

@Suite("Context Menu Permutation Tests")
struct ContextMenuPermutationTests {

    // MARK: - Helper to Create Test Nodes

    private func makeNode(
        nodeType: JSONNodeType,
        parentType: ParentType
    ) -> FlattenedNode {
        FlattenedNode(
            id: "test",
            key: "testKey",
            value: "",
            path: ["test"],
            depth: 0,
            nodeType: nodeType,
            parentType: parentType,
            isExpanded: false,
            isCurrentMatch: false
        )
    }

    // MARK: - Add Child Field Tests (Only for Objects)

    @Test("Object at root - can add child")
    func objectAtRootCanAddChild() {
        let node = makeNode(nodeType: .object(keyCount: 0), parentType: .root)
        #expect(node.canAddChildField == true)
    }

    @Test("Object in object - can add child")
    func objectInObjectCanAddChild() {
        let node = makeNode(nodeType: .object(keyCount: 0), parentType: .object)
        #expect(node.canAddChildField == true)
    }

    @Test("Object in array - can add child")
    func objectInArrayCanAddChild() {
        let node = makeNode(nodeType: .object(keyCount: 0), parentType: .array)
        #expect(node.canAddChildField == true)
    }

    @Test("Array at root - cannot add child")
    func arrayAtRootCannotAddChild() {
        let node = makeNode(nodeType: .array(itemCount: 0), parentType: .root)
        #expect(node.canAddChildField == false)
    }

    @Test("Array in object - cannot add child")
    func arrayInObjectCannotAddChild() {
        let node = makeNode(nodeType: .array(itemCount: 0), parentType: .object)
        #expect(node.canAddChildField == false)
    }

    @Test("Array in array - cannot add child")
    func arrayInArrayCannotAddChild() {
        let node = makeNode(nodeType: .array(itemCount: 0), parentType: .array)
        #expect(node.canAddChildField == false)
    }

    @Test("String (primitive) - cannot add child")
    func stringCannotAddChild() {
        let node = makeNode(nodeType: .string, parentType: .object)
        #expect(node.canAddChildField == false)
    }

    @Test("Int (primitive) - cannot add child")
    func intCannotAddChild() {
        let node = makeNode(nodeType: .int, parentType: .object)
        #expect(node.canAddChildField == false)
    }

    @Test("Bool (primitive) - cannot add child")
    func boolCannotAddChild() {
        let node = makeNode(nodeType: .bool, parentType: .object)
        #expect(node.canAddChildField == false)
    }

    @Test("Null (primitive) - cannot add child")
    func nullCannotAddChild() {
        let node = makeNode(nodeType: .null, parentType: .object)
        #expect(node.canAddChildField == false)
    }

    // MARK: - Add Sibling Field Tests (Only When Parent is Object)

    @Test("Node at root - cannot add sibling")
    func nodeAtRootCannotAddSibling() {
        let node = makeNode(nodeType: .string, parentType: .root)
        #expect(node.canAddSiblingField == false)
    }

    @Test("Node in object - can add sibling")
    func nodeInObjectCanAddSibling() {
        let node = makeNode(nodeType: .string, parentType: .object)
        #expect(node.canAddSiblingField == true)
    }

    @Test("Node in array - cannot add sibling")
    func nodeInArrayCannotAddSibling() {
        let node = makeNode(nodeType: .string, parentType: .array)
        #expect(node.canAddSiblingField == false)
    }

    @Test("Object at root - cannot add sibling")
    func objectAtRootCannotAddSibling() {
        let node = makeNode(nodeType: .object(keyCount: 0), parentType: .root)
        #expect(node.canAddSiblingField == false)
    }

    @Test("Object in object - can add sibling")
    func objectInObjectCanAddSibling() {
        let node = makeNode(nodeType: .object(keyCount: 0), parentType: .object)
        #expect(node.canAddSiblingField == true)
    }

    @Test("Object in array - cannot add sibling")
    func objectInArrayCannotAddSibling() {
        let node = makeNode(nodeType: .object(keyCount: 0), parentType: .array)
        #expect(node.canAddSiblingField == false)
    }

    @Test("Array at root - cannot add sibling")
    func arrayAtRootCannotAddSibling() {
        let node = makeNode(nodeType: .array(itemCount: 0), parentType: .root)
        #expect(node.canAddSiblingField == false)
    }

    @Test("Array in object - can add sibling")
    func arrayInObjectCanAddSibling() {
        let node = makeNode(nodeType: .array(itemCount: 0), parentType: .object)
        #expect(node.canAddSiblingField == true)
    }

    @Test("Array in array - cannot add sibling")
    func arrayInArrayCannotAddSibling() {
        let node = makeNode(nodeType: .array(itemCount: 0), parentType: .array)
        #expect(node.canAddSiblingField == false)
    }

    // MARK: - Delete Field Tests (Not Available for Array Elements)

    @Test("Node at root - can delete field")
    func nodeAtRootCanDelete() {
        let node = makeNode(nodeType: .string, parentType: .root)
        #expect(node.canDeleteField == true)
    }

    @Test("Node in object - can delete field")
    func nodeInObjectCanDelete() {
        let node = makeNode(nodeType: .string, parentType: .object)
        #expect(node.canDeleteField == true)
    }

    @Test("Node in array - cannot delete field (use delete element)")
    func nodeInArrayCannotDeleteField() {
        let node = makeNode(nodeType: .string, parentType: .array)
        #expect(node.canDeleteField == false)
    }

    @Test("Object - can delete field")
    func objectCanDelete() {
        let node = makeNode(nodeType: .object(keyCount: 0), parentType: .object)
        #expect(node.canDeleteField == true)
    }

    @Test("Array - can delete field")
    func arrayCanDelete() {
        let node = makeNode(nodeType: .array(itemCount: 0), parentType: .object)
        #expect(node.canDeleteField == true)
    }
}

// MARK: - Full Permutation Matrix Tests

@Suite("Context Menu Full Permutation Matrix")
struct ContextMenuFullPermutationTests {

    /// Test data for permutation matrix
    /// Format: (nodeType, parentType, canAddChild, canAddSibling, canDeleteField)
    /// Note: canDeleteField is false for array elements (use canDeleteArrayElement instead)
    static let permutationMatrix: [(JSONNodeType, ParentType, Bool, Bool, Bool)] = [
        // Object nodes
        (.object(keyCount: 0), .root, true, false, true),
        (.object(keyCount: 0), .object, true, true, true),
        (.object(keyCount: 0), .array, true, false, false),  // array element - use delete element

        // Array nodes
        (.array(itemCount: 0), .root, false, false, true),
        (.array(itemCount: 0), .object, false, true, true),
        (.array(itemCount: 0), .array, false, false, false),  // array element - use delete element

        // String (primitive) nodes
        (.string, .root, false, false, true),
        (.string, .object, false, true, true),
        (.string, .array, false, false, false),  // array element - use delete element

        // Int (primitive) nodes
        (.int, .root, false, false, true),
        (.int, .object, false, true, true),
        (.int, .array, false, false, false),  // array element - use delete element

        // Bool (primitive) nodes
        (.bool, .root, false, false, true),
        (.bool, .object, false, true, true),
        (.bool, .array, false, false, false),  // array element - use delete element

        // Null (primitive) nodes
        (.null, .root, false, false, true),
        (.null, .object, false, true, true),
        (.null, .array, false, false, false),  // array element - use delete element
    ]

    @Test("Full permutation matrix", arguments: permutationMatrix)
    func testPermutation(
        nodeType: JSONNodeType,
        parentType: ParentType,
        expectedCanAddChild: Bool,
        expectedCanAddSibling: Bool,
        expectedCanDelete: Bool
    ) {
        let node = FlattenedNode(
            id: "test",
            key: "testKey",
            value: "",
            path: ["test"],
            depth: 0,
            nodeType: nodeType,
            parentType: parentType,
            isExpanded: false,
            isCurrentMatch: false
        )

        #expect(
            node.canAddChildField == expectedCanAddChild,
            "canAddChildField for \(nodeType) in \(parentType) should be \(expectedCanAddChild)"
        )
        #expect(
            node.canAddSiblingField == expectedCanAddSibling,
            "canAddSiblingField for \(nodeType) in \(parentType) should be \(expectedCanAddSibling)"
        )
        #expect(
            node.canDeleteField == expectedCanDelete,
            "canDeleteField for \(nodeType) in \(parentType) should be \(expectedCanDelete)"
        )
    }
}
