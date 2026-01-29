# JSONEditorCore

Order-preserving JSON editing with minimal diffs for configuration editors.

## Overview

JSONEditorCore provides JSON serialization and editing capabilities that preserve key order and minimize git diffs. Perfect for building configuration editors that need to maintain exact JSON formatting.

## Features

- **JSONSerializer**: Order-preserving JSON serialization
- **JSONDocument**: Generic document model with change tracking
- **JSONEditOperation**: Type-safe edit operations
- **ValidationResult**: Validation error reporting
- **JSONEditable**: Protocol for editable documents

## Installation

Add JSONEditorCore to your Swift package:

```swift
dependencies: [
    .package(path: "../JSONEditorCore")
]
```

## Usage

### Order-Preserving Serialization

```swift
import JSONEditorCore

let json: [String: Any] = [
    "name": "John",
    "age": 30,
    "city": "NYC"
]

let originalContent = """
{
  "name": "John",
  "age": 30,
  "city": "NYC"
}
"""

// Serializes JSON while preserving key order from original
let serialized = JSONSerializer.serialize(json, preservingOrderFrom: originalContent)

// Replace a single value with minimal diff
let updated = JSONSerializer.replaceValue(
    in: originalContent,
    at: ["age"],
    with: 31
)
// Only the "age" line changes, everything else stays the same
```

### Using JSONDocument

```swift
let data = try Data(contentsOf: configURL)
let document = try JSONDocument(url: configURL, data: data)

// Update a value
if let updated = document.withUpdatedValue(true, at: ["features", "darkMode"]) {
    // Save to disk
    if let data = updated.serialize() {
        try data.write(to: configURL)
    }
}

// Check if document has unsaved changes
if document.hasChanges {
    print("Document has been modified")
}
```

### Edit Operations

```swift
import JSONEditorCore

let operation = JSONEditOperation.setValue(
    path: ["user", "preferences", "theme"],
    value: "dark"
)

if let updated = operation.apply(to: json) {
    // JSON updated successfully
}
```

## Key Features

### Minimal Git Diffs

JSONSerializer only modifies the specific lines that change, preserving:
- Key order
- Indentation (auto-detected: 2 spaces, 4 spaces, or tabs)
- Whitespace
- Comment-like structures (if any)

### Change Tracking

JSONDocument automatically tracks:
- Whether document has unsaved changes
- Original content for comparison
- Edited paths for UI indicators

## Requirements

- macOS 15.0+
- Swift 6.0+

## License

See LICENSE file.
