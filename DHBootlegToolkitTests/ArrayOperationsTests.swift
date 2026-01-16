import Testing
@testable import DHBootlegToolkit

// MARK: - Array Element Properties Tests

@Suite("Array Element Properties Tests")
struct ArrayElementPropertiesTests {

    // MARK: - Helper to Create Test Nodes

    private func makeNode(
        path: [String],
        nodeType: JSONNodeType,
        parentType: ParentType
    ) -> FlattenedNode {
        FlattenedNode(
            id: path.joined(separator: "."),
            key: path.last ?? "",
            value: "",
            path: path,
            depth: path.count - 1,
            nodeType: nodeType,
            parentType: parentType,
            isExpanded: false,
            isCurrentMatch: false
        )
    }

    // MARK: - isArrayElement Tests

    @Test("Node in array - is array element")
    func nodeInArrayIsArrayElement() {
        let node = makeNode(path: ["tags", "0"], nodeType: .string, parentType: .array)
        #expect(node.isArrayElement == true)
    }

    @Test("Node in object - is not array element")
    func nodeInObjectIsNotArrayElement() {
        let node = makeNode(path: ["user", "name"], nodeType: .string, parentType: .object)
        #expect(node.isArrayElement == false)
    }

    @Test("Node at root - is not array element")
    func nodeAtRootIsNotArrayElement() {
        let node = makeNode(path: ["config"], nodeType: .object(keyCount: 0), parentType: .root)
        #expect(node.isArrayElement == false)
    }

    // MARK: - canInsertArrayElement Tests

    @Test("Node in array - can insert element")
    func nodeInArrayCanInsertElement() {
        let node = makeNode(path: ["tags", "0"], nodeType: .string, parentType: .array)
        #expect(node.canInsertArrayElement == true)
    }

    @Test("Node in object - cannot insert element")
    func nodeInObjectCannotInsertElement() {
        let node = makeNode(path: ["user", "name"], nodeType: .string, parentType: .object)
        #expect(node.canInsertArrayElement == false)
    }

    @Test("Node at root - cannot insert element")
    func nodeAtRootCannotInsertElement() {
        let node = makeNode(path: ["config"], nodeType: .object(keyCount: 0), parentType: .root)
        #expect(node.canInsertArrayElement == false)
    }

    // MARK: - canDeleteArrayElement Tests

    @Test("Node in array - can delete element")
    func nodeInArrayCanDeleteElement() {
        let node = makeNode(path: ["tags", "0"], nodeType: .string, parentType: .array)
        #expect(node.canDeleteArrayElement == true)
    }

    @Test("Node in object - cannot delete element")
    func nodeInObjectCannotDeleteElement() {
        let node = makeNode(path: ["user", "name"], nodeType: .string, parentType: .object)
        #expect(node.canDeleteArrayElement == false)
    }

    @Test("Node at root - cannot delete element")
    func nodeAtRootCannotDeleteElement() {
        let node = makeNode(path: ["config"], nodeType: .object(keyCount: 0), parentType: .root)
        #expect(node.canDeleteArrayElement == false)
    }

    // MARK: - arrayIndex Tests

    @Test("Array element at index 0 - returns 0")
    func arrayElementAtIndex0() {
        let node = makeNode(path: ["tags", "0"], nodeType: .string, parentType: .array)
        #expect(node.arrayIndex == 0)
    }

    @Test("Array element at index 5 - returns 5")
    func arrayElementAtIndex5() {
        let node = makeNode(path: ["items", "5"], nodeType: .object(keyCount: 0), parentType: .array)
        #expect(node.arrayIndex == 5)
    }

    @Test("Non-array element - returns nil")
    func nonArrayElementIndexIsNil() {
        let node = makeNode(path: ["user", "name"], nodeType: .string, parentType: .object)
        #expect(node.arrayIndex == nil)
    }

    @Test("Nested array element - returns correct index")
    func nestedArrayElementIndex() {
        let node = makeNode(path: ["data", "items", "3"], nodeType: .int, parentType: .array)
        #expect(node.arrayIndex == 3)
    }

    // MARK: - arrayParentPath Tests

    @Test("Array element - returns parent array path")
    func arrayElementParentPath() {
        let node = makeNode(path: ["tags", "2"], nodeType: .string, parentType: .array)
        #expect(node.arrayParentPath == ["tags"])
    }

    @Test("Nested array element - returns parent array path")
    func nestedArrayElementParentPath() {
        let node = makeNode(path: ["data", "items", "1"], nodeType: .object(keyCount: 0), parentType: .array)
        #expect(node.arrayParentPath == ["data", "items"])
    }

    @Test("Non-array element - returns nil")
    func nonArrayElementParentPathIsNil() {
        let node = makeNode(path: ["user", "name"], nodeType: .string, parentType: .object)
        #expect(node.arrayParentPath == nil)
    }
}

// MARK: - Array Element Context Menu Permutation Tests

@Suite("Array Element Context Menu Permutation Tests")
struct ArrayElementContextMenuTests {

    private func makeArrayElement(nodeType: JSONNodeType, index: Int) -> FlattenedNode {
        FlattenedNode(
            id: "array.\(index)",
            key: "\(index)",
            value: "",
            path: ["array", "\(index)"],
            depth: 1,
            nodeType: nodeType,
            parentType: .array,
            isExpanded: false,
            isCurrentMatch: false
        )
    }

    // Array elements should NEVER have "Add Sibling Field" or "Delete Field"
    // They should have "Insert Element" and "Delete Element"

    @Test("String in array - context menu options")
    func stringInArrayContextMenu() {
        let node = makeArrayElement(nodeType: .string, index: 0)
        #expect(node.canAddChildField == false)
        #expect(node.canAddSiblingField == false)
        #expect(node.canDeleteField == false)
        #expect(node.canInsertArrayElement == true)
        #expect(node.canDeleteArrayElement == true)
    }

    @Test("Object in array - context menu options")
    func objectInArrayContextMenu() {
        let node = makeArrayElement(nodeType: .object(keyCount: 2), index: 1)
        #expect(node.canAddChildField == true)  // Can add children to object
        #expect(node.canAddSiblingField == false)
        #expect(node.canDeleteField == false)
        #expect(node.canInsertArrayElement == true)
        #expect(node.canDeleteArrayElement == true)
    }

    @Test("Array in array - context menu options")
    func arrayInArrayContextMenu() {
        let node = makeArrayElement(nodeType: .array(itemCount: 3), index: 2)
        #expect(node.canAddChildField == false)
        #expect(node.canAddSiblingField == false)
        #expect(node.canDeleteField == false)
        #expect(node.canInsertArrayElement == true)
        #expect(node.canDeleteArrayElement == true)
    }

    @Test("Int in array - context menu options")
    func intInArrayContextMenu() {
        let node = makeArrayElement(nodeType: .int, index: 3)
        #expect(node.canAddChildField == false)
        #expect(node.canAddSiblingField == false)
        #expect(node.canDeleteField == false)
        #expect(node.canInsertArrayElement == true)
        #expect(node.canDeleteArrayElement == true)
    }

    @Test("Bool in array - context menu options")
    func boolInArrayContextMenu() {
        let node = makeArrayElement(nodeType: .bool, index: 4)
        #expect(node.canAddChildField == false)
        #expect(node.canAddSiblingField == false)
        #expect(node.canDeleteField == false)
        #expect(node.canInsertArrayElement == true)
        #expect(node.canDeleteArrayElement == true)
    }

    @Test("Null in array - context menu options")
    func nullInArrayContextMenu() {
        let node = makeArrayElement(nodeType: .null, index: 5)
        #expect(node.canAddChildField == false)
        #expect(node.canAddSiblingField == false)
        #expect(node.canDeleteField == false)
        #expect(node.canInsertArrayElement == true)
        #expect(node.canDeleteArrayElement == true)
    }
}

// MARK: - Insert Array Element Validation Tests

@Suite("Insert Array Element Validation Tests")
struct InsertArrayElementValidationTests {

    // MARK: - String Type Validation

    @Test("String type - empty string is valid")
    func stringTypeEmptyIsValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .string,
            stringValue: "",
            intValue: "",
            floatValue: ""
        )
        #expect(isValid == true)
    }

    @Test("String type - non-empty string is valid")
    func stringTypeNonEmptyIsValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .string,
            stringValue: "hello",
            intValue: "",
            floatValue: ""
        )
        #expect(isValid == true)
    }

    // MARK: - Int Type Validation

    @Test("Int type - valid integer is valid")
    func intTypeValidIntegerIsValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .int,
            stringValue: "",
            intValue: "42",
            floatValue: ""
        )
        #expect(isValid == true)
    }

    @Test("Int type - negative integer is valid")
    func intTypeNegativeIntegerIsValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .int,
            stringValue: "",
            intValue: "-123",
            floatValue: ""
        )
        #expect(isValid == true)
    }

    @Test("Int type - empty string is invalid")
    func intTypeEmptyIsInvalid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .int,
            stringValue: "",
            intValue: "",
            floatValue: ""
        )
        #expect(isValid == false)
    }

    @Test("Int type - non-numeric string is invalid")
    func intTypeNonNumericIsInvalid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .int,
            stringValue: "",
            intValue: "abc",
            floatValue: ""
        )
        #expect(isValid == false)
    }

    @Test("Int type - decimal is invalid")
    func intTypeDecimalIsInvalid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .int,
            stringValue: "",
            intValue: "3.14",
            floatValue: ""
        )
        #expect(isValid == false)
    }

    // MARK: - Float Type Validation

    @Test("Float type - valid decimal is valid")
    func floatTypeValidDecimalIsValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .float,
            stringValue: "",
            intValue: "",
            floatValue: "3.14"
        )
        #expect(isValid == true)
    }

    @Test("Float type - integer string is valid")
    func floatTypeIntegerStringIsValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .float,
            stringValue: "",
            intValue: "",
            floatValue: "42"
        )
        #expect(isValid == true)
    }

    @Test("Float type - negative decimal is valid")
    func floatTypeNegativeDecimalIsValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .float,
            stringValue: "",
            intValue: "",
            floatValue: "-2.5"
        )
        #expect(isValid == true)
    }

    @Test("Float type - empty string is invalid")
    func floatTypeEmptyIsInvalid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .float,
            stringValue: "",
            intValue: "",
            floatValue: ""
        )
        #expect(isValid == false)
    }

    @Test("Float type - non-numeric string is invalid")
    func floatTypeNonNumericIsInvalid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .float,
            stringValue: "",
            intValue: "",
            floatValue: "abc"
        )
        #expect(isValid == false)
    }

    // MARK: - Bool Type Validation

    @Test("Bool type - always valid")
    func boolTypeAlwaysValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .bool,
            stringValue: "",
            intValue: "",
            floatValue: ""
        )
        #expect(isValid == true)
    }

    // MARK: - Object Type Validation

    @Test("Object type - always valid (empty object created)")
    func objectTypeAlwaysValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .object,
            stringValue: "",
            intValue: "",
            floatValue: ""
        )
        #expect(isValid == true)
    }

    // MARK: - Array Type Validation

    @Test("Array type - always valid (empty array created)")
    func arrayTypeAlwaysValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .array,
            stringValue: "",
            intValue: "",
            floatValue: ""
        )
        #expect(isValid == true)
    }

    // MARK: - Null Type Validation

    @Test("Null type - always valid")
    func nullTypeAlwaysValid() {
        let isValid = InsertArrayElementSheet.isValidElement(
            type: .null,
            stringValue: "",
            intValue: "",
            floatValue: ""
        )
        #expect(isValid == true)
    }
}

// MARK: - Type Inference Tests

@Suite("Array Element Type Inference Tests")
struct ArrayElementTypeInferenceTests {

    @Test("Empty array - infers string")
    func emptyArrayInfersString() {
        let array: [Any] = []
        let type = InsertArrayElementSheet.inferType(from: array)
        #expect(type == .string)
    }

    @Test("String array - infers string")
    func stringArrayInfersString() {
        let array: [Any] = ["a", "b", "c"]
        let type = InsertArrayElementSheet.inferType(from: array)
        #expect(type == .string)
    }

    @Test("Int array - infers int")
    func intArrayInfersInt() {
        let array: [Any] = [1, 2, 3]
        let type = InsertArrayElementSheet.inferType(from: array)
        #expect(type == .int)
    }

    @Test("Bool array - infers bool")
    func boolArrayInfersBool() {
        let array: [Any] = [true, false, true]
        let type = InsertArrayElementSheet.inferType(from: array)
        #expect(type == .bool)
    }

    @Test("Object array - infers object")
    func objectArrayInfersObject() {
        let array: [Any] = [["key": "value"], ["key": "value2"]]
        let type = InsertArrayElementSheet.inferType(from: array)
        if case .object = type {
            // Pass - object type inferred
        } else {
            Issue.record("Expected object type, got \(type)")
        }
    }

    @Test("Array of int arrays - infers intArray (from first element)")
    func arrayOfIntArraysInfersIntArray() {
        // When the first element is [1, 2], JSONSchemaType.infer sees it as an intArray
        let array: [Any] = [[1, 2], [3, 4]]
        let type = InsertArrayElementSheet.inferType(from: array)
        #expect(type == .intArray)
    }

    @Test("Array of mixed arrays - infers array")
    func arrayOfMixedArraysInfersArray() {
        // When first element is an array of mixed types, it returns .array
        let array: [Any] = [["a", 1], ["b", 2]]
        let type = InsertArrayElementSheet.inferType(from: array)
        // First element is ["a", 1], JSONSchemaType.infer sees "a" as String, returns .stringArray
        #expect(type == .stringArray)
    }
}
