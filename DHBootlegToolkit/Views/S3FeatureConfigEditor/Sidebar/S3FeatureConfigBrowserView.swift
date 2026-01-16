import SwiftUI
import DHBootlegToolkitCore

// MARK: - S3 Feature Config Browser View

/// Main sidebar view for browsing S3 feature configurations
struct S3FeatureConfigBrowserView: View {
    @Environment(S3Store.self) private var store

    var body: some View {
        @Bindable var store = store

        Group {
            if store.s3RepositoryURL == nil {
                S3RepositoryPrompt()
            } else if store.isLoading {
                VStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading configurations...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.errorMessage {
                S3RepositoryError(errorMessage: error)
            } else {
                List(selection: Binding(
                    get: { store.selectedCountry?.id },
                    set: { id in
                        if let id, let country = store.countries.first(where: { $0.id == id }) {
                            store.selectCountry(country)
                        }
                    }
                )) {
                    // Environment section (header-only with toggle)
                    Section {
                        EmptyView()
                    } header: {
                        HStack {
                            Text("Environment")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .textCase(nil)

                            Spacer()

                            S3EnvironmentToggle()
                        }
                    }

                    // Brand-grouped countries sections
                    if store.groupedCountries.isEmpty {
                        Section {
                            if !store.searchText.isEmpty {
                                Text("No matching countries")
                                    .foregroundStyle(.secondary)
                                    .listRowBackground(Color.clear)
                            } else {
                                Text("No country configurations found")
                                    .foregroundStyle(.secondary)
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text("Countries")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    } else {
                        ForEach(store.groupedCountries) { group in
                            Section {
                                ForEach(group.countries) { country in
                                    S3CountryRow(country: country)
                                        .tag(country.id)
                                }
                            } header: {
                                Text(group.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if store.hasRepository {
                    // Save All button - hidden on protected branches
                    if store.hasUnsavedChanges && !store.isOnProtectedBranch {
                        Button {
                            Task {
                                do {
                                    try await store.saveAllChanges()
                                } catch {
                                    store.saveErrorMessage = error.localizedDescription
                                    store.showSaveError = true
                                }
                            }
                        } label: {
                            Label("Save All", systemImage: "square.and.arrow.down")
                        }
                        .help("Save all changes")
                    }
                }
            }
        }
    }
}

// MARK: - S3 Repository Prompt

/// Prompt view shown when no S3 repository is selected
struct S3RepositoryPrompt: View {
    @Environment(S3Store.self) private var store

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "cloud")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Select S3 Repository")
                    .font(.headline)

                Text("Choose a local repository containing S3 feature configurations")
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
        panel.message = "Select the root of your S3 config repository"

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await store.loadRepository(at: url)
            }
        }
    }
}

// MARK: - S3 Repository Error

/// Error view shown when S3 repository validation fails
struct S3RepositoryError: View {
    @Environment(S3Store.self) private var store
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
        panel.message = "Select the root of your S3 config repository"

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await store.loadRepository(at: url)
            }
        }
    }
}

#Preview {
    S3FeatureConfigBrowserView()
        .environment(S3Store())
        .frame(width: 280, height: 600)
}
