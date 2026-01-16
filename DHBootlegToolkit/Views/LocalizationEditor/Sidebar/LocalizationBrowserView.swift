import SwiftUI
import DHBootlegToolkitCore

// Note: Badge components (BadgeStyle, StatusLetterBadge, CounterBadge) are now in
// Views/Components/Badges/ for reuse across Localization Editor and S3 Editor

// MARK: - Localization Browser View

struct LocalizationBrowserView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Group {
            if store.repositoryURL == nil {
                LocalizationRepositoryPrompt()
            } else if let error = store.repositoryErrorMessage {
                LocalizationRepositoryError(errorMessage: error)
            } else {
                List {
                    // Platform section (header-only, no content)
                    Section {
                        EmptyView()
                    } header: {
                        HStack {
                            Text("Platform")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .textCase(nil)

                            Spacer()

                            PlatformToggle(
                                selectedPlatform: Binding(
                                    get: { store.selectedPlatform },
                                    set: { platform in
                                        Task { await store.selectPlatform(platform) }
                                    }
                                )
                            )
                        }
                    }

                    // Features section
                    Section {
                        if store.isLoading && store.features.isEmpty {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Loading features...")
                                    .foregroundStyle(.secondary)
                            }
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(store.filteredFeatures) { feature in
                                FeatureDisclosureView(feature: feature)
                            }
                        }
                    } header: {
                        Text("Features")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

// MARK: - Localization Repository Prompt

/// Prompt view shown when no localization repository is selected
struct LocalizationRepositoryPrompt: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Select Localization Repository")
                    .font(.headline)

                Text("Choose a local repository containing translation files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Select Repository...") {
                    selectRepository()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func selectRepository() {
        let panel = NSOpenPanel()
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the localization repository folder"

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await store.selectRepository(url, showAlertOnError: false)
            }
        }
    }
}

// MARK: - Localization Repository Error

/// Error view shown when repository validation fails
struct LocalizationRepositoryError: View {
    @Environment(AppStore.self) private var store
    let errorMessage: String

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                ContentUnavailableView(
                    "Invalid Repository",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )

                Button("Select Different Repository...") {
                    selectRepository()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func selectRepository() {
        let panel = NSOpenPanel()
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the localization repository folder"

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await store.selectRepository(url, showAlertOnError: false)
            }
        }
    }
}

// MARK: - Platform Toggle (Pill Style)

struct PlatformToggle: View {
    @Binding var selectedPlatform: Platform

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Platform.allCases) { platform in
                Button {
                    selectedPlatform = platform
                } label: {
                    Text(platform.displayName)
                        .font(.subheadline)
                        .fontWeight(selectedPlatform == platform ? .medium : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedPlatform == platform
                                ? Color.accentColor
                                : Color.clear
                        )
                        .foregroundStyle(
                            selectedPlatform == platform
                                ? .white
                                : .primary
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
        .clipShape(Capsule())
    }
}

// MARK: - Feature Disclosure View

struct FeatureDisclosureView: View {
    @Environment(AppStore.self) private var store
    let feature: FeatureFolder

    @State private var isHovering = false

    private var isExpanded: Bool {
        store.expandedFeatures.contains(feature.id)
    }

    private var fileItems: [FeatureFileItem] {
        store.featureFiles[feature.id] ?? []
    }

    private var hasUncommittedChanges: Bool {
        store.uncommittedFeatureIds.contains(feature.id)
    }

    private var diff: TranslationKeyDiff {
        store.getDiff(for: feature)
    }

    /// Aggregates git file counts from all file items (recursive)
    private var gitFileCounts: (added: Int, modified: Int, deleted: Int) {
        aggregateGitCounts(fileItems)
    }

    private func aggregateGitCounts(_ items: [FeatureFileItem]) -> (added: Int, modified: Int, deleted: Int) {
        var added = 0, modified = 0, deleted = 0

        for item in items {
            if case .folder = item.type {
                // For folders: only count children, not the folder itself
                let childCounts = aggregateGitCounts(item.children)
                added += childCounts.added
                modified += childCounts.modified
                deleted += childCounts.deleted
            } else {
                // For files: count the file's git status
                switch item.gitStatus {
                case .added: added += 1
                case .modified: modified += 1
                case .deleted: deleted += 1
                case .unchanged: break
                }
            }
        }

        return (added, modified, deleted)
    }

    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { isExpanded },
                set: { _ in store.toggleFeatureExpansion(feature) }
            )
        ) {
            // Show file items from discovery
            ForEach(fileItems) { item in
                FileItemView(item: item, feature: feature)
            }

            // Fallback: Show keys directly if file items not loaded yet
            if fileItems.isEmpty {
                ForEach(store.filteredKeys(for: feature)) { key in
                    KeyRowView(key: key, feature: feature)
                }

                // Deleted keys section
                if !diff.deletedKeys.isEmpty {
                    ForEach(Array(diff.deletedKeys).sorted(), id: \.self) { keyName in
                        DeletedKeyRowView(keyName: keyName, feature: feature)
                    }
                }

                // Add new key button
                AddNewKeyButton(feature: feature)
            }
        } label: {
            Button {
                store.toggleFeatureExpansion(feature)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                        .font(.body)

                    Text(feature.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    // Discard All button (always reserve space, show on hover)
                    if hasUncommittedChanges && diff.hasChanges && !store.isOnProtectedBranch {
                        Button {
                            store.featureToDiscard = feature
                            store.showDiscardAllConfirmation = true
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.body)
                        }
                        .buttonStyle(.glass)
                        .opacity(isHovering ? 1 : 0)
                        .help("Discard all changes")
                    }

                    // Git file counter badge showing 📂 +x ~y -z
                    if hasUncommittedChanges {
                        let counts = gitFileCounts
                        let hasFileChanges = counts.added > 0 || counts.modified > 0 || counts.deleted > 0
                        if hasFileChanges {
                            CounterBadge(
                                added: counts.added,
                                modified: counts.modified,
                                deleted: counts.deleted,
                                type: .gitFiles
                            )
                        } else {
                            // Fallback if file items not loaded yet
                            StatusLetterBadge(letter: "M", color: .blue)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
        }
        .task(id: isExpanded) {
            if isExpanded {
                await store.computeDiffForFeature(feature)
                await store.loadFilesForFeature(feature)
                // Also load keys if not loaded
                if store.featureKeys[feature.id] == nil {
                    await store.loadKeysForFeature(feature)
                }
            }
        }
    }
}

// MARK: - File Item View (Dispatcher)

struct FileItemView: View {
    @Environment(AppStore.self) private var store
    let item: FeatureFileItem
    let feature: FeatureFolder

    var body: some View {
        switch item.type {
        case .jsonFile(let isPrimary):
            if isPrimary {
                PrimaryJsonFileView(item: item, feature: feature)
            } else {
                GenericFileRow(item: item, feature: feature)
            }
        case .folder:
            FolderDisclosureView(item: item, feature: feature)
        case .image:
            ImageFileRow(item: item, feature: feature)
        case .otherFile:
            GenericFileRow(item: item, feature: feature)
        }
    }
}

// MARK: - Primary JSON File View (en.json with keys)

struct PrimaryJsonFileView: View {
    @Environment(AppStore.self) private var store
    let item: FeatureFileItem
    let feature: FeatureFolder

    @State private var isExpanded = true
    @State private var isHovering = false

    private var diff: TranslationKeyDiff {
        store.getDiff(for: feature)
    }

    /// Check if this file is the active tab
    private var isSelected: Bool {
        store.activeTextFileTab?.fileURL == item.url
    }

    /// Whether this file can be discarded (has changes and not on protected branch)
    private var canDiscard: Bool {
        item.gitStatus != .unchanged && !store.isOnProtectedBranch
    }

    /// Help text for the discard button
    private var discardHelpText: String {
        switch item.gitStatus {
        case .deleted: return "Restore file"
        case .added: return "Delete file"
        default: return "Discard changes"
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(store.filteredKeys(for: feature)) { key in
                KeyRowView(key: key, feature: feature)
            }

            // Deleted keys section
            if !diff.deletedKeys.isEmpty {
                ForEach(Array(diff.deletedKeys).sorted(), id: \.self) { keyName in
                    DeletedKeyRowView(keyName: keyName, feature: feature)
                }
            }

            // Add new key button
            AddNewKeyButton(feature: feature)
        } label: {
            Button {
                store.openTextFileTab(item.url, in: feature)
            } label: {
                HStack(spacing: 6) {
                    Image("translate-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.blue)

                    Text(item.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    // Discard button (show on hover)
                    if canDiscard {
                        Button {
                            store.fileToDiscard = (file: item, feature: feature)
                            store.showDiscardFileConfirmation = true
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.body)
                        }
                        .buttonStyle(.glass)
                        .opacity(isHovering ? 1 : 0)
                        .help(discardHelpText)
                    }

                    // Key counter badge showing translate icon +x ~y -z (not git status)
                    if diff.hasChanges {
                        CounterBadge(
                            added: diff.addedKeys.count,
                            modified: diff.modifiedKeys.count,
                            deleted: diff.deletedKeys.count,
                            type: .keys
                        )
                    }
                }
                .contentShape(Rectangle())
                .padding(.vertical, 2)
                .padding(.horizontal, -4)
                .background(
                    isSelected
                        ? Color.accentColor.opacity(0.15)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 4)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
        }
        .contextMenu {
            if canDiscard {
                Button(
                    item.gitStatus == .deleted ? "Restore File" : "Discard Changes",
                    systemImage: "arrow.uturn.backward"
                ) {
                    store.fileToDiscard = (file: item, feature: feature)
                    store.showDiscardFileConfirmation = true
                }
            }

            // Permanent delete option (only for existing files, not deleted ones)
            if item.gitStatus != .deleted && !store.isOnProtectedBranch {
                if canDiscard { Divider() }
                Button("Delete File", systemImage: "trash", role: .destructive) {
                    store.fileToDelete = (file: item, feature: feature)
                    store.showDeleteFileConfirmation = true
                }
            }
        }
    }
}

// MARK: - Folder Disclosure View

struct FolderDisclosureView: View {
    @Environment(AppStore.self) private var store
    let item: FeatureFileItem
    let feature: FeatureFolder

    @State private var isExpanded = false

    /// Whether delete is allowed (not on protected branch)
    private var canDelete: Bool {
        !store.isOnProtectedBranch
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(item.children) { child in
                FileItemView(item: child, feature: feature)
            }
        } label: {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: item.iconName)
                        .foregroundStyle(.blue)
                        .font(.body)

                    Text(item.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                if canDelete {
                    Button("Delete Folder", systemImage: "trash", role: .destructive) {
                        store.folderToDelete = (folder: item, feature: feature)
                        store.showDeleteFolderConfirmation = true
                    }
                }
            }
        }
    }
}

// MARK: - Image File Row

struct ImageFileRow: View {
    @Environment(AppStore.self) private var store
    let item: FeatureFileItem
    let feature: FeatureFolder

    @State private var isHovering = false

    /// Only highlight if this image is the ACTIVE tab (not just any open tab)
    private var isSelected: Bool {
        store.activeImageTab?.imageURL == item.url
    }

    /// Whether this file can be discarded (has changes and not on protected branch)
    private var canDiscard: Bool {
        item.gitStatus != .unchanged && !store.isOnProtectedBranch
    }

    /// Help text for the discard button
    private var discardHelpText: String {
        switch item.gitStatus {
        case .deleted: return "Restore file"
        case .added: return "Delete file"
        default: return "Discard changes"
        }
    }

    var body: some View {
        Button {
            // Don't open deleted files
            if item.gitStatus != .deleted {
                store.openImageTab(item.url, in: feature)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: item.iconName)
                    .foregroundStyle(item.gitStatus == .deleted ? Color.secondary : Color.purple)
                    .font(.body)

                Text(item.name)
                    .font(.body)
                    .foregroundStyle(item.gitStatus == .deleted ? Color.secondary : Color.primary)
                    .strikethrough(item.gitStatus == .deleted)
                    .lineLimit(1)

                Spacer()

                // Discard button (show on hover)
                if canDiscard {
                    Button {
                        store.fileToDiscard = (file: item, feature: feature)
                        store.showDiscardFileConfirmation = true
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.body)
                    }
                    .buttonStyle(.glass)
                    .opacity(isHovering ? 1 : 0)
                    .help(discardHelpText)
                }

                // Git status badge
                GitStatusBadge(status: item.gitStatus)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .listRowBackground(
            isSelected
                ? Color.accentColor.opacity(0.15)
                : Color.clear
        )
        .contextMenu {
            if canDiscard {
                Button(
                    item.gitStatus == .deleted ? "Restore File" : "Discard Changes",
                    systemImage: "arrow.uturn.backward"
                ) {
                    store.fileToDiscard = (file: item, feature: feature)
                    store.showDiscardFileConfirmation = true
                }
            }

            // Permanent delete option (only for existing files, not deleted ones)
            if item.gitStatus != .deleted && !store.isOnProtectedBranch {
                Divider()
                Button("Delete File", systemImage: "trash", role: .destructive) {
                    store.fileToDelete = (file: item, feature: feature)
                    store.showDeleteFileConfirmation = true
                }
            }
        }
    }
}

// MARK: - Generic File Row

struct GenericFileRow: View {
    @Environment(AppStore.self) private var store
    let item: FeatureFileItem
    let feature: FeatureFolder

    @State private var isHovering = false

    /// Text file extensions that get syntax highlighting or rendering
    private static let textFileExtensions = Set(["txt", "json", "md", "markdown", "xml", "plist", "yaml", "yml"])

    /// Check if this file is a text file (previewable with TextTabView)
    private var isTextFile: Bool {
        Self.textFileExtensions.contains(item.url.pathExtension.lowercased())
    }

    /// Only highlight if this file is the ACTIVE tab (check both text and generic file tabs)
    private var isSelected: Bool {
        if let activeTabId = store.activeTabId {
            if let tab = store.openTabs.first(where: { $0.id == activeTabId }) {
                if let genericData = tab.genericFileData {
                    return genericData.fileURL == item.url
                }
                if let textData = tab.textFileData {
                    return textData.fileURL == item.url
                }
            }
        }
        return false
    }

    private var canDiscard: Bool {
        item.gitStatus != .unchanged && !store.isOnProtectedBranch
    }

    private var discardHelpText: String {
        switch item.gitStatus {
        case .deleted: return "Restore file"
        case .added: return "Delete file"
        default: return "Discard changes"
        }
    }

    var body: some View {
        Button {
            // Don't open deleted files
            if item.gitStatus != .deleted {
                if isTextFile {
                    store.openTextFileTab(item.url, in: feature)
                } else {
                    store.openGenericFileTab(item.url, iconName: item.iconName, in: feature)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: item.iconName)
                    .foregroundStyle(item.gitStatus == .deleted ? .secondary : .secondary)
                    .font(.body)

                Text(item.name)
                    .font(.body)
                    .foregroundStyle(item.gitStatus == .deleted ? .secondary : .primary)
                    .strikethrough(item.gitStatus == .deleted)
                    .lineLimit(1)

                Spacer()

                // Discard button (show on hover)
                if canDiscard {
                    Button {
                        store.fileToDiscard = (file: item, feature: feature)
                        store.showDiscardFileConfirmation = true
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.body)
                    }
                    .buttonStyle(.glass)
                    .opacity(isHovering ? 1 : 0)
                    .help(discardHelpText)
                }

                // Git status badge
                GitStatusBadge(status: item.gitStatus)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .listRowBackground(
            isSelected
                ? Color.accentColor.opacity(0.15)
                : Color.clear
        )
        .contextMenu {
            if canDiscard {
                Button(
                    item.gitStatus == .deleted ? "Restore File" : "Discard Changes",
                    systemImage: "arrow.uturn.backward"
                ) {
                    store.fileToDiscard = (file: item, feature: feature)
                    store.showDiscardFileConfirmation = true
                }
            }

            // Permanent delete option (only for existing files, not deleted ones)
            if item.gitStatus != .deleted && !store.isOnProtectedBranch {
                Divider()
                Button("Delete File", systemImage: "trash", role: .destructive) {
                    store.fileToDelete = (file: item, feature: feature)
                    store.showDeleteFileConfirmation = true
                }
            }
        }
    }
}

// MARK: - Add New Key Button

struct AddNewKeyButton: View {
    @Environment(AppStore.self) private var store
    let feature: FeatureFolder

    var body: some View {
        Button {
            if store.isOnProtectedBranch {
                store.pendingAddNewKeyFeature = feature
                store.showCreateBranchPrompt = true
            } else {
                store.openNewKeyTab(for: feature)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.body)

                Text("Add New Key")
                    .font(.body)
            }
            .foregroundStyle(store.isOnProtectedBranch ? .tertiary : .secondary)
        }
        .buttonStyle(.plain)
        .help(store.isOnProtectedBranch ? "Create a feature branch first" : "Add a new translation key")
    }
}

// MARK: - Git Status Badge (for files)

struct GitStatusBadge: View {
    let status: GitFileStatus

    private var letter: String {
        switch status {
        case .added: return "A"
        case .modified: return "M"
        case .deleted: return "D"
        case .unchanged: return ""
        }
    }

    private var badgeColor: Color {
        switch status {
        case .added: return .green
        case .modified: return .blue
        case .deleted: return .red
        case .unchanged: return .clear
        }
    }

    var body: some View {
        if status != .unchanged {
            StatusLetterBadge(letter: letter, color: badgeColor)
        }
    }
}

// MARK: - Deleted Key Row View

struct DeletedKeyRowView: View {
    @Environment(AppStore.self) private var store
    let keyName: String
    let feature: FeatureFolder

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .foregroundStyle(.tertiary)
                .font(.body)

            Text(keyName)
                .font(.body)
                .lineLimit(1)
                .strikethrough()
                .foregroundStyle(.secondary)

            Spacer()

            // Restore button (always reserve space, show on hover)
            if !store.isOnProtectedBranch {
                Button {
                    store.keyToDiscard = keyName
                    store.featureToDiscard = feature
                    store.showDiscardKeyConfirmation = true
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.body)
                }
                .buttonStyle(.glass)
                .opacity(isHovering ? 1 : 0)
                .help("Restore key")
            }

            // Deleted badge
            ChangeStatusBadge(status: .deleted)
        }
        .opacity(0.7)
        .onHover { isHovering = $0 }
        .contextMenu {
            if !store.isOnProtectedBranch {
                Button("Restore Key", systemImage: "arrow.uturn.backward") {
                    store.keyToDiscard = keyName
                    store.featureToDiscard = feature
                    store.showDiscardKeyConfirmation = true
                }
            }
        }
    }
}

// MARK: - Change Status Badge (for keys)

struct ChangeStatusBadge: View {
    let status: KeyChangeStatus

    private var letter: String {
        switch status {
        case .added: return "A"
        case .modified: return "M"
        case .deleted: return "D"
        case .unchanged: return ""
        }
    }

    private var badgeColor: Color {
        switch status {
        case .added: return .green
        case .modified: return .blue
        case .deleted: return .red
        case .unchanged: return .clear
        }
    }

    var body: some View {
        if status != .unchanged {
            StatusLetterBadge(letter: letter, color: badgeColor)
        }
    }
}

// MARK: - Key Row View

struct KeyRowView: View {
    @Environment(AppStore.self) private var store
    let key: TranslationKey
    let feature: FeatureFolder

    @State private var isHovering = false

    /// Only highlight if this key is the ACTIVE tab (selectedKey returns active tab's key)
    private var isSelected: Bool {
        store.selectedKey?.id == key.id
    }

    private var changeStatus: KeyChangeStatus {
        store.keyChangeStatus(key.key, in: feature)
    }

    var body: some View {
        Button {
            store.selectKeyFromSidebar(key, in: feature)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                    .font(.body)

                Text(key.key)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // Discard button (always reserve space, show on hover)
                if changeStatus != .unchanged && !store.isOnProtectedBranch {
                    Button {
                        store.keyToDiscard = key.key
                        store.featureToDiscard = feature
                        store.showDiscardKeyConfirmation = true
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.body)
                    }
                    .buttonStyle(.glass)
                    .opacity(isHovering ? 1 : 0)
                    .help("Discard changes")
                }

                // Xcode-style change badge
                ChangeStatusBadge(status: changeStatus)

                // Invalid indicator (orange dot)
                if !key.isValid {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                        .help("Incomplete - missing required fields")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .listRowBackground(
            isSelected
                ? Color.accentColor.opacity(0.15)
                : Color.clear
        )
        .contextMenu {
            // Discard option (only for changed keys)
            if changeStatus != .unchanged && !store.isOnProtectedBranch {
                Button("Discard", systemImage: "arrow.uturn.backward") {
                    store.keyToDiscard = key.key
                    store.featureToDiscard = feature
                    store.showDiscardKeyConfirmation = true
                }
            }

            // Delete Localization option (always available when not on protected branch)
            if !store.isOnProtectedBranch {
                if changeStatus != .unchanged {
                    Divider()
                }
                Button("Delete Localization", systemImage: "trash", role: .destructive) {
                    store.localizationKeyToDelete = (keyName: key.key, feature: feature)
                    store.showDeleteLocalizationConfirmation = true
                }
            }
        }
    }
}

#Preview {
    LocalizationBrowserView()
        .environment(AppStore())
        .frame(width: 280, height: 600)
}
