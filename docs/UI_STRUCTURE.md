# UI Structure

> **Navigation:** [← Back to README](../README.md) | [Architecture](ARCHITECTURE.md) | [Modules](MODULES.md) | [Development](DEVELOPMENT.md)

This document describes the UI hierarchy, component architecture, and native window integration in DHBootlegToolkit.

## Table of Contents

- [Application Layout](#application-layout)
- [View Hierarchy](#view-hierarchy)
- [Component Architecture](#component-architecture)
- [Native Window Integration](#native-window-integration)
- [New UI Components](#new-ui-components)

---

## Application Layout

### Entry Point

**DHBootlegToolkitApp** (`App/DHBootlegToolkitApp.swift`) is the `@main` entry point:

```swift
@main
struct DHBootlegToolkitApp: App {
    var body: some Scene {
        WindowGroup("DH Bootleg Toolkit") {
            MainSplitView()
        }
    }
}
```

### Window Structure

- **Window Title**: "DH Bootleg Toolkit" (static, set in `WindowGroup`)
- **Layout**: Three-pane `NavigationSplitView` (sidebar, content, optional detail)
- **Git Bar**: Shared bottom toolbar across all modules

### Sidebar Navigation

Four module tabs accessible via sidebar:

1. **Market Watch** (`.stockTicker`) - Stock ticker module
2. **Not WebTranslateIt Editor** (`.editor`) - Localization module
3. **S3 Feature Config Editor** (`.s3Editor`) - S3 config module
4. **Logger** (`.logs`) - Logs module (placeholder)

---

## View Hierarchy

### Corrected Hierarchy

The application uses **MainSplitView** as the primary layout container, not ContentView or ModuleSelectionView.

```
DHBootlegToolkitApp (@main entry)
    └── MainSplitView (NavigationSplitView - 3 pane layout)
        ├── Sidebar (left column)
        │   └── SidebarView
        │       ├── Tab: .stockTicker → StockTickerBrowserView
        │       │   └── Stock list with live prices
        │       ├── Tab: .editor → FeatureBrowserView
        │       │   └── Feature tree with file items and git badges
        │       ├── Tab: .s3Editor → S3BrowserView
        │       │   └── Country list with environment toggle
        │       └── Tab: .logs → LogsPlaceholderView
        │           └── Coming soon placeholder
        │
        ├── Detail (center/right) - Dynamic content based on module
        │   ├── When .stockTicker: StockTickerDetailView
        │   │   └── Price card, sentiment thresholds, charts
        │   ├── When .editor: DetailTabView
        │   │   └── Multi-tab translation key editing
        │   ├── When .s3Editor: S3DetailView
        │   │   └── JSON tree editor for configs
        │   └── When .logs: LogsPlaceholderView
        │       └── Empty state
        │
        └── GitStatusBar (bottom toolbar, shared)
            ├── Branch selector dropdown
            ├── Git user info display
            ├── Uncommitted changes count
            └── Create PR / Publish button
```

### Primary Views

| View | Location | Purpose |
|------|----------|---------|
| **MainSplitView** | `Views/MainSplitView.swift` | Primary 3-pane layout with git bar |
| **SidebarView** | `Views/Sidebar/SidebarView.swift` | Tab navigation and module switching |
| **StockTickerBrowserView** | `Views/StockTicker/Sidebar/` | Stock list for market watch |
| **StockTickerDetailView** | `Views/StockTicker/` | Stock detail with charts |
| **FeatureBrowserView** | `Views/LocalizationEditor/` | Feature tree for localization |
| **DetailTabView** | `Views/LocalizationEditor/` | Translation key editor |
| **S3BrowserView** | `Views/S3FeatureConfigEditor/` | Country list for S3 configs |
| **S3DetailView** | `Views/S3FeatureConfigEditor/` | JSON tree editor |

---

## Component Architecture

### Reusable Components

**GitStatusBar** (`Views/Components/GitStatusBar.swift`):
- Bottom toolbar shared across all modules
- **Visibility**: Hidden for logs AND stock ticker modules
- Displays branch, user info, uncommitted changes
- Actions: branch switching, commit, create PR

**JSONSearchBar** (`Views/Components/JSONSearchBar.swift`):
- Search toolbar for JSON editor
- Full-text search across configuration
- Field path search
- Highlight search results in tree

**JSONEditorToolbar** (`Views/Components/JSONEditorToolbar.swift`):
- Editor toolbar for S3 config module
- Quick actions for common operations
- Search integration
- Environment switcher
- Validation status indicator

### Liquid Glass Styling

**Material Effects:**
```swift
.background(.ultraThinMaterial)
```

Used throughout for modern macOS appearance:
- Bottom toolbars (GitStatusBar, TranslationDetailView toolbar)
- Overlay sheets
- Floating panels

**Glow Shadow:**
```swift
.shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 2)
```

Applied to primary action buttons for emphasis.

### Color Coding

**Git Status Badges:**
- Green `[A]` - Added files
- Orange `[M]` - Modified files
- Red `[-]` - Deleted files

**Sentiment Colors:**
- 🚀 Moonshot - Green
- 📈 Gains - Light green
- 😐 Flat - Gray
- 📉 Losses - Light red
- 💥 Crash - Red

---

## Native Window Integration

### Window Title Bar

The app uses native macOS window title bar integration:

- **Window Title**: "DH Bootleg Toolkit" (static, set in `WindowGroup`)
- **Navigation Titles**: Dynamic per module using `.navigationTitle()`

**Important:** The window title is **static** and does not change based on the selected module. Dynamic titles are set via `.navigationTitle()` in detail views only, which updates the breadcrumb navigation but not the window title itself.

### Dynamic Navigation Titles

Each module detail view sets its own navigation title:

```swift
// StockTickerDetailView
.navigationTitle("Market Watch")

// DetailTabView (Localization)
.navigationTitle("Not WebTranslateIt Editor")

// S3DetailView
.navigationTitle("S3 Feature Config Editor")

// LogsPlaceholderView
.navigationTitle("Logger")
```

### Controls Layout

**Toolbar Items:**
- Module-specific actions in the toolbar
- Consistent placement across modules
- Native macOS toolbar styling

**Bottom Toolbar:**
- Fixed position at bottom of window
- Shared GitStatusBar component
- Liquid glass background

---

## New UI Components

### S3InspectFieldSheet

**Purpose:** Enhanced nested field inspection with performance improvements.

**Features:**
- View deeply nested JSON structures without app hang
- Optimized tree traversal
- Improved rendering performance
- Edit nested fields inline

**Location:** `Views/S3FeatureConfigEditor/S3InspectFieldSheet.swift`

**Usage:**
```swift
.sheet(isPresented: $showInspector) {
    S3InspectFieldSheet(field: selectedField)
}
```

### S3ApplyFieldSheet

**Purpose:** Bulk operations across multiple countries with preview.

**Features:**
- Multi-country selection
- Preview changes before applying
- Atomic operations (all or nothing)
- Validation before applying

**Location:** `Views/S3FeatureConfigEditor/S3ApplyFieldSheet.swift`

**Usage:**
```swift
.sheet(isPresented: $showBulkApply) {
    S3ApplyFieldSheet(field: fieldToApply, countries: availableCountries)
}
```

### CreateBranchSheet

**Purpose:** Create new Git branch from current branch.

**Features:**
- Branch name validation
- Protected branch warnings
- Automatic checkout after creation

**Location:** `Views/Components/Git/CreateBranchSheet.swift`

**Usage:**
```swift
.sheet(isPresented: $showCreateBranch) {
    CreateBranchSheet(onCreateBranch: { branchName in
        // Handle branch creation
    })
}
```

### CommitSheet

**Purpose:** Commit changes with descriptive message.

**Features:**
- Auto-generated commit message
- Editable message field
- File list preview
- Validation before commit

**Location:** `Views/Components/Git/CommitSheet.swift`

**Usage:**
```swift
.sheet(isPresented: $showCommit) {
    CommitSheet(files: modifiedFiles, onCommit: { message in
        // Handle commit
    })
}
```

### TranslationDetailView Toolbar

**Purpose:** Fixed bottom toolbar for translation editing.

**Features:**
- Always visible save/discard buttons
- Liquid glass background (`.ultraThinMaterial`)
- Prominent save button with glow shadow
- Keyboard shortcut (⌘S)
- Bottom padding to prevent content occlusion

**Location:** `Views/LocalizationEditor/TranslationDetailView.swift`

**Implementation:**
```swift
VStack(spacing: 0) {
    // Editor content
    ScrollView {
        // ...
    }
    .padding(.bottom, 60) // Prevent toolbar occlusion

    // Fixed toolbar
    HStack {
        Button("Discard") { /* ... */ }
        Spacer()
        Button("Save") { /* ... */ }
            .keyboardShortcut("s", modifiers: .command)
            .shadow(color: .blue.opacity(0.3), radius: 8)
    }
    .padding()
    .background(.ultraThinMaterial)
}
```

---

**Related Documentation:**
- [Architecture](ARCHITECTURE.md) - Technical architecture and patterns
- [Modules](MODULES.md) - Detailed module documentation
- [Development Guide](DEVELOPMENT.md) - Building and contributing
- [Git Integration](GIT_INTEGRATION.md) - Git workflow implementation
