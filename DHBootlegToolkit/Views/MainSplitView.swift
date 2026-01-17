import SwiftUI
import DHBootlegToolkitCore

struct MainSplitView: View {
    @Environment(AppStore.self) private var store
    @Environment(S3Store.self) private var s3Store
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedSidebarTab: SidebarTab = {
        if let saved = UserDefaults.standard.string(forKey: MainSplitView.selectedModuleKey),
           let tab = SidebarTab(rawValue: saved) {
            return tab
        }
        return .stockTicker  // Default for first launch
    }()
    @State private var showCommitSheet = false

    // UserDefaults key for module selection persistence
    private static let selectedModuleKey = "selectedSidebarTab"

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView(selectedTab: $selectedSidebarTab)
            } detail: {
                switch selectedSidebarTab {
                case .stockTicker:
                    StockTickerDetailView()
                case .editor:
                    DetailTabView()
                case .logs:
                    LogsPlaceholderView()
                case .s3Editor:
                    S3DetailView()
                }
            }
            .navigationTitle(selectedSidebarTab.detailTitle)
            .toolbar(id: "git-toolbar") {
                toolbarContent()
            }
            .onChange(of: selectedSidebarTab) { _, newTab in
                UserDefaults.standard.set(newTab.rawValue, forKey: Self.selectedModuleKey)
            }
            .overlay {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .sheet(isPresented: $store.showCreateBranchPrompt) {
                CreateBranchSheet()
            }
            .sheet(isPresented: Binding(
                get: { s3Store.showCreateBranchPrompt },
                set: { s3Store.showCreateBranchPrompt = $0 }
            )) {
                S3CreateBranchSheet()
            }
            .sheet(isPresented: $store.showRepositoryPickerDialog) {
                RepositoryPickerSheet()
            }
            .sheet(isPresented: $showCommitSheet) {
                CommitSheet(selectedTab: selectedSidebarTab)
            }
            .modifier(AlertModifiers())
            .modifier(DialogModifiers())

            // Hide git status bar for logs and stock ticker modules
            if selectedSidebarTab != .logs && selectedSidebarTab != .stockTicker {
                GitStatusBar(selectedTab: selectedSidebarTab)
            }
        }
    }

}

// MARK: - Alert Modifiers (extracted to help compiler)

struct AlertModifiers: ViewModifier {
    @Environment(AppStore.self) private var store
    @Environment(S3Store.self) private var s3Store

    func body(content: Content) -> some View {
        @Bindable var store = store
        @Bindable var s3Store = s3Store

        content
            .gitPublishErrorAlert(store: store)
            .gitPublishErrorAlert(store: s3Store)
            .alert("Save Failed", isPresented: $s3Store.showSaveError) {
                Button("OK", role: .cancel) {
                    s3Store.saveErrorMessage = nil
                }
            } message: {
                if let message = s3Store.saveErrorMessage {
                    Text(message)
                }
            }
            .alert("State Management Error", isPresented: $store.showStateManagementError) {
                Button("OK", role: .cancel) {
                    store.stateManagementErrorMessage = nil
                }
            } message: {
                Text(store.stateManagementErrorMessage ?? "An unexpected state error occurred.")
            }
            .alert("Invalid Repository", isPresented: $store.showRepositoryError) {
                Button("Choose Another") {
                    store.showRepositoryPickerDialog = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(store.repositoryErrorMessage ?? "The selected folder is not a valid localization repository.")
            }
            .alert("External Changes Detected", isPresented: $store.showExternalChangeConflict) {
                Button("Reload", role: .destructive) {
                    Task { await store.discardLocalChanges() }
                }
                Button("Keep Mine") {
                    store.keepLocalChanges()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let change = store.pendingExternalChange {
                    Text("\(change.featureName) was modified externally. You have unsaved changes that will be lost if you reload.")
                } else {
                    Text("A file was modified externally. You have unsaved changes.")
                }
            }
    }
}

// MARK: - Dialog Modifiers (extracted to help compiler)

struct DialogModifiers: ViewModifier {
    @Environment(AppStore.self) private var store
    @Environment(S3Store.self) private var s3Store

    func body(content: Content) -> some View {
        content
            .gitBranchSwitchConfirmation(store: store, editorName: "localization")
            .gitBranchSwitchConfirmation(store: s3Store, editorName: "S3 config")
            .modifier(DiscardDialogModifiers())
            .modifier(S3DiscardDialogModifiers())
    }
}

struct DiscardDialogModifiers: ViewModifier {
    @Environment(AppStore.self) private var store

    func body(content: Content) -> some View {
        @Bindable var store = store

        content
            .confirmationDialog(
                "Discard Changes?",
                isPresented: $store.showDiscardKeyConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) {
                    Task {
                        if let keyName = store.keyToDiscard,
                           let feature = store.featureToDiscard {
                            await store.discardKeyChanges(keyName, in: feature)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    store.keyToDiscard = nil
                    store.featureToDiscard = nil
                }
            } message: {
                if let keyName = store.keyToDiscard {
                    Text("Revert \"\(keyName)\" to its last saved state? This cannot be undone.")
                }
            }
            .confirmationDialog(
                "Discard All Changes?",
                isPresented: $store.showDiscardAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard All", role: .destructive) {
                    Task {
                        if let feature = store.featureToDiscard {
                            await store.discardAllChanges(in: feature)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    store.featureToDiscard = nil
                }
            } message: {
                if let feature = store.featureToDiscard {
                    let diff = store.getDiff(for: feature)
                    Text("Discard \(diff.totalChanges) change(s) in \"\(feature.displayName)\"? This cannot be undone.")
                }
            }
            .confirmationDialog(
                "Discard All Changes",
                isPresented: $store.showDiscardRepositoryConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard All", role: .destructive) {
                    Task {
                        await store.discardAllUncommittedChanges()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                let count = store.gitStatus.uncommittedFileCount
                let filesText = count == 1 ? "file" : "files"
                Text("Are you sure you want to discard all changes in \(count) \(filesText)? This action cannot be undone.")
            }
            .modifier(FileDiscardDialogModifiers())
    }
}

struct FileDiscardDialogModifiers: ViewModifier {
    @Environment(AppStore.self) private var store

    private func fileDiscardMessage(_ fileData: (file: FeatureFileItem, feature: FeatureFolder)) -> String {
        switch fileData.file.gitStatus {
        case .added:
            return "Delete \"\(fileData.file.name)\" from disk? This cannot be undone."
        case .deleted:
            return "Restore \"\(fileData.file.name)\" from git? This will restore the file to its last committed state."
        case .modified:
            return "Restore \"\(fileData.file.name)\" to its last committed state? This cannot be undone."
        case .unchanged:
            return ""
        }
    }

    func body(content: Content) -> some View {
        @Bindable var store = store

        content
            .confirmationDialog(
                "Discard File Changes?",
                isPresented: $store.showDiscardFileConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) {
                    Task { await store.discardFileChanges() }
                }
                Button("Cancel", role: .cancel) {
                    store.fileToDiscard = nil
                }
            } message: {
                if let fileData = store.fileToDiscard {
                    Text(fileDiscardMessage(fileData))
                }
            }
            .confirmationDialog(
                "Unsaved Changes",
                isPresented: $store.showCloseTabConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard Changes", role: .destructive) {
                    store.confirmCloseTab()
                }
                Button("Cancel", role: .cancel) {
                    store.cancelCloseTab()
                }
            } message: {
                Text("This tab has unsaved changes. Discard them and close?")
            }
            // Permanent file delete confirmation
            .confirmationDialog(
                "Delete File?",
                isPresented: $store.showDeleteFileConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await store.deleteFile() }
                }
                Button("Cancel", role: .cancel) {
                    store.fileToDelete = nil
                }
            } message: {
                if let fileData = store.fileToDelete {
                    Text("Permanently delete \"\(fileData.file.name)\"? This cannot be undone.")
                }
            }
            // Permanent folder delete confirmation
            .confirmationDialog(
                "Delete Folder?",
                isPresented: $store.showDeleteFolderConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Folder", role: .destructive) {
                    Task { await store.deleteFolder() }
                }
                Button("Cancel", role: .cancel) {
                    store.folderToDelete = nil
                }
            } message: {
                if let folderData = store.folderToDelete {
                    Text("Permanently delete \"\(folderData.folder.name)\" and all its contents? This cannot be undone.")
                }
            }
            // Delete localization key confirmation
            .confirmationDialog(
                "Delete Localization?",
                isPresented: $store.showDeleteLocalizationConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await store.deleteLocalization() }
                }
                Button("Cancel", role: .cancel) {
                    store.localizationKeyToDelete = nil
                }
            } message: {
                if let keyData = store.localizationKeyToDelete {
                    Text("Permanently delete \"\(keyData.keyName)\"? This cannot be undone.")
                }
            }
            .modifier(LifecycleModifiers())
    }
}

struct S3DiscardDialogModifiers: ViewModifier {
    @Environment(S3Store.self) private var s3Store

    func body(content: Content) -> some View {
        @Bindable var s3Store = s3Store

        content
            .confirmationDialog(
                "Discard All Changes",
                isPresented: $s3Store.showDiscardRepositoryConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard All", role: .destructive) {
                    Task {
                        await s3Store.discardAllUncommittedChanges()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                let count = s3Store.gitStatus.uncommittedFileCount
                let filesText = count == 1 ? "file" : "files"
                Text("Are you sure you want to discard all changes in \(count) \(filesText)? This action cannot be undone.")
            }
    }
}

struct LifecycleModifiers: ViewModifier {
    @Environment(AppStore.self) private var store

    func body(content: Content) -> some View {
        content
            .task {
                // Periodic external change detection every 30 seconds
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(30))
                    await store.checkForExternalChanges()
                }
            }
            // REMOVED: No longer auto-show modal prompt on launch
            // Users now select via sidebar button instead
    }
}

// MARK: - Computed Properties

extension MainSplitView {
    /// Returns the current GitPublishable store for the selected tab, if applicable.
    /// Returns nil for tabs without git functionality (Stock Ticker, Logs).
    private var currentGitPublishableStore: (any GitPublishable)? {
        switch selectedSidebarTab {
        case .editor:
            return store
        case .s3Editor:
            return s3Store
        case .stockTicker, .logs:
            return nil
        }
    }
}

// MARK: - Toolbar Content

extension MainSplitView {
    @ToolbarContentBuilder
    private func toolbarContent() -> some CustomizableToolbarContent {
        if let gitStore = currentGitPublishableStore {
            let isS3Mode = selectedSidebarTab == .s3Editor

            // Save/Commit button
            ToolbarItem(id: "save-commit") {
                Button {
                    showCommitSheet = true
                } label: {
                    Label("Commit", systemImage: "plus.circle")
                }
                .labelStyle(.titleAndIcon)
                .help("Commit changes")
                .disabled(!gitStore.gitStatus.hasUncommittedChanges)
            }

            // Pull Latest button
            ToolbarItem(id: "pull-latest") {
                Button {
                    Task {
                        if isS3Mode {
                            await s3Store.pullLatestFromRemote()
                        } else {
                            await store.pullLatestFromRemote()
                        }
                    }
                } label: {
                    Label("Pull", systemImage: "arrow.down.circle")
                }
                .labelStyle(.titleAndIcon)
                .help("Pull latest changes from remote")
                .disabled(store.isLoading || s3Store.isLoading)
                .if(gitStore.gitStatus.commitsBehind > 0) { view in
                    view.badge(gitStore.gitStatus.commitsBehind)
                }
            }

            // Discard All button
            ToolbarItem(id: "discard-all") {
                Button {
                    if isS3Mode {
                        s3Store.showDiscardRepositoryConfirmation = true
                    } else {
                        store.showDiscardRepositoryConfirmation = true
                    }
                } label: {
                    Label("Discard", systemImage: "arrow.uturn.backward.circle")
                }
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.red)
                .help("Discard all uncommitted changes")
                .disabled(!gitStore.gitStatus.hasUncommittedChanges)
            }

            // Create PR button (separated)
            ToolbarItem(id: "create-pr") {
                GitPublishToolbarButton(
                    store: gitStore,
                    helpText: isS3Mode
                        ? "Commit S3 config changes and create PR"
                        : "Push changes and create PR"
                )
            }
        }
    }
}

// MARK: - Git Status Bar (Unified Bottom Bar)

struct GitStatusBar: View {
    let selectedTab: SidebarTab
    @Environment(AppStore.self) private var appStore
    @Environment(S3Store.self) private var s3Store
    @State private var showCreateBranchSheet = false
    @State private var showRenameBranchSheet = false

    // MARK: - Module-Aware Computed Properties

    private var isS3Mode: Bool {
        selectedTab == .s3Editor
    }

    private var activeGitStatus: GitStatus {
        isS3Mode ? s3Store.gitStatus : appStore.gitStatus
    }

    private var activeAvailableBranches: [String] {
        isS3Mode ? s3Store.availableBranches : appStore.availableBranches
    }

    private var activeIsLoadingBranches: Bool {
        isS3Mode ? s3Store.isLoadingBranches : appStore.isLoadingBranches
    }

    private var activeCurrentBranchDisplayName: String {
        isS3Mode ? s3Store.currentBranchDisplayName : appStore.currentBranchDisplayName
    }

    private var activeIsOnProtectedBranch: Bool {
        isS3Mode ? s3Store.isOnProtectedBranch : appStore.isOnProtectedBranch
    }

    var body: some View {
        HStack(spacing: 0) {
            // Git icon
            Image("git-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(.trailing, 12)

            // 1. User info
            userInfoSection

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 12)

            // 3. Branch selector with new branch button
            branchSection

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 12)

            // 4. Uncommitted file count
            uncommittedFilesSection

            Spacer()
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .sheet(isPresented: $showCreateBranchSheet) {
            if isS3Mode {
                S3CreateBranchSheet()
            } else {
                CreateBranchSheet()
            }
        }
        .sheet(isPresented: $showRenameBranchSheet) {
            RenameBranchSheet()
        }
        .task(id: isS3Mode ? s3Store.s3RepositoryURL : appStore.repositoryURL) {
            // Re-run when repository changes (ensures gitWorker is initialized)
            if isS3Mode {
                guard s3Store.s3RepositoryURL != nil else { return }
                await s3Store.loadBranches()
            } else {
                guard appStore.repositoryURL != nil else { return }
                await appStore.loadBranches()
            }
        }
    }

    // MARK: - Sections

    private var userInfoSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.fill")
                .foregroundStyle(.secondary)
                .imageScale(.small)
            Text(activeGitStatus.displayEmail)
                .foregroundStyle(.secondary)
        }
    }

    private var branchSection: some View {
        HStack(spacing: 8) {
            // Branch selector menu
            branchSelectorMenu

            // New branch button - right next to branch selector
            Button {
                showCreateBranchSheet = true
            } label: {
                Image(systemName: "plus")
                    .imageScale(.small)
            }
            .buttonStyle(.borderless)
            .help("Create new branch")
        }
    }

    private var branchSelectorMenu: some View {
        Menu {
            if activeIsLoadingBranches {
                Text("Loading branches...")
            } else {
                // Rename option (if not on protected branch) - only for AppStore mode
                if !isS3Mode && !activeIsOnProtectedBranch {
                    Button {
                        showRenameBranchSheet = true
                    } label: {
                        Label("Rename Branch", systemImage: "pencil")
                    }
                }

                // Switch branch section
                if !activeAvailableBranches.isEmpty {
                    Section("Switch Branch") {
                        ForEach(activeAvailableBranches, id: \.self) { branch in
                            if branch != activeGitStatus.currentBranch {
                                Button {
                                    if isS3Mode {
                                        s3Store.requestBranchSwitch(branch)
                                    } else {
                                        appStore.requestBranchSwitch(branch)
                                    }
                                } label: {
                                    let isProtected = isS3Mode ? s3Store.isProtectedBranch(branch) : appStore.isProtectedBranch(branch)
                                    Label(branch, systemImage: isProtected ? "lock.fill" : "arrow.triangle.branch")
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                if activeIsLoadingBranches {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: activeIsOnProtectedBranch ? "lock.fill" : "arrow.triangle.branch")
                        .imageScale(.small)
                }
                Text(activeCurrentBranchDisplayName)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
                    .foregroundStyle(.tertiary)
            }
        }
        .menuStyle(.borderlessButton)
    }

    private var uncommittedFilesSection: some View {
        UncommittedFilesTrigger(
            uncommittedCount: activeGitStatus.uncommittedFileCount,
            committedCount: activeGitStatus.commitsAhead,
            behindCount: activeGitStatus.commitsBehind,
            files: activeGitStatus.uncommittedFiles,
            commitsAhead: activeGitStatus.commitsAheadDetails,
            commitsBehind: activeGitStatus.commitsBehindDetails,
            hasChanges: activeGitStatus.hasUncommittedChanges
        )
    }
}

// MARK: - Uncommitted Files Trigger (with hover buffer)

struct UncommittedFilesTrigger: View {
    let uncommittedCount: Int
    let committedCount: Int
    let behindCount: Int
    let files: [String]
    let commitsAhead: [GitCommit]
    let commitsBehind: [GitCommit]
    let hasChanges: Bool

    @State private var showPopover = false
    @State private var isHoveringTrigger = false
    @State private var isHoveringPopover = false
    @State private var dismissTask: Task<Void, Never>?

    private var statusText: String {
        var parts: [String] = []

        if committedCount > 0 {
            parts.append("\(committedCount) committed")
        }

        if behindCount > 0 {
            parts.append("\(behindCount) behind")
        }

        if uncommittedCount > 0 {
            parts.append("\(uncommittedCount) uncommitted")
        }

        return parts.joined(separator: " • ")
    }

    private var hasAnyStatus: Bool {
        uncommittedCount > 0 || committedCount > 0 || behindCount > 0
    }

    var body: some View {
        Group {
            if !statusText.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "doc.badge.ellipsis")
                        .foregroundStyle(.secondary)
                        .imageScale(.small)

                    Text(statusText)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
                .onHover { hovering in
                    isHoveringTrigger = hovering
                    updatePopoverState()
                }
                .popover(isPresented: $showPopover, arrowEdge: .top) {
                    GitStatusPopover(
                        uncommittedFiles: files,
                        commitsAhead: commitsAhead,
                        commitsBehind: commitsBehind
                    ) { hovering in
                        isHoveringPopover = hovering
                        updatePopoverState()
                    }
                }
            }
        }
    }

    private func updatePopoverState() {
        dismissTask?.cancel()

        if isHoveringTrigger || isHoveringPopover {
            // Show popover if hovering and has any status
            if hasAnyStatus {
                showPopover = true
            }
        } else {
            // Delay dismiss to allow moving between trigger and popover
            dismissTask = Task {
                try? await Task.sleep(for: .milliseconds(200))
                if !Task.isCancelled && !isHoveringTrigger && !isHoveringPopover {
                    showPopover = false
                }
            }
        }
    }
}

// MARK: - Git Status Popover

struct GitStatusPopover: View {
    let uncommittedFiles: [String]
    let commitsAhead: [GitCommit]
    let commitsBehind: [GitCommit]
    var onHover: ((Bool) -> Void)?

    private func iconForFile(_ file: String) -> (name: String, color: Color) {
        let ext = (file as NSString).pathExtension.lowercased()
        switch ext {
        case "json":
            return ("doc.text", .orange)
        case "png", "jpg", "jpeg", "gif", "webp":
            return ("photo", .blue)
        case "swift":
            return ("swift", .orange)
        case "md":
            return ("doc.richtext", .purple)
        default:
            return ("doc", .secondary)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Git Status")
                    .font(.headline)

                Divider()

                // Section 1: Uncommitted Files
                if !uncommittedFiles.isEmpty {
                    uncommittedFilesSection
                }

                // Section 2: Local Commits (Ahead)
                if !commitsAhead.isEmpty {
                    localCommitsSection
                }

                // Section 3: Remote Commits (Behind)
                if !commitsBehind.isEmpty {
                    remoteCommitsSection
                }

                // Empty state (shouldn't happen due to trigger logic)
                if uncommittedFiles.isEmpty && commitsAhead.isEmpty && commitsBehind.isEmpty {
                    Text("No changes")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
            }
            .padding()
        }
        .frame(minWidth: 400, maxHeight: 400)
        .contentShape(Rectangle())
        .onHover { hovering in
            onHover?(hovering)
        }
    }

    private var uncommittedFilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.badge.ellipsis")
                    .foregroundStyle(.orange)
                Text("Uncommitted Files (\(uncommittedFiles.count))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                ForEach(uncommittedFiles, id: \.self) { file in
                    let icon = iconForFile(file)
                    HStack(spacing: 6) {
                        Image(systemName: icon.name)
                            .foregroundStyle(icon.color)
                            .imageScale(.small)
                        Text(file)
                            .font(.callout)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var localCommitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.green)
                Text("Local Commits (\(commitsAhead.count)) - Ready to Push")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(commitsAhead) { commit in
                    commitRow(commit, icon: "circle.fill", color: .blue)
                }
            }
        }
    }

    private var remoteCommitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
                Text("Remote Commits (\(commitsBehind.count)) - Available to Pull")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(commitsBehind) { commit in
                    commitRow(commit, icon: "circle.fill", color: .purple)
                }
            }
        }
    }

    private func commitRow(_ commit: GitCommit, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.small)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(commit.shortHash)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(commit.message)
                        .font(.callout)
                        .lineLimit(2)
                }

                Text("\(commit.author) • \(commit.relativeTime)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Repository Picker Sheet

struct RepositoryPickerSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Localization Repository")
                .font(.headline)

            Text("Choose the root folder of your localization repository")
                .foregroundStyle(.secondary)

            Button("Choose Folder...") {
                let panel = NSOpenPanel()
                panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.message = "Select the localization repository folder"

                if panel.runModal() == .OK, let url = panel.url {
                    Task {
                        await store.selectRepository(url)
                        dismiss()
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(width: 400)
    }
}

// MARK: - Create Branch Sheet

struct CreateBranchSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var branchName = "feature/"
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showSwitchConfirmation = false
    @State private var existingBranchName: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Branch")
                .font(.headline)

            if store.isOnProtectedBranch {
                VStack(alignment: .leading, spacing: 12) {
                    // Explain why branch is needed
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.orange)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("The main branch is protected")
                                .fontWeight(.medium)
                            Text("To add or edit translations, create a feature branch first. This keeps the main branch safe and allows your changes to be reviewed before merging.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: 320, alignment: .leading)

                }
                .font(.callout)
            } else {
                // Creating from a feature branch - explain it will branch from main
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create new branch")
                            .fontWeight(.medium)
                        Text("This will create a new branch from your current branch.")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.callout)
                .frame(maxWidth: 320, alignment: .leading)
            }

            TextField("Branch name", text: $branchName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .disabled(isCreating)

            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .frame(maxWidth: 300)
            }

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .disabled(isCreating)

                Button("Create") {
                    createBranch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(branchName.isEmpty || branchName == "feature/" || isCreating)
            }

            if isCreating {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(40)
        .frame(width: 400)
        .interactiveDismissDisabled(isCreating)
        .onDisappear {
            // Clear pending state if sheet is dismissed without successful branch creation
            // (successful cases clear this before dismiss and open the tab)
            store.pendingAddNewKeyFeature = nil
        }
        .confirmationDialog(
            "Branch Already Exists",
            isPresented: $showSwitchConfirmation,
            presenting: existingBranchName
        ) { branch in
            Button("Switch to '\(branch)'") {
                Task {
                    isCreating = true
                    if let error = await store.switchToBranch(branch) {
                        errorMessage = error
                    } else {
                        let pendingFeature = store.pendingAddNewKeyFeature
                        store.pendingAddNewKeyFeature = nil
                        dismiss()
                        if let feature = pendingFeature {
                            store.openNewKeyTab(for: feature)
                        }
                    }
                    isCreating = false
                }
            }
            Button("Use Different Name", role: .cancel) {
                // Let user edit the name
            }
        } message: { branch in
            Text("A branch named '\(branch)' already exists. Would you like to switch to it?")
        }
    }

    private func createBranch() {
        errorMessage = nil
        isCreating = true
        Task {
            // Create new branch from current branch
            let result = await store.createBranchFromMain(branchName)

            switch result {
            case .success:
                let pendingFeature = store.pendingAddNewKeyFeature
                store.pendingAddNewKeyFeature = nil
                dismiss()
                if let feature = pendingFeature {
                    store.openNewKeyTab(for: feature)
                }
            case .error(let message):
                errorMessage = message
            case .branchExists(let name):
                existingBranchName = name
                showSwitchConfirmation = true
            }
            isCreating = false
        }
    }
}

// MARK: - Rename Branch Sheet

struct RenameBranchSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""
    @State private var isRenaming = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Rename Branch")
                .font(.headline)

            TextField("New branch name", text: $newName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .disabled(isRenaming)
                .onAppear { newName = store.gitStatus.currentBranch ?? "" }

            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                }
                .font(.callout)
            }

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .disabled(isRenaming)

                Button("Rename") {
                    errorMessage = nil
                    isRenaming = true
                    Task {
                        if let error = await store.renameBranch(to: newName) {
                            errorMessage = error
                        } else {
                            dismiss()
                        }
                        isRenaming = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newName.isEmpty || isRenaming)
            }

            if isRenaming {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(40)
        .frame(width: 400)
        .interactiveDismissDisabled(isRenaming)
    }
}

// MARK: - S3 Create Branch Sheet

struct S3CreateBranchSheet: View {
    @Environment(S3Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var branchName = "feature/"
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showSwitchConfirmation = false
    @State private var existingBranchName: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Branch")
                .font(.headline)

            if store.isOnProtectedBranch {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.orange)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("The main branch is protected")
                                .fontWeight(.medium)
                            Text("To edit S3 configurations, create a feature branch first.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: 320, alignment: .leading)

                }
                .font(.callout)
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create new branch")
                            .fontWeight(.medium)
                        Text("This will create a new branch from your current branch.")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.callout)
                .frame(maxWidth: 320, alignment: .leading)
            }

            TextField("Branch name", text: $branchName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .disabled(isCreating)

            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .frame(maxWidth: 300)
            }

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .disabled(isCreating)

                Button("Create") {
                    createBranch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(branchName.isEmpty || branchName == "feature/" || isCreating)
            }

            if isCreating {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(40)
        .frame(width: 400)
        .interactiveDismissDisabled(isCreating)
        .confirmationDialog(
            "Branch Already Exists",
            isPresented: $showSwitchConfirmation,
            presenting: existingBranchName
        ) { branch in
            Button("Switch to '\(branch)'") {
                Task {
                    isCreating = true
                    if let error = await store.switchToBranch(branch) {
                        errorMessage = error
                    } else {
                        dismiss()
                    }
                    isCreating = false
                }
            }
            Button("Use Different Name", role: .cancel) {}
        } message: { branch in
            Text("A branch named '\(branch)' already exists. Would you like to switch to it?")
        }
    }

    private func createBranch() {
        errorMessage = nil
        isCreating = true
        Task {
            let result = await store.createBranchFromMain(branchName)

            switch result {
            case .success:
                dismiss()
            case .error(let message):
                errorMessage = message
            case .branchExists(let name):
                existingBranchName = name
                showSwitchConfirmation = true
            }
            isCreating = false
        }
    }
}

// MARK: - Commit Sheet

struct CommitSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(S3Store.self) private var s3Store
    @Environment(\.dismiss) private var dismiss
    let selectedTab: SidebarTab

    @State private var commitMessage = ""
    @State private var isCommitting = false
    @State private var errorMessage: String?

    private var gitStore: (any GitPublishable)? {
        switch selectedTab {
        case .editor:
            return store
        case .s3Editor:
            return s3Store
        case .stockTicker, .logs:
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Commit Changes")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Commit Message")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $commitMessage)
                    .font(.body)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .disabled(isCommitting)
            }
            .frame(width: 400)

            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .frame(maxWidth: 400)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .disabled(isCommitting)

                Button("Commit") {
                    performCommit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCommitting)
            }

            if isCommitting {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(40)
        .frame(width: 480)
        .interactiveDismissDisabled(isCommitting)
        .onAppear {
            // Pre-populate with auto-generated commit message
            if let gitStore {
                commitMessage = gitStore.generateCommitMessage()
            }
        }
    }

    private func performCommit() {
        guard let gitStore, let gitWorker = gitStore.gitWorker else { return }

        errorMessage = nil
        isCommitting = true

        Task {
            do {
                try await gitWorker.commitAll(message: commitMessage)
                await gitStore.refreshAfterGitOperation()
                dismiss()
            } catch {
                errorMessage = "Failed to commit: \(error.localizedDescription)"
            }
            isCommitting = false
        }
    }
}

// MARK: - Logs Placeholder View

struct LogsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.plaintext")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Logs Module")
                .font(.title2)
                .fontWeight(.medium)

            Text("Coming soon")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainSplitView()
        .environment(AppStore())
        .environment(S3Store())
        .frame(width: 1200, height: 800)
}
