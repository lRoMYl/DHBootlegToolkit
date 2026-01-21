import SwiftUI

// MARK: - Insert Array Element Sheet

/// Sheet for inserting an element into a JSON array
public struct InsertArrayElementSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Path to the array
    let arrayPath: [String]

    /// Current array for context
    let currentArray: [Any]

    /// Callback when element is inserted (type label, value, index)
    let onInsert: (String, Any, Int?) -> Void

    @State private var elementType: JSONSchemaType = .string
    @State private var stringValue: String = ""
    @State private var intValue: String = ""
    @State private var floatValue: String = ""
    @State private var boolValue: Bool = false
    @State private var insertAtIndex: String = ""
    @State private var appendToEnd: Bool = true

    /// Available types for array elements
    private let availableTypes: [JSONSchemaType] = [.string, .int, .float, .bool, .object, .array]

    public init(arrayPath: [String], currentArray: [Any], onInsert: @escaping (String, Any, Int?) -> Void) {
        self.arrayPath = arrayPath
        self.currentArray = currentArray
        self.onInsert = onInsert
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Insert Array Element")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Array: \(arrayPath.joined(separator: " › ")) (\(currentArray.count) elements)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // Insert Position
            VStack(alignment: .leading, spacing: 8) {
                Text("Insert Position")
                    .font(.headline)

                Toggle("Append to end", isOn: $appendToEnd)

                if !appendToEnd {
                    HStack {
                        Text("Index:")
                        TextField("0 to \(currentArray.count)", text: $insertAtIndex)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("(0-based)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Element Type Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Element Type")
                    .font(.headline)

                Picker("Type", selection: $elementType) {
                    ForEach(availableTypes, id: \.self) { type in
                        HStack {
                            TypeBadge(type: type, isInferred: false)
                            Text(type.rawValue.capitalized)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            // Value Input (based on selected type)
            VStack(alignment: .leading, spacing: 8) {
                Text("Element Value")
                    .font(.headline)

                switch elementType {
                case .string, .stringArray:
                    TextField("Enter string value", text: $stringValue)
                        .textFieldStyle(.roundedBorder)

                case .int, .intArray:
                    TextField("Enter integer value", text: $intValue)
                        .textFieldStyle(.roundedBorder)

                case .float:
                    TextField("Enter float value", text: $floatValue)
                        .textFieldStyle(.roundedBorder)

                case .bool:
                    Toggle("Value", isOn: $boolValue)

                case .object:
                    Text("Empty object {}")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                case .array:
                    Text("Empty array []")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                case .null, .any:
                    Text("null")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Action Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Insert") {
                    insertElement()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 450)
    }

    private func insertElement() {
        let value: Any = switch elementType {
        case .string, .stringArray:
            stringValue
        case .int, .intArray:
            Int(intValue) ?? 0
        case .float:
            Double(floatValue) ?? 0.0
        case .bool:
            boolValue
        case .object:
            [String: Any]()
        case .array:
            [Any]()
        case .null, .any:
            NSNull()
        }

        let index: Int? = if appendToEnd {
            nil
        } else if let idx = Int(insertAtIndex), idx >= 0, idx <= currentArray.count {
            idx
        } else {
            nil
        }

        onInsert(elementType.rawValue, value, index)
        dismiss()
    }
}

#Preview {
    InsertArrayElementSheet(
        arrayPath: ["features", "enabledCountries"],
        currentArray: ["US", "UK", "FR"]
    ) { type, value, index in
        print("Inserted: \(value) (\(type)) at index \(index?.description ?? "end")")
    }
}
