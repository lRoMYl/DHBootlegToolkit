import SwiftUI

/// Generic error alert for publish failures
struct GitPublishErrorAlert<Store: GitPublishable>: ViewModifier {
    let store: Store

    func body(content: Content) -> some View {
        @Bindable var store = store

        content
            .alert("Error", isPresented: $store.showPublishError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.publishErrorMessage ?? "An unknown error occurred.")
            }
    }
}

extension View {
    func gitPublishErrorAlert<Store: GitPublishable>(store: Store) -> some View {
        modifier(GitPublishErrorAlert(store: store))
    }
}
