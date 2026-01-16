import SwiftUI
import DHBootlegToolkitCore

// MARK: - Country Field Value Model

/// Tracks the value to apply for a specific country with per-country customization
struct CountryFieldValue: Identifiable {
    let id: String  // Country ID
    let countryConfig: S3CountryConfig
    let currentValue: Any?  // Existing value at path (nil if field doesn't exist)
    var newValue: Any       // Value to apply (can be modified per-country)
    let isNewField: Bool    // True if field doesn't exist in target
}

// MARK: - S3 Apply Field Sheet

/// Simplified wizard for applying a field to multiple countries
/// Two-step flow: 1) Select target countries, 2) Preview changes and apply
struct S3ApplyFieldSheet: View {
    @Environment(S3Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var step: WizardStep = .selectCountries
    @State private var selectedCountries: Set<String> = []
    @State private var targetEnvironment: S3Environment = .staging
    @State private var availableCountriesForEnvironment: [S3CountryConfig] = []
    @State private var isApplying: Bool = false
    @State private var countryFieldValues: [CountryFieldValue] = []
    @State private var sourceTreeViewModel = JSONTreeViewModel()

    enum WizardStep {
        case selectCountries
        case previewChanges
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
        .frame(width: 700, height: 650)
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
            Text("Apply Field to Multiple Countries")
                .font(.headline)

            Spacer()

            Button {
                dismiss()
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
            // Field path
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

            // Source value using JSON tree
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
        .onAppear {
            configureSourceTreeViewModel()
        }
    }

    /// Configure the source value tree view model
    private func configureSourceTreeViewModel() {
        guard let value = store.selectedNodeValue,
              let fieldPath = store.selectedNodePath else { return }

        let pathComponents = fieldPath.split(separator: ".").map(String.init)
        let fieldKey = pathComponents.last ?? "value"
        let json = [fieldKey: value]
        sourceTreeViewModel.configure(json: json, expandAllByDefault: false)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch step {
        case .selectCountries:
            countrySelectionView
        case .previewChanges:
            changesPreviewView
        }
    }

    // MARK: - Country Selection

    private var countrySelectionView: some View {
        S3CountrySelectionView(
            title: "Target Countries",
            selectedCountries: $selectedCountries,
            targetEnvironment: $targetEnvironment,
            availableCountries: availableCountries,
            onEnvironmentChange: handleEnvironmentChange
        )
    }

    /// Countries available for selection (excludes current source country)
    private var availableCountries: [S3CountryConfig] {
        // Use environment-specific countries, excluding source country if from same environment
        if targetEnvironment == store.selectedEnvironment {
            return availableCountriesForEnvironment.filter { $0.id != store.selectedCountry?.id }
        } else {
            return availableCountriesForEnvironment
        }
    }

    // MARK: - Changes Preview

    private var changesPreviewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    step = .selectCountries
                    countryFieldValues = []  // Clear when going back
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
                Text("Changes Preview")
                    .font(.subheadline.bold())

                Spacer()

                Text("\(countryFieldValues.count) countries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Text("Double-click values to edit them individually per country")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach($countryFieldValues) { $fieldValue in
                        CountryFieldPreviewCard(
                            fieldValue: $fieldValue,
                            fieldPath: store.selectedNodePath ?? ""
                        )
                    }
                }
                .padding()
            }
        }
        .onAppear {
            initializeCountryFieldValues()
        }
    }

    private var selectedCountriesArray: [S3CountryConfig] {
        availableCountriesForEnvironment.filter { selectedCountries.contains($0.id) }
    }

    /// Initialize per-country values when entering preview step
    private func initializeCountryFieldValues() {
        guard countryFieldValues.isEmpty,
              let newValue = store.selectedNodeValue,
              let fieldPath = store.selectedNodePath else { return }

        let pathComponents = fieldPath.split(separator: ".").map(String.init)

        countryFieldValues = selectedCountriesArray.map { country in
            let currentValue = getValue(at: pathComponents, from: country.parseConfigJSON() ?? [:])
            return CountryFieldValue(
                id: country.id,
                countryConfig: country,
                currentValue: currentValue,
                newValue: newValue,  // Start with source value
                isNewField: currentValue == nil
            )
        }
    }

    /// Navigate JSON to get value at path
    private func getValue(at path: [String], from json: [String: Any]) -> Any? {
        guard !path.isEmpty else { return json }

        if path.count == 1 {
            return json[path[0]]
        }

        let key = path[0]
        let remainingPath = Array(path.dropFirst())

        if let nested = json[key] as? [String: Any] {
            return getValue(at: remainingPath, from: nested)
        }

        return nil
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            if step == .selectCountries {
                Button("Preview Changes") {
                    step = .previewChanges
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCountries.isEmpty)
            } else {
                Button {
                    applyChanges()
                } label: {
                    if isApplying {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Apply Changes")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCountries.isEmpty || isApplying)
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func applyChanges() {
        isApplying = true
        Task {
            do {
                // Apply to each country in the target environment
                try await applyFieldToCountriesInEnvironment()

                // Refresh main store if we saved to current environment
                if targetEnvironment == store.selectedEnvironment {
                    await store.loadCountries()
                    await store.updateGitStatuses()
                }

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isApplying = false
                    // Could show error alert
                }
            }
        }
    }

    private func applyFieldToCountriesInEnvironment() async throws {
        guard let fieldPath = store.selectedNodePath else {
            throw S3StoreError.invalidWizardState
        }

        let pathComponents = fieldPath.split(separator: ".").map(String.init)

        for fieldValue in countryFieldValues {
            guard let country = availableCountriesForEnvironment.first(where: { $0.id == fieldValue.id }) else {
                continue
            }

            if let updated = country.withUpdatedValue(fieldValue.newValue, at: pathComponents) {
                guard let data = updated.configData else { continue }
                try data.write(to: updated.configURL, options: .atomic)
            }
        }
    }

    private func handleEnvironmentChange(_ newEnvironment: S3Environment) async {
        targetEnvironment = newEnvironment

        // Clear selections when switching environment
        selectedCountries.removeAll()
        countryFieldValues = []

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

// MARK: - Country Field Preview Card

/// Card showing the field preview for a single country with JSON tree display and editing
struct CountryFieldPreviewCard: View {
    @Binding var fieldValue: CountryFieldValue
    let fieldPath: String

    @State private var originalTreeViewModel = JSONTreeViewModel()
    @State private var newTreeViewModel = JSONTreeViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Country header with badge
            countryHeaderView

            // Original value section (if exists) - read-only
            if let currentValue = fieldValue.currentValue {
                originalValueSection(currentValue)
            }

            // New value section - editable
            newValueSection
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            configureTreeViewModels()
        }
    }

    // MARK: - Country Header

    private var countryHeaderView: some View {
        HStack {
            Text(fieldValue.countryConfig.countryName)
                .font(.subheadline.bold())

            Text("(\(fieldValue.countryConfig.countryCode.uppercased()))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            diffTypeBadge
        }
    }

    private var diffTypeBadge: some View {
        let (text, color) = fieldValue.isNewField ? ("NEW", Color.blue) : ("UPDATE", Color.orange)
        return Text(text)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .cornerRadius(4)
    }

    // MARK: - Original Value Section

    private func originalValueSection(_ value: Any) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Current Value:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Show original value using tree view (read-only, same design as new value)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(originalTreeViewModel.flattenedNodes) { node in
                    JSONNodeRowView(
                        node: node,
                        onToggleExpand: { originalTreeViewModel.toggleExpand(node.id) },
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

    // MARK: - New Value Section

    private var newValueSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("New Value:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("(editable)")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }

            // Show new value using tree view (editable)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(newTreeViewModel.flattenedNodes) { node in
                    JSONNodeRowView(
                        node: node,
                        onToggleExpand: { newTreeViewModel.toggleExpand(node.id) },
                        onValueChange: { path, newValue in
                            updateNewValue(at: path, with: newValue)
                        }
                    )
                }
            }
            .padding(8)
            .background(Color.green.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(4)
        }
    }

    // MARK: - Tree Configuration

    private func configureTreeViewModels() {
        // Get the field key from the path
        let pathComponents = fieldPath.split(separator: ".").map(String.init)
        let fieldKey = pathComponents.last ?? "value"

        // Configure original value tree (if exists)
        if let currentValue = fieldValue.currentValue {
            let originalJSON = wrapValueAsJSON(currentValue, key: fieldKey)
            originalTreeViewModel.configure(json: originalJSON, expandAllByDefault: true)
        }

        // Configure new value tree
        let newJSON = wrapValueAsJSON(fieldValue.newValue, key: fieldKey)
        newTreeViewModel.configure(json: newJSON, expandAllByDefault: true)
    }

    /// Wrap a value in a JSON dictionary for tree display
    private func wrapValueAsJSON(_ value: Any, key: String) -> [String: Any] {
        return [key: value]
    }

    /// Update the newValue when user edits in the tree
    private func updateNewValue(at path: [String], with newValue: Any) {
        // The path starts with the field key, so we need to update the actual value
        if path.count == 1 {
            // Direct value update (primitive or replacing entire object)
            fieldValue.newValue = newValue
        } else {
            // Nested update - need to update within the structure
            fieldValue.newValue = updateValueAtPath(
                in: fieldValue.newValue,
                path: Array(path.dropFirst()),  // Remove the wrapper key
                newValue: newValue
            )
        }

        // Reconfigure tree to reflect changes
        let pathComponents = fieldPath.split(separator: ".").map(String.init)
        let fieldKey = pathComponents.last ?? "value"
        let newJSON = wrapValueAsJSON(fieldValue.newValue, key: fieldKey)
        newTreeViewModel.configure(json: newJSON, expandAllByDefault: true)
    }

    /// Recursively update a value at a given path
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
}

#Preview {
    S3ApplyFieldSheet()
        .environment(S3Store())
}
