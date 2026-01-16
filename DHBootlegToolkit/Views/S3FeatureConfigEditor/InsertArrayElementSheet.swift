import SwiftUI

// MARK: - Insert Array Element Sheet

/// Sheet for inserting a new element into an array
/// Type is inferred from existing siblings - only value input is needed
struct InsertArrayElementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(S3Store.self) private var store

    /// Path to the array (not including index)
    let arrayPath: [String]

    /// Index at which to insert the element
    let insertIndex: Int

    /// Type inferred from sibling elements
    let inferredType: JSONSchemaType

    @State private var stringValue: String = ""
    @State private var intValue: String = ""
    @State private var floatValue: String = ""
    @State private var boolValue: Bool = false

    /// Display name for the array path
    private var arrayPathDisplay: String {
        arrayPath.isEmpty ? "(root)" : arrayPath.joined(separator: ".")
    }

    /// Whether the form is valid
    private var isValid: Bool {
        Self.isValidElement(
            type: inferredType,
            stringValue: stringValue,
            intValue: intValue,
            floatValue: floatValue
        )
    }

    /// Validates element value (extracted for testability)
    static func isValidElement(
        type: JSONSchemaType,
        stringValue: String,
        intValue: String,
        floatValue: String
    ) -> Bool {
        switch type {
        case .int:
            return Int(intValue) != nil
        case .float:
            return Double(floatValue) != nil
        case .string, .bool, .object, .array, .null:
            return true
        default:
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Insert Array Element")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section("Location") {
                    LabeledContent("Array") {
                        Text(arrayPathDisplay)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Insert at Index") {
                        Text("[\(insertIndex)]")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Element") {
                    LabeledContent("Type (inferred)") {
                        Text(inferredType.label)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.blue)
                    }

                    valueEditor
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Insert Element") {
                    insertElement()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 400, height: 320)
    }

    // MARK: - Value Editor

    @ViewBuilder
    private var valueEditor: some View {
        switch inferredType {
        case .string:
            TextField("Value", text: $stringValue)
                .textFieldStyle(.roundedBorder)
            Text("Empty string is valid")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .int:
            TextField("Value", text: $intValue)
                .textFieldStyle(.roundedBorder)
            if !intValue.isEmpty && Int(intValue) == nil {
                Text("Please enter a valid integer")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

        case .float:
            TextField("Value (e.g., 3.14)", text: $floatValue)
                .textFieldStyle(.roundedBorder)
            if !floatValue.isEmpty && Double(floatValue) == nil {
                Text("Please enter a valid decimal number")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

        case .bool:
            Toggle("Value", isOn: $boolValue)

        case .object:
            Text("An empty object { } will be created")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .array:
            Text("An empty array [ ] will be created")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .null:
            Text("A null value will be created")
                .font(.caption)
                .foregroundStyle(.secondary)

        default:
            Text("Value will be empty string")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func insertElement() {
        let value: Any

        switch inferredType {
        case .string:
            value = stringValue
        case .int:
            value = Int(intValue) ?? 0
        case .float:
            value = Double(floatValue) ?? 0.0
        case .bool:
            value = boolValue
        case .object:
            value = [String: Any]()
        case .array:
            value = [Any]()
        case .null:
            value = NSNull()
        default:
            value = ""
        }

        let fullPath = arrayPath + [String(insertIndex)]
        store.insertArrayElement(at: fullPath, value: value)
        dismiss()
    }
}

// MARK: - Helper to Infer Type from Array

extension InsertArrayElementSheet {
    /// Infers the element type from existing array elements
    /// Returns .string as default if array is empty or has mixed types
    static func inferType(from array: [Any]) -> JSONSchemaType {
        guard let first = array.first else {
            return .string // Default for empty arrays
        }
        return JSONSchemaType.infer(from: first)
    }
}

#Preview {
    InsertArrayElementSheet(
        arrayPath: ["tags"],
        insertIndex: 2,
        inferredType: .string
    )
    .environment(S3Store())
}
