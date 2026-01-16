import SwiftUI

/// "Create PR" toolbar button that works with any GitPublishable store
struct GitPublishToolbarButton: View {
    let store: any GitPublishable
    let helpText: String

    var body: some View {
        Button {
            Task { await store.publish() }
        } label: {
            Label("Create PR", systemImage: "arrow.up.circle")
        }
        .labelStyle(.titleAndIcon)
        .buttonStyle(.bordered)
        .disabled(!store.canPublish)
        .help(helpText)
    }
}
