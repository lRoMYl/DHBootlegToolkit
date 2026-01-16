import SwiftUI
import DHBootlegToolkitCore

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(StockTickerStore.self) private var stockTickerStore
    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            Section("Repository") {
                if let repoURL = store.repositoryURL {
                    LabeledContent("Current Repository") {
                        Text(repoURL.path)
                            .foregroundStyle(.secondary)
                    }

                    Button("Change Repository...") {
                        store.showRepositoryPicker()
                    }
                } else {
                    Text("No repository selected")
                        .foregroundStyle(.secondary)

                    Button("Select Repository...") {
                        store.showRepositoryPicker()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("Git Configuration") {
                if store.gitStatus.isConfigured {
                    LabeledContent("User Name") {
                        Text(store.gitStatus.userName ?? "Not set")
                    }

                    LabeledContent("Email") {
                        Text(store.gitStatus.userEmail ?? "Not set")
                    }

                    LabeledContent("Current Branch") {
                        Text(store.gitStatus.currentBranch ?? "None")
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

            Section("Reset") {
                HStack {
                    Button("Clear Stock Cache") {
                        clearStockCache()
                        stockTickerStore.clearCache()
                    }

                    Button("Clear Repository Settings") {
                        clearRepositorySettings()
                    }
                }

                Button("Reset All Settings...", role: .destructive) {
                    showResetConfirmation = true
                }
            }

            Section("About") {
                LabeledContent("App Version") {
                    Text("1.0.0")
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
        .environment(StockTickerStore())
}
