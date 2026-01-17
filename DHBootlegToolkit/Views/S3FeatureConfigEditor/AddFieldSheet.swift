import SwiftUI
import DHBootlegToolkitCore

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
    @State private var selectedSchemaField: String? = nil

    /// Available types for new fields (JSON primitive types)
    private let availableTypes: [JSONSchemaType] = [.string, .int, .float, .bool, .object, .array]

    /// Schema-defined fields available at the parent path
    private var schemaFields: [(name: String, schema: JSONSchema)] {
        guard let schema = store.parsedSchema?.schema(at: parentPath),
              let properties = schema.properties else {
            return []
        }
        return properties.map { ($0.key, $0.value) }.sorted { $0.name < $1.name }
    }

    /// Whether additional properties are allowed at this path
    private var allowsAdditionalProperties: Bool {
        guard let schema = store.parsedSchema?.schema(at: parentPath) else {
            return true // No schema, allow anything
        }

        guard let additionalProps = schema.additionalProperties else {
            return true // Default JSON Schema behavior
        }

        switch additionalProps {
        case .boolean(let allowed):
            return allowed
        case .schema:
            return true
        }
    }

    /// Whether the current field is defined in schema
    private var isFieldInSchema: Bool {
        guard !fieldKey.isEmpty else { return false }
        return schemaFields.contains { $0.name == fieldKey }
    }

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

                // Schema suggestions section
                if !schemaFields.isEmpty {
                    Section {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(schemaFields, id: \.name) { field in
                                    Button {
                                        selectSchemaField(field.name, schema: field.schema)
                                    } label: {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack {
                                                    Text(field.name)
                                                        .font(.system(.body, design: .monospaced))
                                                        .foregroundStyle(.primary)

                                                    if let parentSchema = store.parsedSchema?.schema(at: parentPath),
                                                       parentSchema.required?.contains(field.name) == true {
                                                        Text("*")
                                                            .foregroundStyle(.red)
                                                            .font(.caption)
                                                    }

                                                    if field.schema.deprecated == true {
                                                        Text("deprecated")
                                                            .font(.caption2)
                                                            .foregroundStyle(.orange)
                                                            .padding(.horizontal, 4)
                                                            .padding(.vertical, 2)
                                                            .background(Color.orange.opacity(0.2))
                                                            .cornerRadius(4)
                                                    }
                                                }

                                                if let description = field.schema.description {
                                                    Text(description)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(2)
                                                }

                                                if let type = field.schema.type {
                                                    Text("Type: \(type.types.joined(separator: " | "))")
                                                        .font(.caption2)
                                                        .foregroundStyle(.tertiary)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.vertical, 4)

                                    if field.name != schemaFields.last?.name {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    } header: {
                        Text("Available Fields from Schema")
                    } footer: {
                        Text("Click a field to auto-fill its information")
                            .font(.caption2)
                    }
                }

                Section("Field") {
                    TextField("Key Name", text: $fieldKey)
                        .textFieldStyle(.roundedBorder)

                    // Warning if field not in schema and additionalProperties is false
                    if !fieldKey.isEmpty && !isFieldInSchema && !allowsAdditionalProperties {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("This field is not defined in the schema and additional properties are not allowed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

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

    private func selectSchemaField(_ name: String, schema: JSONSchema) {
        fieldKey = name
        selectedSchemaField = name

        // Auto-populate field type from schema
        if let schemaType = schema.type {
            let typeString = schemaType.types.first ?? "string"
            switch typeString {
            case "string":
                fieldType = .string
                if let defaultValue = schema.defaultValue {
                    if case .string(let str) = defaultValue {
                        stringValue = str
                    }
                }
            case "number":
                fieldType = .float
                if let defaultValue = schema.defaultValue {
                    if case .number(let num) = defaultValue {
                        floatValue = String(num)
                    }
                }
            case "integer":
                fieldType = .int
                if let defaultValue = schema.defaultValue {
                    if case .number(let num) = defaultValue {
                        intValue = String(Int(num))
                    }
                }
            case "boolean":
                fieldType = .bool
                if let defaultValue = schema.defaultValue {
                    if case .boolean(let bool) = defaultValue {
                        boolValue = bool
                    }
                }
            case "object":
                fieldType = .object
            case "array":
                fieldType = .array
            default:
                fieldType = .string
            }
        }
    }

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
