import SwiftUI
import DHBootlegToolkitCore

// MARK: - Country Inspection Value Model

/// Tracks the field value and edit state for a specific country during inspection
struct CountryInspectionValue: Identifiable {
    let id: String
    let countryConfig: S3CountryConfig
    let fieldExists: Bool
    var currentValue: Any?
    var editedValue: Any?
    var isEditing: Bool = false

    var isDirty: Bool { editedValue != nil }
    var displayValue: Any? { editedValue ?? currentValue }
}

// MARK: - S3 Inspect Field Sheet

/// Inspect field values across multiple countries with optional editing
/// Two-step flow: 1) Select countries to inspect, 2) View/edit field values
struct S3InspectFieldSheet: View {
    @Environment(S3Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var step: WizardStep = .selectCountries
    @State private var selectedCountries: Set<String> = []
    @State private var targetEnvironment: S3Environment = .staging
    @State private var availableCountriesForEnvironment: [S3CountryConfig] = []
    @State private var inspectionValues: [CountryInspectionValue] = []
    @State private var sourceTreeViewModel = JSONTreeViewModel()

    enum WizardStep {
        case selectCountries
        case inspectValues
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            fieldInfoView

            Divider()

            contentView

            Divider()

            footerView
        }
        .frame(width: 800, height: 650)
        .onAppear {
            targetEnvironment = store.selectedEnvironment
            Task {
                await loadCountriesForEnvironment(targetEnvironment)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Inspect Field Across Countries")
                .font(.headline)
            Spacer()
            Button {
                handleDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Field Info

    private var fieldInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Field:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(store.selectedNodePath ?? "")
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.blue)
                Spacer()
                Text("Source Value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Source value tree
            if store.selectedNodeValue != nil {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sourceTreeViewModel.flattenedNodes) { node in
                        JSONNodeRowView(
                            node: node,
                            onToggleExpand: { sourceTreeViewModel.toggleExpand(node.id) },
                            onValueChange: { _, _ in },
                            isReadOnly: true
                        )
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .onAppear(perform: configureSourceTreeViewModel)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch step {
        case .selectCountries:
            countrySelectionView
        case .inspectValues:
            inspectionView
        }
    }

    // MARK: - Country Selection

    private var countrySelectionView: some View {
        S3CountrySelectionView(
            title: "Select Countries to Inspect",
            selectedCountries: $selectedCountries,
            targetEnvironment: $targetEnvironment,
            availableCountries: availableCountries,
            onEnvironmentChange: handleEnvironmentChange
        )
    }

    // MARK: - Inspection View

    private var inspectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    step = .selectCountries
                } label: {
                    Label("Back to Selection", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            HStack {
                Text("Field Values")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(inspectionValues.count) countries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Text("Compare field values across selected countries")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach($inspectionValues) { $inspectionValue in
                        CountryInspectionCard(
                            inspectionValue: $inspectionValue,
                            fieldPath: store.selectedNodePath ?? "",
                            onSave: saveFieldValue
                        )
                    }
                }
                .padding()
            }
        }
        .onAppear {
            if inspectionValues.isEmpty {
                initializeInspectionValues()
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Button("Cancel") {
                handleDismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            if step == .selectCountries {
                Button("Inspect") {
                    step = .inspectValues
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCountries.isEmpty)
            } else {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(hasUnsavedChanges)
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private var availableCountries: [S3CountryConfig] {
        // Use environment-specific countries, excluding source country if from same environment
        if targetEnvironment == store.selectedEnvironment {
            return availableCountriesForEnvironment.filter { $0.id != store.selectedCountry?.id }
        } else {
            return availableCountriesForEnvironment
        }
    }

    private var hasUnsavedChanges: Bool {
        inspectionValues.contains { $0.isDirty }
    }

    private func configureSourceTreeViewModel() {
        guard let value = store.selectedNodeValue,
              let fieldPath = store.selectedNodePath else { return }
        let pathComponents = fieldPath.split(separator: ".").map(String.init)
        let fieldKey = pathComponents.last ?? "value"
        let json = [fieldKey: value]
        sourceTreeViewModel.configure(json: json, expandAllByDefault: false)
    }

    private func initializeInspectionValues() {
        guard let fieldPath = store.selectedNodePath else { return }
        let pathComponents = fieldPath.split(separator: ".").map(String.init)

        inspectionValues = selectedCountries.compactMap { countryId in
            guard let country = store.countries.first(where: { $0.id == countryId }),
                  let json = country.parseConfigJSON() else { return nil }

            let currentValue = getValue(at: pathComponents, from: json)
            return CountryInspectionValue(
                id: country.id,
                countryConfig: country,
                fieldExists: currentValue != nil,
                currentValue: currentValue,
                editedValue: nil,
                isEditing: false
            )
        }
    }

    private func getValue(at path: [String], from json: [String: Any]) -> Any? {
        guard !path.isEmpty else { return json }
        if path.count == 1 { return json[path[0]] }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())
        if let nested = json[key] as? [String: Any] {
            return getValue(at: remainingPath, from: nested)
        }
        return nil
    }

    private func saveFieldValue(countryId: String, newValue: Any) async throws {
        guard let fieldPath = store.selectedNodePath else { return }
        let pathComponents = fieldPath.split(separator: ".").map(String.init)

        // Find country in environment-specific list
        guard let country = availableCountriesForEnvironment.first(where: { $0.id == countryId }) else {
            throw S3StoreError.valueNotFound
        }

        // Update using country's targeted replacement
        if let updated = country.withUpdatedValue(newValue, at: pathComponents) {
            guard let data = updated.configData else { return }
            try data.write(to: updated.configURL, options: .atomic)

            // Update in-memory state
            if let idx = availableCountriesForEnvironment.firstIndex(where: { $0.id == countryId }) {
                let newOriginalContent = String(data: data, encoding: .utf8)
                availableCountriesForEnvironment[idx] = S3CountryConfig(
                    countryCode: updated.countryCode,
                    configURL: updated.configURL,
                    configData: updated.configData,
                    originalContent: newOriginalContent,
                    hasChanges: false
                )
            }

            // Clear edited state in inspection values
            if let idx = inspectionValues.firstIndex(where: { $0.id == countryId }) {
                inspectionValues[idx].editedValue = nil
                inspectionValues[idx].isEditing = false
                inspectionValues[idx].currentValue = newValue
            }

            // Refresh main store if we saved to current environment
            if targetEnvironment == store.selectedEnvironment {
                await store.loadCountries()
                await store.updateGitStatuses()
            }
        }
    }

    private func handleDismiss() {
        if hasUnsavedChanges {
            // Could show confirmation dialog here
        }
        dismiss()
    }

    private func handleEnvironmentChange(_ newEnvironment: S3Environment) async {
        targetEnvironment = newEnvironment

        // Clear selections when switching environment
        selectedCountries.removeAll()
        inspectionValues = []

        // Load countries for new environment
        await loadCountriesForEnvironment(newEnvironment)
    }

    private func loadCountriesForEnvironment(_ environment: S3Environment) async {
        guard let repoURL = store.s3RepositoryURL,
              let featureConfigURL = store.featureConfigURL else {
            availableCountriesForEnvironment = []
            return
        }

        let envURL = featureConfigURL.appendingPathComponent(environment.folderName)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: envURL.path) else {
            availableCountriesForEnvironment = []
            return
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: envURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            var loadedCountries: [S3CountryConfig] = []

            for folderURL in contents {
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }

                let countryCode = folderURL.lastPathComponent
                let configFileURL = folderURL.appendingPathComponent("config.json")

                guard fileManager.fileExists(atPath: configFileURL.path) else {
                    continue
                }

                let configData = try? Data(contentsOf: configFileURL)
                let originalContent = try? String(contentsOf: configFileURL, encoding: .utf8)

                let config = S3CountryConfig(
                    countryCode: countryCode,
                    configURL: configFileURL,
                    configData: configData,
                    originalContent: originalContent,
                    hasChanges: false
                )

                loadedCountries.append(config)
            }

            availableCountriesForEnvironment = loadedCountries.sorted { $0.countryCode < $1.countryCode }
        } catch {
            availableCountriesForEnvironment = []
        }
    }
}

// MARK: - Country Inspection Card

struct CountryInspectionCard: View {
    @Binding var inspectionValue: CountryInspectionValue
    let fieldPath: String
    let onSave: @MainActor (String, Any) async throws -> Void

    @State private var treeViewModel = JSONTreeViewModel()
    @State private var isSaving: Bool = false
    @State private var saveError: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(inspectionValue.countryConfig.countryName)
                    .font(.subheadline.bold())
                Text("(\(inspectionValue.countryConfig.countryCode.uppercased()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                statusBadge
            }

            // Content
            if inspectionValue.fieldExists {
                fieldValueSection
            } else {
                missingFieldSection
            }

            // Error message
            if let error = saveError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(inspectionValue.isEditing ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onAppear {
            configureTreeViewModel()
        }
    }

    // MARK: - Sections

    private var statusBadge: some View {
        let (text, color) = inspectionValue.fieldExists ? ("EXISTS", Color.green) : ("MISSING", Color.orange)
        return Text(text)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .cornerRadius(4)
    }

    private var fieldValueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(inspectionValue.isEditing ? "Editing:" : "Value:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()

                if !inspectionValue.isEditing {
                    Button("Edit") {
                        inspectionValue.isEditing = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    HStack(spacing: 8) {
                        Button("Cancel") {
                            inspectionValue.editedValue = nil
                            inspectionValue.isEditing = false
                            saveError = nil
                            configureTreeViewModel()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button {
                            Task {
                                await handleSave()
                            }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Save")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!inspectionValue.isDirty || isSaving)
                    }
                }
            }

            // Tree view
            VStack(alignment: .leading, spacing: 0) {
                ForEach(treeViewModel.flattenedNodes) { node in
                    JSONNodeRowView(
                        node: node,
                        onToggleExpand: { treeViewModel.toggleExpand(node.id) },
                        onValueChange: { path, newValue in
                            updateEditedValue(at: path, with: newValue)
                        },
                        isReadOnly: !inspectionValue.isEditing
                    )
                }
            }
            .padding(8)
            .background(inspectionValue.isEditing ? Color.blue.opacity(0.05) : Color.secondary.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(inspectionValue.isEditing ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(4)
        }
    }

    private var missingFieldSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("Field does not exist in this country")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(4)
        }
    }

    // MARK: - Helpers

    private func configureTreeViewModel() {
        let pathComponents = fieldPath.split(separator: ".").map(String.init)
        let fieldKey = pathComponents.last ?? "value"

        if let displayValue = inspectionValue.displayValue {
            let json = [fieldKey: displayValue]
            treeViewModel.configure(json: json, expandAllByDefault: true)
        }
    }

    private func updateEditedValue(at path: [String], with newValue: Any) {
        // The path starts with the field key wrapper
        if path.count == 1 {
            inspectionValue.editedValue = newValue
        } else {
            // Nested update
            let baseValue = inspectionValue.displayValue ?? inspectionValue.currentValue
            inspectionValue.editedValue = updateValueAtPath(
                in: baseValue!,
                path: Array(path.dropFirst()),
                newValue: newValue
            )
        }

        // Reconfigure tree
        configureTreeViewModel()
    }

    private func updateValueAtPath(in value: Any, path: [String], newValue: Any) -> Any {
        guard !path.isEmpty else { return newValue }

        if var dict = value as? [String: Any] {
            let key = path[0]
            if path.count == 1 {
                dict[key] = newValue
            } else if let existingValue = dict[key] {
                dict[key] = updateValueAtPath(in: existingValue, path: Array(path.dropFirst()), newValue: newValue)
            }
            return dict
        } else if var array = value as? [Any], let index = Int(path[0]), index < array.count {
            if path.count == 1 {
                array[index] = newValue
            } else {
                array[index] = updateValueAtPath(in: array[index], path: Array(path.dropFirst()), newValue: newValue)
            }
            return array
        }

        return value
    }

    private func handleSave() async {
        guard inspectionValue.isDirty,
              let editedValue = inspectionValue.editedValue else { return }

        isSaving = true
        saveError = nil

        do {
            try await onSave(inspectionValue.id, editedValue)
            await MainActor.run {
                isSaving = false
            }
        } catch {
            await MainActor.run {
                isSaving = false
                saveError = "Save failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    S3InspectFieldSheet()
        .environment(S3Store())
}
