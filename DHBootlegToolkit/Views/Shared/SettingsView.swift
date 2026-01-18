import SwiftUI
import AppKit
import DHBootlegToolkitCore

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(S3Store.self) private var s3Store
    @Environment(StockTickerStore.self) private var stockTickerStore
    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            Section("Repositories") {
                // Localization Repository
                LabeledContent {
                    VStack(alignment: .trailing, spacing: 6) {
                        if let repoURL = store.repositoryURL {
                            Text(repoURL.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: 250, alignment: .trailing)

                            Button("Change...") {
                                store.showRepositoryPicker()
                            }
                            .controlSize(.small)
                        } else {
                            Button("Select...") {
                                store.showRepositoryPicker()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                } label: {
                    Text("Localization")
                }

                // S3 Config Repository
                LabeledContent {
                    VStack(alignment: .trailing, spacing: 6) {
                        if let repoURL = s3Store.s3RepositoryURL {
                            Text(repoURL.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: 250, alignment: .trailing)

                            Button("Change...") {
                                selectS3Repository()
                            }
                            .controlSize(.small)
                        } else {
                            Button("Select...") {
                                selectS3Repository()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                } label: {
                    Text("S3 Config")
                }
            }

            Section("Maintenance") {
                Button("Clear Stock Cache") {
                    clearStockCache()
                    stockTickerStore.clearCache()
                }

                Button("Clear Repository Settings") {
                    clearRepositorySettings()
                }

                Button("Reset All Settings...") {
                    showResetConfirmation = true
                }
                .foregroundStyle(.red)
            }

            Section("Git Configuration") {
                if store.gitStatus.isConfigured {
                    LabeledContent("User Name") {
                        Text(store.gitStatus.userName ?? "Not set")
                    }

                    LabeledContent("Email") {
                        Text(store.gitStatus.userEmail ?? "Not set")
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Git is not configured")
                            .foregroundStyle(.orange)

                        Text("Run these commands in Terminal:")
                            .font(.caption)

                        Text("""
                            git config --global user.name "Your Name"
                            git config --global user.email "you@example.com"
                            """)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }

            Section("About") {
                LabeledContent("App Version") {
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text("\(version) (\(build))")
                    } else {
                        Text("Unknown")
                    }
                }

                LabeledContent("macOS Version") {
                    Text(ProcessInfo.processInfo.operatingSystemVersionString)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
        .alert("Reset All Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text("This will clear all cached data and settings. The app will restart.")
        }
    }

    // MARK: - Repository Selection

    private func selectS3Repository() {
        let panel = NSOpenPanel()
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the root of your S3 config repository"

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await s3Store.loadRepository(at: url)
            }
        }
    }

    // MARK: - Reset Functions

    private func clearStockCache() {
        let defaults = UserDefaults.standard
        for symbol in ["DHER.DE", "TALABAT.AE"] {
            defaults.removeObject(forKey: "stock_\(symbol)")
            defaults.removeObject(forKey: "sentiment_\(symbol)")
        }
        defaults.removeObject(forKey: "selectedChartRange")
    }

    private func clearRepositorySettings() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "lastRepositoryURL")
        defaults.removeObject(forKey: "lastS3RepositoryURL")
    }

    private func resetAllSettings() {
        clearStockCache()
        clearRepositorySettings()
        UserDefaults.standard.removeObject(forKey: "selectedSidebarTab")

        // Restart the app
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()

        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    SettingsView()
        .environment(AppStore())
        .environment(S3Store())
        .environment(StockTickerStore())
}
