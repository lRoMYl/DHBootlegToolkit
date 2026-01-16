import SwiftUI
import DHBootlegToolkitCore

struct TranslationListView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Group {
            if store.selectedFeature == nil {
                ContentUnavailableView(
                    "Select a Feature",
                    systemImage: "folder",
                    description: Text("Choose a feature folder from the sidebar")
                )
            } else if store.translationKeys.isEmpty {
                ContentUnavailableView(
                    "No Translation Keys",
                    systemImage: "doc.text",
                    description: Text("This feature has no translation keys yet.\nClick + to add one.")
                )
            } else {
                List(selection: Binding(
                    get: { store.selectedKey },
                    set: { key in
                        if let key, let feature = store.selectedFeature {
                            store.openKeyTab(key, in: feature)
                        }
                    }
                )) {
                    ForEach(store.translationKeys) { key in
                        TranslationKeyRowView(key: key)
                            .tag(key)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.deleteKey(store.translationKeys[index])
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(store.selectedFeature?.displayName ?? "Translation Keys")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if let feature = store.selectedFeature {
                        store.openNewKeyTab(for: feature)
                    }
                } label: {
                    Label("Add Key", systemImage: "plus")
                }
                .disabled(store.selectedFeature == nil)
            }
        }
    }
}

struct TranslationKeyRowView: View {
    let key: TranslationKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key.key)
                .font(.headline)
                .lineLimit(1)

            Text(key.translation.isEmpty ? "No translation" : key.translation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                if !key.isValid {
                    Label("Incomplete", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                if let charLimit = key.charLimit {
                    Text("Max \(charLimit) chars")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let languages = key.targetLanguages, !languages.isEmpty {
                    Text("\(languages.count) languages")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TranslationListView()
        .environment(AppStore())
        .frame(width: 350)
}
