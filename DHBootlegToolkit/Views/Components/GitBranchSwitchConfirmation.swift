import SwiftUI

/// Generic confirmation dialog for branch switching when git fails due to uncommitted changes
struct GitBranchSwitchConfirmation<Store: GitPublishable>: ViewModifier {
    let store: Store
    let editorName: String

    func body(content: Content) -> some View {
        @Bindable var store = store

        content
            .confirmationDialog(
                "Cannot Switch Branch",
                isPresented: $store.showUncommittedChangesConfirmation,
                presenting: store.pendingBranchSwitch
            ) { targetBranch in
                Button("Discard Changes & Switch", role: .destructive) {
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
                if let rawError = store.pendingBranchSwitchError {
                    Text("Git cannot switch to '\(targetBranch)' because you have local changes that would be overwritten.\n\nDiscard changes to proceed?\n\nDetails: \(rawError)")
                } else {
                    Text("Git cannot switch to '\(targetBranch)' because you have local changes. Discard them to proceed?")
                }
            }
    }
}

extension View {
    func gitBranchSwitchConfirmation<Store: GitPublishable>(store: Store, editorName: String) -> some View {
        modifier(GitBranchSwitchConfirmation(store: store, editorName: editorName))
    }
}
