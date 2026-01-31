# Development Guide

> **Navigation:** [← Back to README](../README.md) | [Architecture](ARCHITECTURE.md) | [Modules](MODULES.md) | [UI Structure](UI_STRUCTURE.md)

This guide covers everything you need to build, develop, and contribute to DHBootlegToolkit.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Development Setup](#development-setup)
- [Building from Source](#building-from-source)
- [Code Style Guide](#code-style-guide)
- [Testing](#testing)
- [Working with Packages](#working-with-packages)
- [Contributing](#contributing)

---

## Prerequisites

To build DHBootlegToolkit from source, you need:

- **macOS 26.0+** (deployment target)
- **Xcode 16+** with Command Line Tools
- **Swift 6.0** (included with Xcode 16)
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** for project generation
- **GitHub CLI (`gh`)** for PR creation (optional but recommended)

### Installing XcodeGen

```bash
# Install via Homebrew
brew install xcodegen

# Or via Mint
mint install yonaskolb/XcodeGen
```

### Installing GitHub CLI

```bash
# Install via Homebrew
brew install gh

# Authenticate with GitHub
gh auth login
```

---

## Development Setup

### Clone Repository

```bash
git clone https://github.com/lRoMYl/DHBootlegToolkit.git
cd DHBootlegToolkit
```

### Generate Xcode Project

The project uses XcodeGen to generate the Xcode project from `project.yml`:

```bash
# Generate Xcode project
xcodegen

# This creates DHBootlegToolkit.xcodeproj
```

**Note:** You must run `xcodegen` after:
- Cloning the repository (first time)
- Adding/removing files
- Changing project structure in `project.yml`
- Switching branches that modify project structure

### Opening in Xcode

```bash
# Open the generated project
open DHBootlegToolkit.xcodeproj
```

### Package Dependencies Setup

The project depends on several Swift Packages:

- **DHBootlegToolkitCore** (local package)
- **GitCore** (local package)
- **JSONEditorCore** (local package)
- **JSONEditorUI** (local package)
- **JSONEditorKit** (local package)
- **Sparkle** (external, for auto-updates)

**First-time setup:**
1. Open `DHBootlegToolkit.xcodeproj` in Xcode
2. Wait for Swift Package Manager to resolve dependencies
3. Build the project (⌘B) to ensure all packages are downloaded

---

## Building from Source

### Build via Xcode

1. Open `DHBootlegToolkit.xcodeproj`
2. Select the `DHBootlegToolkit` scheme
3. Choose your target device (typically "My Mac")
4. Press ⌘B to build or ⌘R to run

### Build via Command Line

```bash
# Build the app
xcodebuild -scheme DHBootlegToolkit -configuration Release build

# Build output location
build/Release/DHBootlegToolkit.app
```

### Common Build Issues

**Issue: "Cannot find 'DHBootlegToolkitCore' in scope"**

Solution: Ensure packages are resolved:
```bash
xcodebuild -resolvePackageDependencies
```

**Issue: "No such module 'GitCore'"**

Solution: Clean and rebuild:
```bash
xcodebuild clean
xcodebuild -scheme DHBootlegToolkit build
```

**Issue: XcodeGen not found**

Solution: Install XcodeGen:
```bash
brew install xcodegen
```

---

## Code Style Guide

### Swift 6 Conventions

DHBootlegToolkit uses **Swift 6** with strict concurrency checking enabled.

**Key Principles:**
- Use actors for thread-safe operations
- Leverage `@Observable` for SwiftUI state
- Embrace `async/await` for asynchronous code
- Avoid force unwrapping (`!`) - use optional binding or guard
- Use explicit type annotations where clarity is important

### SwiftUI Patterns

**Observable State Management:**
```swift
@Observable
class MyStore {
    var data: [Item] = []

    func loadData() async {
        // Async operations
    }
}
```

**View Structure:**
```swift
struct MyView: View {
    let store: MyStore

    var body: some View {
        VStack {
            // View content
        }
        .task {
            await store.loadData()
        }
    }
}
```

### Actor Isolation Guidelines

**Worker Actors:**
```swift
public actor MyWorker {
    private var state: SomeState

    public func performOperation() async throws -> Result {
        // Thread-safe operation
    }

    // Use nonisolated for parallel-safe reads
    nonisolated public func getConstant() -> String {
        return "constant value"
    }
}
```

**MainActor for UI:**
```swift
@MainActor
class AppStore {
    @Published var uiState: UIState

    func updateUI() {
        // Runs on main thread
    }
}
```

### Concurrency Best Practices

**Prefer async/await over completion handlers:**
```swift
// ✅ Good
func fetchData() async throws -> Data {
    let url = URL(string: "...")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// ❌ Avoid
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    // Old-style completion handlers
}
```

**Use AsyncStream for continuous updates:**
```swift
func priceUpdates() -> AsyncStream<Double> {
    AsyncStream { continuation in
        // Stream values
        continuation.yield(100.50)
        continuation.finish()
    }
}
```

### Naming Conventions

- **Files**: PascalCase matching the main type (e.g., `StockTickerView.swift`)
- **Types**: PascalCase (e.g., `StockData`, `GitWorker`)
- **Variables/Functions**: camelCase (e.g., `currentBranch`, `fetchStockData()`)
- **Constants**: camelCase (e.g., `maxRetries`, `defaultTimeout`)
- **Actors**: Suffix with "Worker" for clarity (e.g., `GitWorker`, `FileSystemWorker`)

### Code Organization

**File Header:**
```swift
//
//  FileName.swift
//  DHBootlegToolkit
//
//  Created by [Author] on [Date].
//

import SwiftUI

// Code here
```

**Import Order:**
1. Foundation/System frameworks
2. SwiftUI
3. Third-party packages
4. Local packages (DHBootlegToolkitCore, GitCore, etc.)

---

## Testing

### Running Tests

**Via Xcode:**
1. Press ⌘U to run all tests
2. Or use Test Navigator (⌘6) to run specific tests

**Via Command Line:**
```bash
# Run app tests
xcodebuild test -scheme DHBootlegToolkitTests

# Run Core package tests
cd DHBootlegToolkitCore
swift test

# Run GitCore tests
cd GitCore
swift test
```

### Writing New Tests

**Example Test:**
```swift
import Testing
@testable import DHBootlegToolkitCore

@Suite("GitWorker Tests")
struct GitWorkerTests {

    @Test("Get current branch")
    func testGetCurrentBranch() async throws {
        let worker = GitWorker(repositoryURL: testRepoURL)
        let branch = try await worker.getCurrentBranch()
        #expect(branch == "main")
    }
}
```

### Test Coverage

Run tests with coverage:
```bash
xcodebuild test -scheme DHBootlegToolkit -enableCodeCoverage YES
```

View coverage report in Xcode:
1. Navigate to Report Navigator (⌘9)
2. Select latest test run
3. Click "Coverage" tab

---

## Working with Packages

### DHBootlegToolkitCore

**Location:** `DHBootlegToolkitCore/`

Core business logic package.

**Key Components:**
- Workers (actors)
- Models (data structures)
- Configuration (protocols)

**Adding New Workers:**
1. Create new actor in `Sources/DHBootlegToolkitCore/Workers/`
2. Implement thread-safe operations
3. Add to `Package.swift` if needed
4. Write tests in `Tests/`

### GitCore

**Location:** `GitCore/`

Git operations package.

**Key Components:**
- GitWorker (version control operations)
- Git command execution utilities

**Modifying Git Operations:**
1. Update worker in `Sources/GitCore/Workers/`
2. Ensure thread safety with actor isolation
3. Handle errors gracefully
4. Add tests for new operations

### JSONEditorCore/UI/Kit

**JSONEditorCore Location:** `JSONEditorCore/`
**JSONEditorUI Location:** `JSONEditorUI/`
**JSONEditorKit Location:** `JSONEditorKit/`

JSON editing packages split by responsibility:
- **Core**: Logic and data structures
- **UI**: SwiftUI components
- **Kit**: Utilities and helpers

**Adding Features:**
1. Logic goes in JSONEditorCore
2. UI components go in JSONEditorUI
3. Utilities go in JSONEditorKit
4. Update package dependencies as needed

---

## Contributing

### Branch Naming

Use descriptive branch names with prefixes:
- `feature/` - New features (e.g., `feature/add-chart-export`)
- `bugfix/` - Bug fixes (e.g., `bugfix/fix-git-status-parsing`)
- `chore/` - Maintenance tasks (e.g., `chore/update-dependencies`)
- `docs/` - Documentation updates (e.g., `docs/improve-readme`)

### Commit Messages

Write clear, descriptive commit messages:

```
Add real-time WebSocket connection for stock prices

- Implement YahooFinanceWorker with WebSocket support
- Add AsyncStream for price updates
- Include fallback to REST API
- Add connection status indicator
```

**Format:**
- First line: Brief summary (50 chars or less)
- Blank line
- Detailed description (if needed)
- Bullet points for multiple changes

### Pull Request Process

1. **Create feature branch:**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes and commit:**
   ```bash
   git add .
   git commit -m "Descriptive message"
   ```

3. **Push to GitHub:**
   ```bash
   git push -u origin feature/my-feature
   ```

4. **Create PR:**
   - Via GitHub UI
   - Or via `gh` CLI: `gh pr create`

5. **Wait for review and address feedback**

### Code Review Guidelines

**For Authors:**
- Keep PRs focused and reasonably sized
- Write clear PR descriptions
- Add screenshots for UI changes
- Ensure tests pass before requesting review

**For Reviewers:**
- Review for correctness, not style preferences
- Test the changes locally if possible
- Provide constructive feedback
- Approve or request changes promptly

---

**Related Documentation:**
- [Architecture](ARCHITECTURE.md) - Technical architecture and patterns
- [Modules](MODULES.md) - Detailed module documentation
- [UI Structure](UI_STRUCTURE.md) - View hierarchy and components
- [Git Integration](GIT_INTEGRATION.md) - Git workflow implementation
