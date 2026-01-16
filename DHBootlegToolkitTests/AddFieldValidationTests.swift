import Testing
@testable import DHBootlegToolkit

// MARK: - Add Field Validation Tests

@Suite("Add Field Validation Tests")
struct AddFieldValidationTests {

    // MARK: - Key Validation

    @Test("Empty key is invalid")
    func emptyKeyInvalid() {
        let result = AddFieldSheet.isValidField(
            key: "",
            type: .string,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(!result)
    }

    @Test("Key with dot is invalid")
    func keyWithDotInvalid() {
        let result = AddFieldSheet.isValidField(
            key: "invalid.key",
            type: .string,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(!result)
    }

    @Test("Valid key is accepted")
    func validKeyAccepted() {
        let result = AddFieldSheet.isValidField(
            key: "validKey",
            type: .string,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    // MARK: - String Type Tests

    @Test("String type - nullable OFF, empty value - valid")
    func stringNonNullableEmpty() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .string,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    @Test("String type - nullable OFF, with value - valid")
    func stringNonNullableValue() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .string,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    @Test("String type - nullable ON - valid")
    func stringNullable() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .string,
            isNullable: true,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    // MARK: - Int Type Tests

    @Test("Int type - nullable OFF, empty value - invalid")
    func intNonNullableEmpty() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .int,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(!result)
    }

    @Test("Int type - nullable OFF, invalid value - invalid")
    func intNonNullableInvalid() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .int,
            isNullable: false,
            intValue: "abc",
            floatValue: ""
        )
        #expect(!result)
    }

    @Test("Int type - nullable OFF, valid value - valid")
    func intNonNullableValid() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .int,
            isNullable: false,
            intValue: "42",
            floatValue: ""
        )
        #expect(result)
    }

    @Test("Int type - nullable OFF, negative value - valid")
    func intNonNullableNegative() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .int,
            isNullable: false,
            intValue: "-5",
            floatValue: ""
        )
        #expect(result)
    }

    @Test("Int type - nullable ON - valid")
    func intNullable() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .int,
            isNullable: true,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    // MARK: - Float Type Tests

    @Test("Float type - nullable OFF, empty value - invalid")
    func floatNonNullableEmpty() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .float,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(!result)
    }

    @Test("Float type - nullable OFF, invalid value - invalid")
    func floatNonNullableInvalid() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .float,
            isNullable: false,
            intValue: "",
            floatValue: "abc"
        )
        #expect(!result)
    }

    @Test("Float type - nullable OFF, valid value - valid")
    func floatNonNullableValid() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .float,
            isNullable: false,
            intValue: "",
            floatValue: "3.14"
        )
        #expect(result)
    }

    @Test("Float type - nullable OFF, integer value - valid")
    func floatNonNullableInteger() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .float,
            isNullable: false,
            intValue: "",
            floatValue: "42"
        )
        #expect(result)
    }

    @Test("Float type - nullable ON - valid")
    func floatNullable() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .float,
            isNullable: true,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    // MARK: - Bool Type Tests

    @Test("Bool type - nullable OFF - valid")
    func boolNonNullable() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .bool,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    @Test("Bool type - nullable ON - valid")
    func boolNullable() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .bool,
            isNullable: true,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    // MARK: - Object Type Tests

    @Test("Object type - nullable OFF - valid")
    func objectNonNullable() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .object,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    @Test("Object type - nullable ON - valid")
    func objectNullable() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .object,
            isNullable: true,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    // MARK: - Array Type Tests

    @Test("Array type - nullable OFF - valid")
    func arrayNonNullable() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .array,
            isNullable: false,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }

    @Test("Array type - nullable ON - valid")
    func arrayNullable() {
        let result = AddFieldSheet.isValidField(
            key: "key",
            type: .array,
            isNullable: true,
            intValue: "",
            floatValue: ""
        )
        #expect(result)
    }
}
