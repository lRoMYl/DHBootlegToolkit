import SwiftUI
import DHBootlegToolkitCore

struct SettingsView: View {
    @Environment(AppStore.self) private var store

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
        .frame(width: 450, height: 350)
    }
}

#Preview {
    SettingsView()
        .environment(AppStore())
}
