import SwiftUI
import DHBootlegToolkitCore

struct TranslationDetailView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if let selectedKey = store.selectedKey {
                TranslationFormView(key: selectedKey)
            } else {
                ContentUnavailableView(
                    "Select a Translation Key",
                    systemImage: "text.cursor",
                    description: Text("Choose a key from the list to edit")
                )
            }
        }
    }
}

// MARK: - Selectable Text (Read-Only Copyable)

struct SelectableText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Translation Form View

struct TranslationFormView: View {
    @Environment(AppStore.self) private var store
    let key: TranslationKey  // The original/saved key (for comparison)

    @State private var targetLanguagesText: String = ""
    @State private var keyValidationError: String?
    @State private var charLimitText: String = ""
    @State private var charLimitError: String?
    @State private var targetLanguagesError: String?

    // Error handling state
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showOverwriteConfirmation = false
    @State private var isSaving = false

    init(key: TranslationKey) {
        self.key = key
        self._targetLanguagesText = State(initialValue: key.targetLanguages?.joined(separator: ", ") ?? "")
        self._charLimitText = State(initialValue: key.charLimit.map { String($0) } ?? "")
    }

    // MARK: - Computed Bindings for Form Fields

    /// The edited key from store (or fallback to original key)
    private var editedKey: TranslationKey {
        store.editedKey ?? key
    }

    private var keyBinding: Binding<String> {
        Binding(
            get: { store.editedKey?.key ?? key.key },
            set: { newValue in
                var updated = store.editedKey ?? key
                updated.key = newValue
                store.editedKey = updated
                store.hasChanges = hasFormChanges
            }
        )
    }

    private var translationBinding: Binding<String> {
        Binding(
            get: { store.editedKey?.translation ?? key.translation },
            set: { newValue in
                var updated = store.editedKey ?? key
                updated.translation = newValue
                store.editedKey = updated
                store.hasChanges = hasFormChanges
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { store.editedKey?.notes ?? key.notes },
            set: { newValue in
                var updated = store.editedKey ?? key
                updated.notes = newValue
                store.editedKey = updated
                store.hasChanges = hasFormChanges
            }
        )
    }

    private var isReadOnly: Bool {
        store.isOnProtectedBranch
    }

    /// Validates a single language code (e.g., "de_DE", "zh_TW", "en", "cn")
    /// Allows: 2-3 letters, optionally followed by underscore and 2-3 letters
    private func isValidLanguageCode(_ code: String) -> Bool {
        let pattern = "^[a-zA-Z]{2,3}(_[a-zA-Z]{2,3})?$"
        return code.range(of: pattern, options: .regularExpression) != nil
    }

    /// Validates all language codes and returns error message if any are invalid
    private func validateTargetLanguages(_ text: String) -> String? {
        guard !text.isEmpty else { return nil }

        let rawParts = text.components(separatedBy: ",")
        let trimmedParts = rawParts.map { $0.trimmingCharacters(in: .whitespaces) }

        // Check for empty entries (trailing commas, double commas, etc.)
        let emptyCount = trimmedParts.filter { $0.isEmpty }.count
        if emptyCount > 0 {
            return "Remove empty entries (trailing or duplicate commas)"
        }

        let codes = trimmedParts.filter { !$0.isEmpty }

        // Check for duplicates (case-insensitive)
        let lowercasedCodes = codes.map { $0.lowercased() }
        let uniqueCodes = Set(lowercasedCodes)
        if uniqueCodes.count != codes.count {
            // Find the duplicates
            var seen = Set<String>()
            var duplicates = [String]()
            for code in lowercasedCodes {
                if seen.contains(code) && !duplicates.contains(code) {
                    duplicates.append(code)
                }
                seen.insert(code)
            }
            if duplicates.count == 1 {
                return "Duplicate language code: \(duplicates[0])"
            } else {
                return "Duplicate language codes: \(duplicates.joined(separator: ", "))"
            }
        }

        // Check for invalid format
        let invalidCodes = codes.filter { !isValidLanguageCode($0) }

        if invalidCodes.isEmpty {
            return nil
        } else if invalidCodes.count == 1 {
            return "Invalid language code: \(invalidCodes[0])"
        } else {
            return "Invalid language codes: \(invalidCodes.joined(separator: ", "))"
        }
    }

    private var canSaveForm: Bool {
        editedKey.isValid &&
        keyValidationError == nil &&
        charLimitError == nil &&
        targetLanguagesError == nil &&
        editedKey.isKeyFormatValid
    }

    /// Detects if form has unsaved changes compared to original key
    private var hasFormChanges: Bool {
        guard let edited = store.editedKey else { return false }
        return edited.key != key.key ||
               edited.translation != key.translation ||
               edited.notes != key.notes ||
               edited.targetLanguages != key.targetLanguages ||
               edited.charLimit != key.charLimit
    }

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Read-only banner when on protected branch
                    if isReadOnly {
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
                    }

                    // Key Name
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Key Name")
                                if !isReadOnly {
                                    Text("*")
                                        .foregroundStyle(.red)
                                }
                            }
                            .font(.headline)

                            if isReadOnly {
                                SelectableText(editedKey.key)
                            } else {
                                TextField("e.g., HOME_Welcome_Title", text: keyBinding)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: editedKey.key) { _, newValue in
                                        keyValidationError = store.validateKeyName(newValue, excludingId: editedKey.id)
                                    }

                                if let error = keyValidationError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundStyle(.red)
                                        Text(error)
                                            .foregroundStyle(.red)
                                    }
                                    .font(.caption)
                                } else if !editedKey.key.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("Key name is valid")
                                            .foregroundStyle(.green)
                                    }
                                    .font(.caption)
                                }

                                Text("Must start with a letter, use only letters, numbers, and underscores")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Translation (Required)
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Translation (en-GB)")
                                if !isReadOnly {
                                    Text("*")
                                        .foregroundStyle(.red)
                                }
                            }
                            .font(.headline)

                            if isReadOnly {
                                SelectableText(editedKey.translation)
                                    .frame(minHeight: 80, alignment: .topLeading)
                            } else {
                                TextEditor(text: translationBinding)
                                    .frame(minHeight: 80)
                                    .font(.body)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .background(Color(nsColor: .textBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }

                    // Notes (Required)
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Notes for Translators")
                                if !isReadOnly {
                                    Text("*")
                                        .foregroundStyle(.red)
                                }
                            }
                            .font(.headline)

                            if isReadOnly {
                                SelectableText(editedKey.notes)
                                    .frame(minHeight: 60, alignment: .topLeading)
                            } else {
                                TextEditor(text: notesBinding)
                                    .frame(minHeight: 60)
                                    .font(.body)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .background(Color(nsColor: .textBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }

                    // Target Languages (Optional)
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Languages")
                                .font(.headline)

                            if isReadOnly {
                                SelectableText(editedKey.targetLanguages?.joined(separator: ", ") ?? "All languages")
                            } else {
                                TextField("e.g., de_DE, tr_TR, zh_TW", text: $targetLanguagesText)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: targetLanguagesText) { _, newValue in
                                        var updated = store.editedKey ?? key
                                        if newValue.isEmpty {
                                            updated.targetLanguages = nil
                                            targetLanguagesError = nil
                                        } else {
                                            targetLanguagesError = validateTargetLanguages(newValue)
                                            // Only update the model if validation passes
                                            if targetLanguagesError == nil {
                                                updated.targetLanguages = newValue
                                                    .components(separatedBy: ",")
                                                    .map { $0.trimmingCharacters(in: .whitespaces) }
                                                    .filter { !$0.isEmpty }
                                            }
                                        }
                                        store.editedKey = updated
                                        store.hasChanges = hasFormChanges
                                    }

                                if let error = targetLanguagesError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundStyle(.red)
                                        Text(error)
                                            .foregroundStyle(.red)
                                    }
                                    .font(.caption)
                                }

                                Text("Leave empty to target all languages. Format: 2-3 letter codes (e.g., de_DE, en, zh_TW)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Character Limit (Optional)
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Character Limit")
                                .font(.headline)

                            if isReadOnly {
                                SelectableText(editedKey.charLimit.map { "\($0)" } ?? "No limit")
                            } else {
                                HStack {
                                    TextField("Max characters", text: $charLimitText)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: charLimitText) { _, newValue in
                                            var updated = store.editedKey ?? key
                                            if newValue.isEmpty {
                                                updated.charLimit = nil
                                                charLimitError = nil
                                            } else if let intValue = Int(newValue), intValue > 0 {
                                                updated.charLimit = intValue
                                                charLimitError = nil
                                            } else {
                                                charLimitError = "Please enter a valid positive number"
                                            }
                                            store.editedKey = updated
                                            store.hasChanges = hasFormChanges
                                        }

                                    if editedKey.charLimit != nil || !charLimitText.isEmpty {
                                        Button {
                                            var updated = store.editedKey ?? key
                                            updated.charLimit = nil
                                            store.editedKey = updated
                                            charLimitText = ""
                                            charLimitError = nil
                                            store.hasChanges = hasFormChanges
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                if let error = charLimitError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundStyle(.red)
                                        Text(error)
                                            .foregroundStyle(.red)
                                    }
                                    .font(.caption)
                                }

                                Text("Leave empty for no character limit")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Validation Status (only in edit mode)
                    if !isReadOnly {
                        ValidationStatusView(
                            editedKey: editedKey,
                            keyValidationError: keyValidationError,
                            charLimitError: charLimitError,
                            targetLanguagesError: targetLanguagesError
                        )
                    }
                }
                .padding()
                .padding(.bottom, !isReadOnly ? 60 : 0) // Add bottom padding for fixed toolbar
            }

            // Fixed bottom toolbar (only in edit mode) - positioned above GitStatusBar
            if !isReadOnly {
                VStack(spacing: 0) {
                    Divider()
                        .background(.quaternary)

                    HStack(spacing: 12) {
                        // Discard button (only shown if key has changes)
                        if let feature = store.selectedFeature {
                            let changeStatus = store.keyChangeStatus(key.key, in: feature)
                            if changeStatus != .unchanged {
                                Button(role: .destructive) {
                                    store.keyToDiscard = key.key
                                    store.featureToDiscard = feature
                                    store.showDiscardKeyConfirmation = true
                                } label: {
                                    Label("Discard Changes", systemImage: "arrow.uturn.backward")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .help("Discard changes to this translation key")
                            }
                        }

                        Spacer()

                        Button {
                            if let edited = store.editedKey {
                                store.updateKey(edited)
                                Task { await performSave(forceOverwrite: false) }
                            }
                        } label: {
                            if isSaving {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Saving...")
                                }
                            } else {
                                Label("Save", systemImage: "checkmark.circle.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.accentColor)
                        .help("Save translation key (⌘S)")
                        .disabled(!canSaveForm || isSaving)
                        .keyboardShortcut("s", modifiers: .command)
                        .shadow(color: canSaveForm && !isSaving ? .accentColor.opacity(0.4) : .clear, radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .white.opacity(0.1),
                                        .clear
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                }
            }
        }
        .alert("Save Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("File Modified Externally", isPresented: $showOverwriteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Overwrite", role: .destructive) {
                Task { await performSave(forceOverwrite: true) }
            }
        } message: {
            Text("The file was modified externally. Do you want to overwrite it with your changes?")
        }
        .onAppear {
            // Initialize editedKey if not already set for this key
            if store.editedKey?.id != key.id {
                store.editedKey = key
            }
            // Sync text fields from editedKey
            targetLanguagesText = store.editedKey?.targetLanguages?.joined(separator: ", ") ?? ""
            charLimitText = store.editedKey?.charLimit.map { String($0) } ?? ""
        }
        .onChange(of: key) { _, newKey in
            // Only reset if switching to a different key
            if store.editedKey?.id != newKey.id {
                store.editedKey = newKey
                targetLanguagesText = newKey.targetLanguages?.joined(separator: ", ") ?? ""
                charLimitText = newKey.charLimit.map { String($0) } ?? ""
                keyValidationError = nil
                charLimitError = nil
                targetLanguagesError = nil
                store.hasChanges = false
            }
        }
    }

    // MARK: - Save Actions

    private func performSave(forceOverwrite: Bool) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await store.saveCurrentFile(forceOverwrite: forceOverwrite)
        } catch let error as FileOperationError {
            if error.canForceOverwrite {
                // External modification - prompt user for confirmation
                showOverwriteConfirmation = true
            } else {
                // Other error - show alert
                errorMessage = error.localizedDescription
                showError = true
            }
        } catch {
            // Unexpected error
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Validation Status View

struct ValidationStatusView: View {
    let editedKey: TranslationKey
    let keyValidationError: String?
    let charLimitError: String?
    let targetLanguagesError: String?

    private var issues: [String] {
        var result: [String] = []

        if editedKey.key.isEmpty {
            result.append("Key name is required")
        } else if keyValidationError != nil {
            result.append(keyValidationError!)
        }

        if editedKey.translation.isEmpty {
            result.append("Translation is required")
        }

        if editedKey.notes.isEmpty {
            result.append("Notes for translators is required")
        }

        if let charError = charLimitError {
            result.append(charError)
        }

        if let langError = targetLanguagesError {
            result.append(langError)
        }

        return result
    }

    var body: some View {
        if !issues.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Please fix the following to save:")
                        .font(.headline)
                }

                ForEach(issues, id: \.self) { issue in
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                        Text(issue)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    TranslationDetailView()
        .environment(AppStore())
        .frame(width: 450, height: 700)
}
