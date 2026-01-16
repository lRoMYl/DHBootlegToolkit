import SwiftUI
import DHBootlegToolkitCore

struct DetailTabView: View {
    @Environment(AppStore.self) private var store

    private var hasTabs: Bool {
        store.showNewKeyTab || !store.openTabs.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            if hasTabs {
                tabBar
                Divider()
            }

            // Content area
            contentArea
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            // "New" tab - always first, visually distinct
            if store.showNewKeyTab {
                NewKeyTabButton(
                    isActive: store.isNewKeyTabActive,
                    onSelect: { store.focusNewKeyTab() },
                    onClose: { store.closeNewKeyTab() }
                )

                // Separator between "New" and key tabs
                if !store.openTabs.isEmpty {
                    Divider()
                        .frame(height: 16)
                        .padding(.horizontal, 8)
                }
            }

            // Key tabs - draggable
            ForEach(store.openTabs) { tab in
                DraggableKeyTab(
                    tab: tab,
                    isActive: store.activeTabId == tab.id,
                    onSelect: { store.focusKeyTab(tab.id) },
                    onClose: { store.requestCloseTab(tab.id) },
                    onDrop: { draggedId in
                        guard let sourceIndex = store.openTabs.firstIndex(where: { $0.id == draggedId }),
                              let destIndex = store.openTabs.firstIndex(where: { $0.id == tab.id }),
                              sourceIndex != destIndex else {
                            return false
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.moveTab(fromOffsets: IndexSet(integer: sourceIndex), toOffset: destIndex > sourceIndex ? destIndex + 1 : destIndex)
                        }
                        return true
                    }
                )
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if !hasTabs {
            emptyState
        } else if store.isNewKeyTabActive, let feature = store.newKeyTabFeature {
            // "New" tab is active
            NewKeyWizard(feature: feature)
                .id("wizard-\(feature.id)")
        } else if let tab = store.activeKeyTab, let key = tab.editedKey {
            // A key tab is active
            TranslationFormView(key: key)
                .id("form-\(tab.id)")
        } else if let imageTab = store.activeImageTab {
            // An image tab is active
            ImageTabView(
                imageURL: imageTab.imageURL,
                imageName: imageTab.imageName
            )
            .id("image-\(imageTab.id)")
        } else if let textFileTab = store.activeTextFileTab {
            // A text file tab is active
            TextTabView(
                fileURL: textFileTab.fileURL,
                fileName: textFileTab.fileName,
                fileExtension: textFileTab.fileExtension
            )
            .id("textFile-\(textFileTab.id)")
        } else if let genericFileTab = store.activeGenericFileTab {
            // A generic file tab is active
            GenericFileTabView(
                fileURL: genericFileTab.fileURL,
                fileName: genericFileTab.fileName,
                iconName: genericFileTab.iconName
            )
            .id("genericFile-\(genericFileTab.id)")
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
                .frame(maxHeight: 80)

            ContentUnavailableView(
                "Select a Translation Key",
                systemImage: "text.cursor",
                description: Text("Choose a key from the sidebar to edit, or click \"Add New Key\" to create one")
            )

            Spacer()
        }
    }
}

// MARK: - New Key Tab Button (Distinct styling)

struct NewKeyTabButton: View {
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)

                Text("New Key")
                    .fontWeight(.medium)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isActive
                    ? Color.green.opacity(0.15)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Draggable Key Tab Wrapper

struct DraggableKeyTab: View {
    let tab: EditorTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onDrop: (UUID) -> Bool

    @State private var isDropTarget = false

    var body: some View {
        KeyTabButton(
            tab: tab,
            isActive: isActive,
            isDropTarget: isDropTarget,
            onSelect: onSelect,
            onClose: onClose
        )
        .draggable(tab.id.uuidString) {
            // Drag preview
            HStack(spacing: 4) {
                if tab.isImageTab {
                    Image(systemName: "photo")
                        .foregroundStyle(.purple)
                }
                Text(tab.displayName)
            }
            .padding(8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .dropDestination(for: String.self) { items, _ in
            guard let draggedIdString = items.first,
                  let draggedId = UUID(uuidString: draggedIdString) else {
                return false
            }
            return onDrop(draggedId)
        } isTargeted: { isTargeted in
            isDropTarget = isTargeted
        }
    }
}

// MARK: - Key Tab Button (Standard styling with drag support)

struct KeyTabButton: View {
    let tab: EditorTab
    let isActive: Bool
    let isDropTarget: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    private var hasUnsavedChanges: Bool {
        tab.keyData?.hasChanges ?? false
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                // Tab type icon for image tabs
                if tab.isImageTab {
                    Image(systemName: "photo")
                        .foregroundStyle(.purple)
                        .font(.caption)
                } else if tab.isTextFileTab {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if tab.isGenericFileTab {
                    Image(systemName: "doc")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                // Unsaved changes indicator (only for key tabs)
                if hasUnsavedChanges {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                }

                Text(tab.displayName.isEmpty ? "Untitled" : tab.displayName)
                    .lineLimit(1)
                    .frame(maxWidth: 150)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                isActive
                    ? Color(nsColor: .controlBackgroundColor)
                    : isDropTarget
                        ? Color.accentColor.opacity(0.2)
                        : Color.clear,
                in: RoundedRectangle(cornerRadius: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isDropTarget ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? .primary : .secondary)
        .onHover { isHovering = $0 }
    }
}

// MARK: - New Key Wizard

struct NewKeyWizard: View {
    @Environment(AppStore.self) private var store
    let feature: FeatureFolder

    @State private var currentStep: WizardStep = .screenshot
    @State private var screenshotURL: URL?
    @State private var generatedScreenshotName: String = ""
    @State private var keyName: String = ""
    @State private var translation: String = ""
    @State private var notes: String = ""
    @State private var targetLanguagesText: String = ""
    @State private var charLimit: Int?
    @State private var keyValidationError: String?
    @State private var isDropTargeted = false
    @State private var isCreating = false

    // Error handling state
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showOverwriteConfirmation = false
    @State private var pendingNewKey: TranslationKey?
    @State private var pendingScreenshot: PendingScreenshot?

    enum WizardStep: Int, CaseIterable {
        case screenshot = 0
        case keyDetails = 1
        case review = 2

        var title: String {
            switch self {
            case .screenshot: return "Add Screenshot"
            case .keyDetails: return "Key Details"
            case .review: return "Review & Create"
            }
        }

        var stepNumber: Int { rawValue + 1 }
        var totalSteps: Int { WizardStep.allCases.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            wizardHeader

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    switch currentStep {
                    case .screenshot:
                        screenshotStep
                    case .keyDetails:
                        keyDetailsStep
                    case .review:
                        reviewStep
                    }
                }
                .padding(24)
            }

            Divider()

            // Navigation buttons
            navigationButtons
        }
        .alert("Save Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("File Modified Externally", isPresented: $showOverwriteConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingNewKey = nil
                pendingScreenshot = nil
            }
            Button("Overwrite", role: .destructive) {
                Task { await saveWithOverwrite() }
            }
        } message: {
            Text("The file was modified externally. Do you want to overwrite it with your changes?")
        }
    }

    // MARK: - Header

    private var wizardHeader: some View {
        VStack(spacing: 12) {
            Text("New Translation Key for \(feature.displayName)")
                .font(.headline)

            // Progress indicator
            HStack(spacing: 8) {
                ForEach(WizardStep.allCases, id: \.rawValue) { step in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay {
                                if step.rawValue < currentStep.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(step.stepNumber)")
                                        .font(.caption.bold())
                                        .foregroundStyle(step.rawValue <= currentStep.rawValue ? .white : .secondary)
                                }
                            }

                        if step != WizardStep.allCases.last {
                            Rectangle()
                                .fill(step.rawValue < currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: 40)
                        }
                    }
                }
            }

            Text(currentStep.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Step 1: Screenshot

    private var screenshotStep: some View {
        VStack(spacing: 16) {
            Text("Start by adding a screenshot showing where this translation will appear.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            // Drop zone
            VStack(spacing: 12) {
                if let url = screenshotURL {
                    // Show selected screenshot
                    VStack(spacing: 8) {
                        if let image = NSImage(contentsOf: url) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading) {
                                Text(generatedScreenshotName)
                                    .font(.headline)
                                Text("from: \(url.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Change") {
                                selectScreenshot()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    // Empty drop zone
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("Drop PNG screenshot here")
                            .font(.headline)

                        Text("or")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Button("Choose File...") {
                            selectScreenshot()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [8])
                            )
                    )
                    .contentShape(Rectangle())
                    .onDrop(of: [.png, .fileURL], isTargeted: $isDropTargeted) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                }
            }

            if !generatedScreenshotName.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Screenshot will be saved as: **\(generatedScreenshotName)**")
                        .font(.caption)
                }
                .padding(8)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - Step 2: Key Details

    private var keyDetailsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Key Name
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Key Name")
                        .font(.headline)
                    Text("*")
                        .foregroundStyle(.red)
                }

                TextField("e.g., HOME_Welcome_Title", text: $keyName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: keyName) { _, newValue in
                        keyValidationError = store.validateKeyName(newValue, excludingId: UUID())
                    }

                if let error = keyValidationError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                    }
                    .font(.caption)
                } else if !keyName.isEmpty {
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

            Divider()

            // Translation
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Translation (en-GB)")
                        .font(.headline)
                    Text("*")
                        .foregroundStyle(.red)
                }

                TextEditor(text: $translation)
                    .frame(height: 80)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Notes
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Notes for Translators")
                        .font(.headline)
                    Text("*")
                        .foregroundStyle(.red)
                }

                TextEditor(text: $notes)
                    .frame(height: 60)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text("Provide context to help translators understand where and how this text is used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Optional fields
            DisclosureGroup("Optional Settings") {
                VStack(alignment: .leading, spacing: 16) {
                    // Target Languages
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Languages")
                            .font(.subheadline.bold())

                        TextField("e.g., de_DE, tr_TR, zh_TW", text: $targetLanguagesText)
                            .textFieldStyle(.roundedBorder)

                        Text("Leave empty to target all languages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Character Limit
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Character Limit")
                            .font(.subheadline.bold())

                        HStack {
                            TextField("Max characters", value: $charLimit, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)

                            if charLimit != nil {
                                Button {
                                    charLimit = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Step 3: Review

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review your new translation key before creating it.")
                .foregroundStyle(.secondary)

            // Screenshot preview
            GroupBox("Screenshot") {
                HStack {
                    if let url = screenshotURL, let image = NSImage(contentsOf: url) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    VStack(alignment: .leading) {
                        Text(generatedScreenshotName)
                            .font(.headline)
                    }
                    Spacer()
                }
            }

            // Key details
            GroupBox("Key Details") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Key Name") {
                        Text(keyName)
                            .font(.system(.body, design: .monospaced))
                    }

                    LabeledContent("Translation") {
                        Text(translation)
                            .lineLimit(2)
                    }

                    LabeledContent("Notes") {
                        Text(notes)
                            .lineLimit(2)
                            .foregroundStyle(.secondary)
                    }

                    if !targetLanguagesText.isEmpty {
                        LabeledContent("Target Languages") {
                            Text(targetLanguagesText)
                        }
                    }

                    if let limit = charLimit {
                        LabeledContent("Character Limit") {
                            Text("\(limit)")
                        }
                    }
                }
            }

            // Confirmation
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Ready to create! The key and screenshot will be added to your feature folder.")
                    .font(.callout)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            Button("Cancel") {
                store.closeNewKeyTab()
            }
            .buttonStyle(.bordered)

            Spacer()

            if currentStep != .screenshot {
                Button("Back") {
                    withAnimation {
                        currentStep = WizardStep(rawValue: currentStep.rawValue - 1) ?? .screenshot
                    }
                }
                .buttonStyle(.bordered)
            }

            if currentStep == .review {
                Button {
                    createKey()
                } label: {
                    if isCreating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Create Key")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreating)
            } else {
                Button("Next") {
                    withAnimation {
                        currentStep = WizardStep(rawValue: currentStep.rawValue + 1) ?? .review
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceedToNextStep)
            }
        }
        .padding()
    }

    // MARK: - Validation

    private var canProceedToNextStep: Bool {
        switch currentStep {
        case .screenshot:
            return screenshotURL != nil
        case .keyDetails:
            return !keyName.isEmpty &&
                   keyValidationError == nil &&
                   !translation.isEmpty &&
                   !notes.isEmpty
        case .review:
            return true
        }
    }

    // MARK: - Actions

    private func selectScreenshot() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png]
        panel.message = "Select PNG screenshot"

        if panel.runModal() == .OK, let url = panel.url {
            setScreenshot(url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url, url.pathExtension.lowercased() == "png" {
                        DispatchQueue.main.async {
                            setScreenshot(url)
                        }
                    }
                }
            }
        }
    }

    private func setScreenshot(_ url: URL) {
        screenshotURL = url
        generatedScreenshotName = store.generateScreenshotName()
    }

    private func createKey() {
        guard let screenshotURL else { return }

        // Parse target languages
        let targetLanguages: [String]? = targetLanguagesText.isEmpty ? nil :
            targetLanguagesText
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

        // Create the key
        let newKey = TranslationKey(
            key: keyName,
            translation: translation,
            notes: notes,
            targetLanguages: targetLanguages,
            charLimit: charLimit,
            isNew: false
        )

        // Create screenshot with proper name
        let destinationURL = feature.imagesFolderURL.appendingPathComponent(generatedScreenshotName)
        let screenshot = PendingScreenshot(
            id: UUID(),
            originalURL: screenshotURL,
            originalName: screenshotURL.lastPathComponent,
            renamedName: generatedScreenshotName,
            destinationURL: destinationURL
        )

        isCreating = true

        Task {
            await performSave(newKey: newKey, screenshot: screenshot, forceOverwrite: false)
        }
    }

    private func performSave(newKey: TranslationKey, screenshot: PendingScreenshot, forceOverwrite: Bool) async {
        // Step 1: Pre-validate - ensure we can actually save
        guard store.isFileSystemReady else {
            errorMessage = FileOperationError.fileSystemNotInitialized.localizedDescription
            showError = true
            isCreating = false
            return
        }

        // Step 2: Set the feature context
        store.selectedFeature = feature

        // Step 3: Load existing keys from disk (not stale cache)
        await store.loadKeysForFeature(feature)
        store.translationKeys = store.featureKeys[feature.id] ?? []

        // Step 4: Append the new key to translationKeys (in memory)
        store.translationKeys.append(newKey)

        // Step 5: Add pending screenshot
        store.pendingScreenshots.append(screenshot)

        // Step 6: Save to disk FIRST
        do {
            try await store.saveCurrentFile(forceOverwrite: forceOverwrite)

            // Step 7: Only update cache AFTER successful save
            store.featureKeys[feature.id] = store.translationKeys

            // Success - close wizard and open the new key tab
            store.closeNewKeyTab()
            store.selectKeyFromSidebar(newKey, in: feature)
            isCreating = false
        } catch let error as FileOperationError {
            // Rollback - remove the key from memory since save failed
            store.translationKeys.removeAll { $0.id == newKey.id }
            store.pendingScreenshots.removeAll { $0.id == screenshot.id }

            if error.canForceOverwrite {
                // External modification - prompt user for confirmation
                pendingNewKey = newKey
                pendingScreenshot = screenshot
                showOverwriteConfirmation = true
            } else {
                // Other error - show alert
                errorMessage = error.localizedDescription
                showError = true
            }
            isCreating = false
        } catch {
            // Rollback
            store.translationKeys.removeAll { $0.id == newKey.id }
            store.pendingScreenshots.removeAll { $0.id == screenshot.id }

            errorMessage = error.localizedDescription
            showError = true
            isCreating = false
        }
    }

    private func saveWithOverwrite() async {
        guard let newKey = pendingNewKey, let screenshot = pendingScreenshot else {
            return
        }

        isCreating = true
        pendingNewKey = nil
        pendingScreenshot = nil

        await performSave(newKey: newKey, screenshot: screenshot, forceOverwrite: true)
    }
}

#Preview {
    DetailTabView()
        .environment(AppStore())
        .frame(width: 500, height: 700)
}
