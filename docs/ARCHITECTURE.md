# Architecture

> **Navigation:** [← Back to README](../README.md) | [Modules](MODULES.md) | [Development](DEVELOPMENT.md) | [UI Structure](UI_STRUCTURE.md)

## System Overview

DHBootlegToolkit is built as a modular macOS application with a reusable Swift Package at its core. The architecture emphasizes:

- **Thread-safe concurrency** via Swift actors
- **Protocol-based configuration** for extensibility
- **Observable state management** for SwiftUI reactivity
- **Unified Git workflow** shared across all modules

## Package Architecture

The project is organized into multiple Swift Packages:

### DHBootlegToolkitCore

**Location:** `DHBootlegToolkitCore/`

Core business logic package providing thread-safe workers, models, and configuration management. This package is designed to be reusable and independent of UI concerns.

**Contents:**
- Workers (actors for thread-safe operations)
- Models (data structures)
- Configuration (protocols and loaders)

### GitCore

**Location:** `GitCore/`

Git operations package providing version control integration.

**Contents:**
- Git command execution
- Repository management
- Branch and commit operations

### JSONEditorCore

**Location:** `JSONEditorCore/`

JSON editing logic package.

**Contents:**
- JSON parsing and serialization
- Tree structure management
- Edit operations

### JSONEditorUI

**Location:** `JSONEditorUI/`

JSON editor UI components package.

**Contents:**
- Tree view components
- Field editors
- Search and filtering UI

### JSONEditorKit

**Location:** `JSONEditorKit/`

JSON editing utilities package.

**Contents:**
- Helper functions
- Validation utilities
- Formatting tools

## Core Library Architecture

### Workers (Thread-safe Actors)

Workers are implemented as Swift actors to ensure thread-safe execution of operations:

| Worker | Purpose | Key Operations |
|--------|---------|----------------|
| **YahooFinanceWorker** | WebSocket and REST API for stock data | Real-time price updates, historical data fetching, market statistics |
| **CommentaryEngine** | Sentiment commentary generation | Dynamic witty market commentary based on price movements and thresholds |
| **GitWorker** | Git operations | Branch management, commit, push, status parsing |
| **FileSystemWorker** | File I/O with order-preserving JSON | Read/write files, preserve JSON key order for clean diffs |
| **DiffWorker** | Diff computation | Compare HEAD vs working directory, generate change lists |
| **ExternalChangeWorker** | External change detection | Hash-based file modification detection, conflict resolution |
| **S3JSONSerializer** | S3 config serialization | JSON encoding/decoding for S3 feature configs, field operations |
| **ProcessExecutor** | Command execution | Shell command execution for git and other CLI tools |

**Actor Pattern Example:**
```swift
public actor GitWorker {
    private let repositoryURL: URL

    public func getCurrentBranch() async throws -> String {
        try await runCommand(executable: "/usr/bin/git", arguments: ["branch", "--show-current"])
    }
}
```

### Models

Data structures representing application entities:

| Model | Purpose |
|-------|---------|
| **FeatureFolder**, **TranslationEntity** | Localization data structures for organizing translation keys by feature |
| **S3CountryConfig**, **S3Environment** | S3 feature config data structures for country-level configurations |
| **StockData**, **StockSymbol** | Stock market data structures with price, volume, sentiment |
| **GitStatus**, **GitFileStatus** | Git state representation for tracking repository changes |
| **EntityDiff**, **EntityChangeStatus** | Change tracking for diff display in UI |

### Configuration Management

| Component | Purpose |
|-----------|---------|
| **RepositoryConfiguration** | Protocol defining repository layout and structure |
| **EntitySchema** | JSON schema definitions for validation |
| **ConfigurationLoader** | Parses `.localization-schema.json` from repository root |

## Module Architecture

### Stock Ticker Technical Details

**Real-Time Data Flow:**

```
YahooFinanceWorker (WebSocket/REST)
        ↓
AsyncStream<StockData>
        ↓
StockTickerStore (@Observable)
        ↓
SwiftUI Views (Price Card, Charts, Sentiment)
```

**YahooFinanceWorker Integration:**
- **WebSocket connections** for real-time price updates
- **REST API fallback** when WebSocket unavailable
- **AsyncStream** for reactive data updates
- Historical data fetching for chart time ranges

**CommentaryEngine:**
- **Dynamic sentiment analysis** based on price changes
- **Witty market commentary** generation with emoji indicators
- **Threshold-based categories**: Moonshot 🚀, Gains 📈, Flat 😐, Losses 📉, Crash 💥
- **Adaptive thresholds** calculated from historical volatility

**Sentiment Calculation:**

Dynamic thresholds based on historical volatility:

```swift
volatility = standardDeviation(returns) * volatilityMultiplier
```

**Sentiment Categories:**
- **Moonshot** 🚀: Change ≥ +moonshot threshold (e.g., +5%)
- **Gains** 📈: Between +gainsLower and +moonshot
- **Flat** 😐: Within ±flat range
- **Losses** 📉: Between -lossesLower and -flatLower
- **Crash** 💥: Change ≤ crash threshold (e.g., -5%)

**Threshold Source:**
- **Fixed**: Baseline thresholds (±5%, ±1%, ±0.5%)
- **Dynamic**: Adjusted based on 3-month volatility ratio

**Chart System:**
- Interactive Swift Charts with 11 time ranges (1D, 1W, 1M, 3M, 6M, YTD, 1Y, 2Y, 5Y, 10Y, All)
- Hover to inspect price at specific time
- Drag to select range and view change statistics
- Smooth catmull-rom interpolation
- Adaptive axis labels based on time range
- Color-coded sentiment overlay on range selection

## Recent Improvements

### S3 Feature Config Editor Enhancements

**S3EditorConfiguration** (commit 4c51d03):
- New configuration file for S3 editor settings
- Improved field promotion and batch operations
- Enhanced JSON schema validation

**Performance Fixes:**
- **Nested field inspection fix**: Resolved app hang when inspecting deeply nested JSON structures
- **Bulk delete functionality**: Fixed bulk delete operations for multiple config fields
- **S3JSONSerializer improvements**: Enhanced field operation serialization

**UI Enhancements:**
- JSONSearchBar with improved searching
- JSONEditorToolbar for better navigation
- S3InspectFieldSheet for enhanced nested field handling
- S3ApplyFieldSheet for bulk operations across countries

## Project Structure

```
DHBootlegToolkit/
├── DHBootlegToolkitCore/                    # Reusable Swift Package
│   ├── Package.swift
│   └── Sources/DHBootlegToolkitCore/
│       ├── Workers/                         # YahooFinanceWorker, CommentaryEngine,
│       │                                    # GitWorker, FileSystemWorker, DiffWorker,
│       │                                    # ExternalChangeWorker, S3JSONSerializer,
│       │                                    # ProcessExecutor
│       ├── Models/                          # FeatureFolder, TranslationEntity,
│       │                                    # StockData, GitStatus, EntityDiff
│       └── Configuration/                   # RepositoryConfiguration, EntitySchema
│
├── GitCore/                                 # Git operations package
│   ├── Package.swift
│   └── Sources/GitCore/
│       └── Workers/                         # GitWorker (version control operations)
│
├── JSONEditorCore/                          # JSON editing logic package
│   ├── Package.swift
│   └── Sources/JSONEditorCore/
│       └── (JSON parsing, tree structure)
│
├── JSONEditorUI/                            # JSON editor UI components package
│   ├── Package.swift
│   └── Sources/JSONEditorUI/
│       └── (Tree view, field editors, search UI)
│
├── JSONEditorKit/                           # JSON editing utilities package
│   ├── Package.swift
│   └── Sources/JSONEditorKit/
│       └── (Helper functions, validation, formatting)
│
├── DHBootlegToolkit/                        # macOS SwiftUI App
│   ├── App/DHBootlegToolkitApp.swift        # @main entry point
│   ├── ViewModels/                          # View State containers
│   │   ├── AppStore.swift                   # Localization editor state (~1600 lines)
│   │   ├── S3Store.swift                    # S3 config editor state
│   │   └── StockTickerStore.swift           # Stock ticker state
│   ├── Views/                               # Views
│   │   ├── MainSplitView.swift              # Primary layout + git bar
│   │   ├── Components/                      # Shared components
│   │   │   ├── GitStatusBar.swift           # Git status bar
│   │   │   ├── JSONSearchBar.swift          # Search toolbar
│   │   │   └── JSONEditorToolbar.swift      # Editor toolbar
│   │   ├── Sidebar/                         # SidebarView with 4 tabs
│   │   ├── StockTicker/                     # Stock Ticker module
│   │   │   ├── StockTickerDetailView.swift
│   │   │   ├── StockPriceCard.swift
│   │   │   ├── SentimentThresholdLegend.swift
│   │   │   ├── StockChartView.swift
│   │   │   └── MarketStatsGrid.swift
│   │   ├── LocalizationEditor/              # Localization Editor module
│   │   │   ├── DetailTabView.swift
│   │   │   ├── TranslationDetailView.swift
│   │   │   └── TranslationListView.swift
│   │   └── S3FeatureConfigEditor/           # S3 Config Editor module
│   │       ├── S3DetailView.swift
│   │       ├── S3BrowserView.swift
│   │       ├── JSONTreeView.swift
│   │       ├── S3PromotionSheet.swift
│   │       ├── S3ApplyFieldSheet.swift
│   │       └── S3InspectFieldSheet.swift
│   └── Models/                              # EditorTab, LogEntry
│
├── DHBootlegToolkitTests/                   # Unit tests
├── project.yml                              # XcodeGen configuration
```

## Design Patterns

### Actor Isolation

All workers are implemented as Swift actors to ensure thread-safe execution:

```swift
public actor FileSystemWorker {
    public func readFile(at url: URL) async throws -> Data {
        // Thread-safe file I/O
    }
}
```

### Observable Pattern

SwiftUI state management uses the `@Observable` macro for reactive updates:

```swift
@Observable
class StockTickerStore {
    var stockData: StockData?
    var sentimentThresholds: SentimentThresholds

    func updatePrice(_ newPrice: Double) {
        // Automatic UI updates
    }
}
```

### Dependency Injection

Workers are injected into view models for testability:

```swift
class AppStore {
    private let gitWorker: GitWorker
    private let fileSystemWorker: FileSystemWorker

    init(gitWorker: GitWorker, fileSystemWorker: FileSystemWorker) {
        self.gitWorker = gitWorker
        self.fileSystemWorker = fileSystemWorker
    }
}
```

## Code Conventions

- **Swift 6** with strict concurrency checking
- **Actors** for thread-safe workers
- **@Observable** pattern for SwiftUI state management
- **Protocol-based configuration** for extensibility
- **Nonisolated methods** where parallel execution is safe
- **Native macOS UI patterns** (liquid glass, materials, toolbars)

### Order-Preserving JSON

The `FileSystemWorker` manually builds JSON to preserve key order, which is important for readable diffs in version control:

```swift
// Custom JSON serialization maintains key order
func serializeJSON(_ object: Any) -> String {
    // Manual string building preserves insertion order
}
```

### External Change Detection

File hashes (prefix + suffix + length) are cached and compared on app focus to detect concurrent edits:

```swift
let hash = calculateHash(prefix: data.prefix(1024),
                        suffix: data.suffix(1024),
                        length: data.count)
```

---

**Related Documentation:**
- [Module Details](MODULES.md) - Detailed module documentation
- [Development Guide](DEVELOPMENT.md) - Building and contributing
- [UI Structure](UI_STRUCTURE.md) - View hierarchy and components
- [Git Integration](GIT_INTEGRATION.md) - Git workflow implementation
- [State Management](STATE_MANAGEMENT.md) - State machines and patterns
