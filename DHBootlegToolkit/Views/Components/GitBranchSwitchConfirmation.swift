import SwiftUI

/// Generic confirmation dialog for branch switching with uncommitted changes
struct GitBranchSwitchConfirmation<Store: GitPublishable>: ViewModifier {
    let store: Store
    let editorName: String

    func body(content: Content) -> some View {
        @Bindable var store = store

        content
            .confirmationDialog(
                "Unsaved Changes",
                isPresented: $store.showUncommittedChangesConfirmation,
                presenting: store.pendingBranchSwitch
            ) { targetBranch in
                // Only show "Save & Switch" if not on a protected branch
                if !store.gitStatus.isOnProtectedBranch {
                    Button("Save & Switch") {
                        Task {
                            if let error = await store.commitAndSwitchBranch() {
                                store.publishErrorMessage = error
                                store.showPublishError = true
                            }
                        }
                    }
                }

                // Show "Discard & Switch" option
                Button("Discard & Switch", role: .destructive) {
                    Task {
                        if let error = await store.discardAndSwitchBranch() {
                            store.publishErrorMessage = error
                            store.showPublishError = true
                        }
                    }
                }

                Button("Cancel", role: .cancel) {
                    store.cancelBranchSwitch()
                }
            } message: { targetBranch in
                if store.gitStatus.isOnProtectedBranch {
                    Text("You have uncommitted \(editorName) changes on protected branch '\(store.gitStatus.currentBranch ?? "")'. You must discard them before switching to '\(targetBranch)'.")
                } else {
                    Text("You have uncommitted \(editorName) changes. Save them before switching to '\(targetBranch)'?")
                }
            }
    }
}

extension View {
    func gitBranchSwitchConfirmation<Store: GitPublishable>(store: Store, editorName: String) -> some View {
        modifier(GitBranchSwitchConfirmation(store: store, editorName: editorName))
    }
}
