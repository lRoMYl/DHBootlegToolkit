# JSONEditorUI

SwiftUI components for displaying and editing JSON with tree view.

## Overview

JSONEditorUI provides ready-to-use SwiftUI components for building JSON editors. Includes a recursive tree view, type badges, field editors, and modal sheets for adding/inserting elements.

## Features

- **JSONTreeView**: Recursive tree view with expand/collapse
- **TypeBadge**: Visual type indicators (string, int, bool, object, array)
- **Type-specific Editors**: Inline editors for strings, numbers, booleans
- **AddFieldSheet**: Modal for adding new JSON fields
- **InsertArrayElementSheet**: Modal for inserting array elements

## Installation

Add JSONEditorUI to your Swift package:

```swift
dependencies: [
    .package(path: "../JSONEditorUI")
]
```

## Usage

### Basic Tree View

```swift
import SwiftUI
import JSONEditorUI

struct ConfigEditorView: View {
    let json: [String: Any]
    @State private var expandedPaths: Set<String> = []

    var body: some View {
        JSONTreeView(
            json: json,
            path: [],
            expandedPaths: expandedPaths,
            onValueChange: { path, newValue in
                print("Updated \(path.joined(separator: ".")) to \(newValue)")
            }
        )
    }
}
```

### With Add/Delete Callbacks

```swift
JSONTreeView(
    json: json,
    path: [],
    onValueChange: { path, value in
        handleValueChange(path, value)
    },
    onAddField: { parentPath in
        showAddFieldSheet(for: parentPath)
    },
    onDeleteField: { path in
        handleDelete(at: path)
    }
)
```

### Type Badges

```swift
import JSONEditorUI

// Infer type from value
TypeBadge.from(value: "hello")      // Shows "str" badge
TypeBadge.from(value: 42)           // Shows "int" badge
TypeBadge.from(value: true)         // Shows "bool" badge

// Explicit type
TypeBadge.string()
TypeBadge.int()
TypeBadge.bool()
TypeBadge.object()
```

### Add Field Sheet

```swift
@State private var showAddField = false
@State private var selectedParentPath: [String] = []

var body: some View {
    Button("Add Field") {
        showAddField = true
    }
    .sheet(isPresented: $showAddField) {
        AddFieldSheet(parentPath: selectedParentPath) { key, type, value in
            addField(key: key, type: type, value: value)
        }
    }
}
```

### Insert Array Element Sheet

```swift
@State private var showInsert = false

var body: some View {
    Button("Insert Element") {
        showInsert = true
    }
    .sheet(isPresented: $showInsert) {
        InsertArrayElementSheet(
            arrayPath: ["items"],
            currentArray: items
        ) { type, value, index in
            insertElement(type: type, value: value, at: index)
        }
    }
}
```

## Components

### JSONTreeView

Recursive tree view that displays JSON with:
- Expand/collapse for objects and arrays
- Inline editing for primitive values
- Type badges for each field
- Search highlighting
- Context actions (add, delete)

**Props:**
- `json: [String: Any]` - JSON to display
- `path: [String]` - Current path (empty for root)
- `expandedPaths: Set<String>` - Paths to expand
- `onValueChange: ([String], Any) -> Void` - Value change callback
- `onAddField: (([String]) -> Void)?` - Add field callback
- `onDeleteField: (([String]) -> Void)?` - Delete field callback

### TypeBadge

Visual indicator for JSON value types:
- `str` (green) - String
- `int` (purple) - Integer
- `float` (purple) - Float
- `bool` (orange) - Boolean
- `{obj}` (blue) - Object
- `[arr]` (indigo) - Array

## Requirements

- macOS 15.0+
- Swift 6.0+
- SwiftUI

## Dependencies

- JSONEditorCore (for path utilities)

## License

See LICENSE file.
