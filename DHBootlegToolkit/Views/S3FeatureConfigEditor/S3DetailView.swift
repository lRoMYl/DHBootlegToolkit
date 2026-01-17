import SwiftUI
import DHBootlegToolkitCore

// MARK: - Add Field Context

/// Context for presenting the add field sheet
/// Using Identifiable forces SwiftUI to create a new sheet instance each time
struct AddFieldContext: Identifiable {
    let id = UUID()
    let parentPath: [String]
}

// MARK: - S3 Detail View

/// Detail view for editing a country's S3 configuration
/// Uses virtualized rendering with LazyVStack for performance
struct S3DetailView: View {
    @Environment(S3Store.self) private var store
    @State private var searchQuery: String = ""
    @State private var debouncedQuery: String = ""
    @State private var searchMatches: JSONSearchMatches = .empty
    @State private var debounceTask: Task<Void, Never>?

    // View model for virtualized tree rendering
    @State private var treeViewModel = JSONTreeViewModel()

    // Cached HEAD JSON for current country (for diff comparison)
    @State private var currentHeadJSON: [String: Any]?

    // Add field state - uses item binding to ensure fresh sheet on each presentation
    @State private var addFieldContext: AddFieldContext? = nil

    // Filter state - show only changed fields
    @State private var showChangedFieldsOnly: Bool = false

    // Delete field state
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteFieldPath: [String] = []

    // Read-only state for protected branches
    private var isReadOnly: Bool {
        store.isOnProtectedBranch
    }

    // Array element state
    @State private var showInsertArrayElementSheet: Bool = false
    @State private var insertArrayElementPath: [String] = []
    @State private var insertArrayElementType: JSONSchemaType = .string
    @State private var showDeleteArrayElementConfirmation: Bool = false
    @State private var deleteArrayElementPath: [String] = []

    // Validation state
    @State private var validationResult: JSONSchemaValidationResult?
    @State private var showValidationPanel: Bool = true
    @State private var validationDebounceTask: Task<Void, Never>?
    @State private var isValidating: Bool = false

    // Scroll proxy for navigation to errors
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        if store.isLoading {
            VStack {
                ProgressView()
                    .controlSize(.large)
                Text("Reloading configuration...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let country = store.selectedCountry {
            countryDetailView(country)
        } else {
            VStack {
                Spacer()
                    .frame(maxHeight: 80)

                ContentUnavailableView(
                    "Select a Country",
                    systemImage: "globe",
                    description: Text("Choose a country from the sidebar to view and edit its configuration")
                )

                Spacer()
            }
        }
    }

    // MARK: - Country Detail View

    @ViewBuilder
    private func countryDetailView(_ country: S3CountryConfig) -> some View {
        VStack(spacing: 0) {
            S3DetailHeader(
                country: country,
                isReadOnly: isReadOnly,
                validationResult: $validationResult,
                showValidationPanel: $showValidationPanel
            )

            // Deleted placeholder notice
            if country.isDeletedPlaceholder {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This config was deleted")
                            .font(.headline)
                        Text("Loading content from git...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Read-only banner for protected branches
            if store.isOnProtectedBranch {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text("Read-only on \(store.currentBranchDisplayName) branch")
                    Spacer()
                    Button("Create Branch to Edit") {
                        store.showCreateBranchPrompt = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.top, 8)
            }

            Divider()

            searchBarSection

            Divider()

            // Validation panel or loading indicator
            if isValidating {
                // Show loading state
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Validating configuration...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)
            } else if let result = validationResult, !result.errors.isEmpty, showValidationPanel {
                validationPanel(result: result)
            }

            treeContentSection(country)
        }
        .task(id: country.id) {
            // Use task(id:) instead of onChange - fires on both initial appearance AND when ID changes
            await AppLogger.shared.timedGroup("S3 Country Change: \(country.countryCode)") { ctx in
                await ctx.time("Handle country change") {
                    await handleCountryChange(country)
                }
            }
        }
        .onChange(of: country.configData) { _, _ in
            // Refresh tree view when country data changes (e.g., after discard or value edit)
            // This is the ONLY place that handles configData changes - no duplicates in treeContentSection
            Task { @MainActor in
                await AppLogger.shared.time("S3 ConfigData onChange") {
                    if let json = country.parseConfigJSON() {
                        // Debounce validation (300ms)
                        validationDebounceTask?.cancel()
                        validationDebounceTask = Task {
                            try? await Task.sleep(for: .milliseconds(300))
                            guard !Task.isCancelled else { return }
                            await MainActor.run {
                                Task {
                                    isValidating = true
                                    let validation = await store.validateCountry(country)
                                    validationResult = validation
                                    isValidating = false
                                }
                            }
                        }

                        treeViewModel.configure(
                            json: json,
                            expandAllByDefault: true,
                            manuallyCollapsed: treeViewModel.getManuallyCollapsed(),
                            originalJSON: currentHeadJSON,
                            fileGitStatus: country.gitStatus,
                            hasInMemoryChanges: country.hasChanges,
                            editedPaths: country.editedPaths,
                            showChangedFieldsOnly: showChangedFieldsOnly,
                            schema: store.parsedSchema,
                            validationResult: validationResult
                        )
                    }
                }
            }
        }
        .onChange(of: searchQuery) { _, newValue in
            handleSearchQueryChange(newValue)
        }
        .onChange(of: debouncedQuery) { _, query in
            handleDebouncedQueryChange(query, country: country)
        }
        .sheet(item: $addFieldContext) { context in
            AddFieldSheet(parentPath: context.parentPath)
        }
        .confirmationDialog(
            "Delete Field",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                store.deleteField(at: deleteFieldPath)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(deleteFieldPath.last ?? "")'? This action cannot be undone.")
        }
        .sheet(isPresented: $showInsertArrayElementSheet) {
            // Strip brackets to handle both "[0]" and "0" formats
            let indexString = insertArrayElementPath.last ?? "0"
            let stripped = indexString.replacingOccurrences(of: "[", with: "")
                                      .replacingOccurrences(of: "]", with: "")
            InsertArrayElementSheet(
                arrayPath: Array(insertArrayElementPath.dropLast()),
                insertIndex: Int(stripped) ?? 0,
                inferredType: insertArrayElementType
            )
        }
        .confirmationDialog(
            "Delete Element",
            isPresented: $showDeleteArrayElementConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                store.deleteArrayElement(at: deleteArrayElementPath)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete element [\(deleteArrayElementPath.last ?? "")]? This action cannot be undone.")
        }
        .sheet(isPresented: Binding(
            get: { store.showInspectFieldSheet },
            set: { store.showInspectFieldSheet = $0 }
        )) {
            S3InspectFieldSheet()
        }
        .sheet(isPresented: Binding(
            get: { store.showApplyFieldSheet },
            set: { store.showApplyFieldSheet = $0 }
        )) {
            S3ApplyFieldSheet()
        }
    }

    // MARK: - Search Bar Section

    private var searchBarSection: some View {
        HStack(spacing: 8) {
            S3SearchBar(
                searchQuery: $searchQuery,
                currentMatch: searchMatches.displayIndex,
                totalMatches: searchMatches.count,
                onNext: { searchMatches.next() },
                onPrevious: { searchMatches.previous() }
            )

            Divider()
                .frame(height: 20)

            Button {
                if treeViewModel.isAllExpanded {
                    treeViewModel.collapseAllExceptRoot()
                } else {
                    treeViewModel.expandAll()
                }
            } label: {
                Image(systemName: treeViewModel.isAllExpanded ? "chevron.down.square" : "chevron.right.square")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(treeViewModel.isAllExpanded ? "Collapse All" : "Expand All")

            Button {
                showChangedFieldsOnly.toggle()
                treeViewModel.setShowChangedFieldsOnly(showChangedFieldsOnly)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    if showChangedFieldsOnly {
                        let count = treeViewModel.countChangedFields()
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption2.weight(.medium).monospacedDigit())
                        }
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(showChangedFieldsOnly ? .blue : .primary)
            .background(showChangedFieldsOnly ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(4)
            .disabled(currentHeadJSON == nil || treeViewModel.countChangedFields() == 0)
            .help(showChangedFieldsOnly ? "Show All Fields" : "Show Changed Fields Only")
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Tree Content Section

    @ViewBuilder
    private func treeContentSection(_ country: S3CountryConfig) -> some View {
        if let json = country.parseConfigJSON() {
            if showChangedFieldsOnly && treeViewModel.flattenedNodes.isEmpty {
                ContentUnavailableView(
                    "No Changes",
                    systemImage: "checkmark.circle",
                    description: Text("All fields match the git HEAD version")
                )
            } else {
                S3TreeContentView(
                    treeViewModel: treeViewModel,
                    searchMatches: searchMatches,
                    isReadOnly: isReadOnly,
                    onToggleExpand: { nodeId in
                        treeViewModel.toggleExpand(nodeId)
                    },
                    onValueChange: { path, newValue in
                        store.updateValue(at: path, value: newValue)
                    },
                    onAddField: isReadOnly ? nil : { parentPath in
                        addFieldContext = AddFieldContext(parentPath: parentPath)
                    },
                    onDeleteField: isReadOnly ? nil : { path in
                        deleteFieldPath = path
                        showDeleteConfirmation = true
                    },
                    onInsertArrayElement: isReadOnly ? nil : { path in
                        insertArrayElementPath = path
                        // Infer type from sibling elements
                        let arrayPath = Array(path.dropLast())
                        if let array = getArrayValue(at: arrayPath, from: json) {
                            insertArrayElementType = InsertArrayElementSheet.inferType(from: array)
                        } else {
                            insertArrayElementType = .string
                        }
                        showInsertArrayElementSheet = true
                    },
                    onDeleteArrayElement: isReadOnly ? nil : { path in
                        deleteArrayElementPath = path
                        showDeleteArrayElementConfirmation = true
                    },
                    onMoveArrayElement: isReadOnly ? nil : { arrayPath, fromIndex, toIndex in
                        store.moveArrayElement(arrayPath: arrayPath, fromIndex: fromIndex, toIndex: toIndex)
                    },
                    pathsToExpand: pathsToExpand,
                    scrollProxy: $scrollProxy
                )
            // NOTE: Configuration is handled by parent-level task(id:) and onChange(of: configData)
            // No onAppear or onChange needed here - avoids race conditions from multiple config calls
            }
        } else {
            ContentUnavailableView(
                "No Configuration Data",
                systemImage: "doc.text",
                description: Text("Unable to parse configuration for \(country.countryName)")
            )
        }
    }

    // MARK: - Event Handlers

    private func handleCountryChange(_ country: S3CountryConfig) async {
        // Clear previous validation state immediately
        validationResult = nil
        isValidating = true
        showValidationPanel = true

        searchQuery = ""
        debouncedQuery = ""
        searchMatches = .empty
        showChangedFieldsOnly = false
        treeViewModel.reset()

        if let json = country.parseConfigJSON() {
            // Validate country configuration
            let validation = await store.validateCountry(country)
            validationResult = validation
            isValidating = false

            // Configure tree immediately for fast rendering (no diff badges yet)
            currentHeadJSON = nil
            treeViewModel.configure(
                json: json,
                expandAllByDefault: true,
                originalJSON: nil,
                fileGitStatus: country.gitStatus,
                hasInMemoryChanges: country.hasChanges,
                editedPaths: country.editedPaths,
                showChangedFieldsOnly: showChangedFieldsOnly,
                schema: store.parsedSchema,
                validationResult: validation
            )

            // Fetch HEAD JSON for diff badges (this may be slow but tree is already visible)
            let headJSON = await store.fetchHeadJSON(for: country)

            // Only update if still showing same country
            if store.selectedCountry?.id == country.id {
                currentHeadJSON = headJSON
                // Reconfigure with diff data to show change badges
                treeViewModel.configure(
                    json: json,
                    expandAllByDefault: true,
                    manuallyCollapsed: treeViewModel.getManuallyCollapsed(),
                    originalJSON: headJSON,
                    fileGitStatus: country.gitStatus,
                    hasInMemoryChanges: country.hasChanges,
                    editedPaths: country.editedPaths,
                    showChangedFieldsOnly: showChangedFieldsOnly,
                    schema: store.parsedSchema,
                    validationResult: validation
                )
            }
        } else {
            isValidating = false
        }
    }

    private func handleSearchQueryChange(_ newValue: String) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                debouncedQuery = newValue
            }
        }
    }

    private func handleDebouncedQueryChange(_ query: String, country: S3CountryConfig) {
        if let json = country.parseConfigJSON() {
            searchMatches = query.isEmpty ? .empty : JSONSearchMatches.build(from: json, query: query)
        }
    }

    // MARK: - Helpers

    private func pathsToExpand(for path: [String]?) -> Set<String> {
        guard let path = path else { return [] }
        var result = Set<String>()
        for i in 1..<path.count {
            result.insert(path.prefix(i).map { $0 }.joined(separator: "."))
        }
        return result
    }

    /// Navigates to and returns an array value at the given path
    private func getArrayValue(at path: [String], from json: [String: Any]) -> [Any]? {
        guard !path.isEmpty else { return nil }

        var current: Any = json

        for component in path {
            if let dict = current as? [String: Any] {
                guard let next = dict[component] else { return nil }
                current = next
            } else if let array = current as? [Any] {
                // Strip brackets to handle both "[0]" and "0" formats
                let stripped = component.replacingOccurrences(of: "[", with: "")
                                        .replacingOccurrences(of: "]", with: "")
                guard let index = Int(stripped), index < array.count else { return nil }
                current = array[index]
            } else {
                return nil
            }
        }

        return current as? [Any]
    }

    // MARK: - Validation Panel

    private func handleErrorTap(_ error: ValidationError) {
        guard let proxy = scrollProxy else { return }
        store.navigateToValidationError(
            error,
            treeViewModel: treeViewModel,
            scrollProxy: proxy
        )
    }

    @ViewBuilder
    private func validationPanel(result: JSONSchemaValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.errorCount > 0 ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    .foregroundStyle(result.errorCount > 0 ? .red : .orange)

                Text("\(result.errorCount) error\(result.errorCount == 1 ? "" : "s")\(result.warningCount > 0 ? ", \(result.warningCount) warning\(result.warningCount == 1 ? "" : "s")" : "")")
                    .font(.headline)

                Spacer()

                Button {
                    showValidationPanel = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(result.errors) { error in
                        ValidationErrorChip(error: error) {
                            handleErrorTap(error)
                        }
                    }
                }
            }
        }
        .padding()
        .background((result.errorCount > 0 ? Color.red : Color.orange).opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Validation Error Chip

struct ValidationErrorChip: View {
    let error: ValidationError
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: error.severity == .error ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(error.severity == .error ? .red : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(error.pathString)
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)

                    Text(error.message)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help("Click to navigate to this error")
    }
}

// MARK: - S3 Tree Content View

/// Extracted tree content view to help compiler with type checking
struct S3TreeContentView: View {
    @Environment(S3Store.self) private var store
    let treeViewModel: JSONTreeViewModel
    var searchMatches: JSONSearchMatches
    var isReadOnly: Bool = false
    let onToggleExpand: (String) -> Void
    let onValueChange: ([String], Any) -> Void
    var onAddField: (([String]) -> Void)? = nil
    var onDeleteField: (([String]) -> Void)? = nil
    var onInsertArrayElement: (([String]) -> Void)? = nil
    var onDeleteArrayElement: (([String]) -> Void)? = nil
    var onMoveArrayElement: ((_ arrayPath: [String], _ fromIndex: Int, _ toIndex: Int) -> Void)? = nil
    let pathsToExpand: ([String]?) -> Set<String>
    @Binding var scrollProxy: ScrollViewProxy?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(treeViewModel.flattenedNodes) { node in
                        JSONNodeRowView(
                            node: node,
                            onToggleExpand: { onToggleExpand(node.id) },
                            onValueChange: onValueChange,
                            onAddField: onAddField,
                            onDeleteField: onDeleteField,
                            onInsertArrayElement: onInsertArrayElement,
                            onDeleteArrayElement: onDeleteArrayElement,
                            onMoveArrayElement: onMoveArrayElement,
                            onSelect: { path, value in
                                store.selectNode(path: path, value: value)
                            },
                            isSelected: node.id == store.selectedNodePath,
                            isReadOnly: isReadOnly
                        )
                    }
                }
                .padding()
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: searchMatches.currentPath) { _, newPath in
                treeViewModel.currentMatchPath = newPath
                treeViewModel.searchExpandedPaths = pathsToExpand(newPath)

                if let path = newPath {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(path.joined(separator: "."), anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - S3 Search Bar

/// Search bar with text editor-style navigation (next/prev buttons)
struct S3SearchBar: View {
    @Binding var searchQuery: String
    let currentMatch: Int
    let totalMatches: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search keys...", text: $searchQuery)
                .textFieldStyle(.plain)
                .focused($isFocused)

            if !searchQuery.isEmpty {
                matchCounterView
                navigationButtons
                clearButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder
    private var matchCounterView: some View {
        if totalMatches > 0 {
            Text("\(currentMatch) of \(totalMatches)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        } else {
            Text("No matches")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 4) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(totalMatches == 0)

            Button(action: onNext) {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(totalMatches == 0)
        }
    }

    private var clearButton: some View {
        Button {
            searchQuery = ""
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - S3 Detail Header

/// Header showing country info and action buttons
struct S3DetailHeader: View {
    @Environment(S3Store.self) private var store
    let country: S3CountryConfig
    var isReadOnly: Bool = false
    @Binding var validationResult: JSONSchemaValidationResult?
    @Binding var showValidationPanel: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                countryInfoView

                Spacer()

                actionButtons
            }

            // Show selected path when a field is selected
            if let selectedPath = store.selectedNodePath {
                HStack(spacing: 4) {
                    Text("Selected:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(selectedPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.blue)

                    Button {
                        store.clearNodeSelection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var countryInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(country.countryName)
                .font(.headline)

            HStack(spacing: 8) {
                Text(country.countryCode.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("•")
                    .foregroundStyle(.secondary)

                Text(store.selectedEnvironment.displayName)
                    .font(.caption)
                    .foregroundStyle(store.selectedEnvironment == .staging ? .orange : .green)
            }
        }
    }

    /// Returns true if the selected node path contains an array index (numeric path component)
    /// e.g., "hidden_form_fields.[0]" or "items.[1].name" would return true
    private var isArrayElementSelected: Bool {
        guard let path = store.selectedNodePath else { return false }
        let components = path.split(separator: ".")
        return components.contains { component in
            // Strip brackets to handle both "[0]" and "0" formats
            let stripped = String(component).replacingOccurrences(of: "[", with: "")
                                            .replacingOccurrences(of: "]", with: "")
            return Int(stripped) != nil
        }
    }

    private var actionButtons: some View {
        HStack {
            // Inspect Field button - view field values across countries (always visible, read-only safe)
            Button {
                store.startInspectFieldWizard()
            } label: {
                Label("Inspect Field", systemImage: "eye.circle")
            }
            .disabled(store.selectedNodePath == nil || isArrayElementSelected)
            .buttonStyle(.bordered)

            // Batch Update button - hidden when read-only
            if !isReadOnly {
                Button {
                    store.startApplyFieldWizard()
                } label: {
                    Label("Batch Update", systemImage: "square.on.square")
                }
                .disabled(store.selectedNodePath == nil || isArrayElementSelected)
                .buttonStyle(.bordered)
            }

            // Discard and Save buttons - only visible when country has changes and not read-only
            if country.hasChanges && !isReadOnly {
                Button("Discard") {
                    Task {
                        await store.discardChanges(for: country.id)
                    }
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    Task {
                        // Run validation for informational purposes only
                        let validation = await store.validateCountry(country)
                        validationResult = validation

                        // Save regardless of validation results (errors are informative only)
                        do {
                            try await store.saveCountry(country)
                        } catch {
                            store.saveErrorMessage = error.localizedDescription
                            store.showSaveError = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    S3DetailView()
        .environment(S3Store())
        .frame(width: 600, height: 400)
}
