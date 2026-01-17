import SwiftUI

// MARK: - Add Field Sheet

/// Sheet for adding a new field to the JSON configuration
struct AddFieldSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(S3Store.self) private var store

    /// Path to the parent object where the field will be added
    let parentPath: [String]

    @State private var fieldKey: String = ""
    @State private var fieldType: JSONSchemaType = .string
    @State private var stringValue: String = ""
    @State private var intValue: String = ""
    @State private var floatValue: String = ""
    @State private var boolValue: Bool = false
    @State private var isNullable: Bool = false

    /// Available types for new fields (JSON primitive types)
    private let availableTypes: [JSONSchemaType] = [.string, .int, .float, .bool, .object, .array]

    /// Display name for the parent path
    private var parentPathDisplay: String {
        parentPath.isEmpty ? "(root)" : parentPath.joined(separator: ".")
    }

    /// Whether the form is valid
    private var isValid: Bool {
        Self.isValidField(
            key: fieldKey,
            type: fieldType,
            isNullable: isNullable,
            intValue: intValue,
            floatValue: floatValue
        )
    }

    /// Validates field creation parameters (extracted for testability)
    static func isValidField(
        key: String,
        type: JSONSchemaType,
        isNullable: Bool,
        intValue: String,
        floatValue: String
    ) -> Bool {
        guard !key.isEmpty else { return false }
        guard !key.contains(".") else { return false }

        // Skip value validation if nullable
        if isNullable { return true }

        switch type {
        case .int:
            return Int(intValue) != nil
        case .float:
            return Double(floatValue) != nil
        default:
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add New Field")
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
                    LabeledContent("Parent Path") {
                        Text(parentPathDisplay)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Field") {
                    TextField("Key Name", text: $fieldKey)
                        .textFieldStyle(.roundedBorder)

                    ScrollView(.horizontal, showsIndicators: false) {
                        Picker("Type", selection: $fieldType) {
                            ForEach(availableTypes, id: \.self) { type in
                                Text(type.label).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Value") {
                    Toggle("Nullable", isOn: $isNullable)

                    if !isNullable {
                        valueEditor
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Add Field") {
                    addField()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 450, height: 420)
        .onAppear {
            // Safety dismissal: don't allow adding fields on protected branches
            if store.isOnProtectedBranch { dismiss() }
        }
    }

    // MARK: - Value Editor

    @ViewBuilder
    private var valueEditor: some View {
        switch fieldType {
        case .string:
            TextField("Value", text: $stringValue)
                .textFieldStyle(.roundedBorder)

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

        default:
            EmptyView()
        }
    }

    // MARK: - Actions

    private func addField() {
        let value: Any

        // If nullable is enabled, create null value regardless of type
        if isNullable {
            value = NSNull()
        } else {
            switch fieldType {
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
            default:
                value = ""
            }
        }

        store.addField(at: parentPath, key: fieldKey, value: value)
        dismiss()
    }
}

#Preview {
    AddFieldSheet(parentPath: ["features", "darkMode"])
        .environment(S3Store())
}
