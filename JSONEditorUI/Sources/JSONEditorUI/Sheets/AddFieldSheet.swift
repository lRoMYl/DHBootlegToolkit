import SwiftUI

// MARK: - Add Field Sheet

/// Sheet for adding a new field to a JSON object
public struct AddFieldSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Path to the parent object where the field will be added
    let parentPath: [String]

    /// Callback when field is added (key, type label, value)
    let onAdd: (String, String, Any) -> Void

    @State private var fieldKey: String = ""
    @State private var fieldType: JSONSchemaType = .string
    @State private var stringValue: String = ""
    @State private var intValue: String = ""
    @State private var floatValue: String = ""
    @State private var boolValue: Bool = false

    /// Available types for new fields (JSON primitive types)
    private let availableTypes: [JSONSchemaType] = [.string, .int, .float, .bool, .object, .array]

    public init(parentPath: [String], onAdd: @escaping (String, String, Any) -> Void) {
        self.parentPath = parentPath
        self.onAdd = onAdd
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Add New Field")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Parent: \(parentPath.isEmpty ? "root" : parentPath.joined(separator: " › "))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // Field Key
            VStack(alignment: .leading, spacing: 8) {
                Text("Field Key")
                    .font(.headline)
                TextField("Enter field name", text: $fieldKey)
                    .textFieldStyle(.roundedBorder)
            }

            // Field Type Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Field Type")
                    .font(.headline)

                Picker("Type", selection: $fieldType) {
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
                Text("Initial Value")
                    .font(.headline)

                switch fieldType {
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

                Button("Add Field") {
                    addField()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(fieldKey.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 450)
    }

    private func addField() {
        let value: Any = switch fieldType {
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

        onAdd(fieldKey, fieldType.rawValue, value)
        dismiss()
    }
}

#Preview {
    AddFieldSheet(parentPath: ["features", "darkMode"]) { key, type, value in
        print("Added: \(key) (\(type)) = \(value)")
    }
}
