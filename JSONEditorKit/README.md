# JSONEditorKit

Complete JSON editor framework combining Git operations, JSON editing, and SwiftUI components.

## Overview

JSONEditorKit combines GitCore, JSONEditorCore, and JSONEditorUI into a single package with coordinator patterns and integration helpers. Perfect for building configuration editors with git integration.

## Features

- **Re-exports all dependencies**: GitCore + JSONEditorCore + JSONEditorUI
- **EditorCoordinator**: Protocol combining git and document management
- **DocumentManager**: Helper for batch operations and validation
- **Default implementations**: Minimal code to get started

## Installation

Add JSONEditorKit to your Swift package:

```swift
dependencies: [
    .package(path: "../JSONEditorKit")
]
```

JSONEditorKit automatically includes:
- GitCore
- JSONEditorCore
- JSONEditorUI

## Usage

### Complete Editor Example

```swift
import JSONEditorKit
import SwiftUI

@Observable
@MainActor
final class ConfigStore: EditorCoordinator {
    typealias Document = ConfigFile

    // Required properties
    var gitWorker: GitWorker?
    var gitStatus: GitStatus = .unconfigured
    var documents: [ConfigFile] = []
    var selectedDocument: ConfigFile?
    var searchText: String = ""
    var isLoading: Bool = false

    // Required methods (for PR generation)
    func generateCommitMessage() -> String {
        let modified = documents.filter { $0.hasChanges }
        return "Update \(modified.count) config file(s)"
    }

    func generatePRTitle() -> String {
        "Configuration updates"
    }

    func generatePRBody() -> String {
        let files = documents.filter { $0.hasChanges }.map { "- \($0.fileName)" }
        return "Modified files:\n" + files.joined(separator: "\n")
    }

    // Custom loading logic
    func loadAllConfigs() async throws {
        isLoading = true
        defer { isLoading = false }

        // Load files from directory
        let configURLs = DocumentManager<ConfigFile>().findJSONFiles(in: configDirectory)

        documents = try configURLs.compactMap { url in
            let data = try Data(contentsOf: url)
            return try ConfigFile(url: url, data: data)
        }
    }
}

// Your document type
struct ConfigFile: JSONEditable {
    let id: UUID
    let url: URL
    var content: [String: Any]
    var originalContent: String?

    var hasChanges: Bool {
        guard let original = originalContent else { return false }
        // Use JSONSerializer for comparison
        return serialize() != original.data(using: .utf8)
    }

    func withUpdatedValue(_ value: Any, at path: [String]) -> ConfigFile? {
        // Implement update logic
        // Use JSONEditorCore's helpers
    }

    func serialize() -> Data? {
        guard let original = originalContent else { return nil }
        return JSONSerializer.serialize(content, preservingOrderFrom: original).data(using: .utf8)
    }
}
```

### Using in SwiftUI

```swift
struct ConfigEditorView: View {
    @Environment(ConfigStore.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar with file list
            List(selection: $store.selectedDocument) {
                ForEach(store.documents) { doc in
                    Text(doc.fileName)
                        .badge(doc.hasChanges ? "●" : "")
                }
            }
            .frame(width: 250)

            // JSON editor
            if let doc = store.selectedDocument {
                JSONTreeView(
                    json: doc.content,
                    path: [],
                    onValueChange: { path, value in
                        store.updateSelectedDocument(at: path, value: value)
                    }
                )
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Create PR") {
                    Task {
                        try? await store.saveAllModifiedDocuments()
                        _ = try? await store.publish()
                    }
                }
                .disabled(!store.canPublish)
            }
        }
    }
}
```

## Provided Defaults

The **EditorCoordinator** protocol provides default implementations for:

- `updateValue(in:at:value:)` - Delegates to document
- `saveDocument(_:)` - Serializes and writes to disk
- `saveAllModifiedDocuments()` - Saves all changed documents
- `replaceDocument(_:)` - Updates document in array
- `updateSelectedDocument(at:value:)` - Updates current selection
- `canPublish` - Computed property (hasChanges && isReady)
- `refreshGitStatus()` - Updates git status
- `publish()` - Creates PR (inherited from GitPublishable)

## Helpers

### DocumentManager

```swift
let manager = DocumentManager<ConfigFile>()

// Batch update multiple documents
let updated = manager.batchUpdate(
    documents,
    at: ["feature", "enabled"],
    value: true
)

// Filter by search
let filtered = manager.filterDocuments(
    documents,
    searchText: "staging"
)

// Group by directory
let grouped = manager.groupDocuments(documents) { url in
    url.deletingLastPathComponent().lastPathComponent
}

// Find JSON files
let files = manager.findJSONFiles(in: directory)

// Validate documents
let errors = manager.validateDocuments(documents)
```

## Requirements

- macOS 15.0+
- Swift 6.0+
- SwiftUI

## Dependencies

- GitCore
- JSONEditorCore
- JSONEditorUI

## License

See LICENSE file.
