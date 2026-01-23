# GitCore

Generic git operations for macOS applications.

## Overview

GitCore provides a Swift-friendly interface for common git operations including branch management, commits, and pull request creation. It's designed to work with any macOS application that needs git integration.

## Features

- **GitWorker**: Actor-based git command execution
- **ProcessExecutor**: Low-level process execution with timeout support
- **Git Models**: `GitStatus`, `GitCommit`, `GitFileStatus`
- **GitConfiguration**: Protocol for repository-specific settings
- **GitPublishable**: Protocol for view models with git operations

## Installation

Add GitCore to your Swift package:

```swift
dependencies: [
    .package(path: "../GitCore")
]
```

## Usage

### Basic Git Operations

```swift
import GitCore

// Create a git worker
let config = MyGitConfig() // Conforms to GitConfiguration
let gitWorker = GitWorker(repositoryURL: repoURL, configuration: config)

// Check git status
let status = try await gitWorker.checkConfiguration()

// Create a new branch
try await gitWorker.createBranch("feature/new-feature")

// Commit and push changes
try await gitWorker.commitAll(message: "Add new feature")
try await gitWorker.push(branch: "feature/new-feature")

// Create a pull request
let prURL = try await gitWorker.createPullRequest(
    title: "Add new feature",
    body: "This PR adds a new feature"
)
```

### Using GitPublishable Protocol

```swift
@Observable
@MainActor
final class MyStore: GitPublishable {
    var gitWorker: GitWorker?
    var gitStatus: GitStatus = .unconfigured

    func generateCommitMessage() -> String {
        "Update configuration"
    }

    func generatePRTitle() -> String {
        "Configuration updates"
    }

    func generatePRBody() -> String {
        "Automated configuration changes"
    }
}

// The protocol provides default implementations for:
// - publish() - Creates PR with commit, push, and PR creation
// - refreshGitStatus() - Updates git status
// - canPublish - Computed property for button state
```

## Requirements

- macOS 15.0+
- Swift 6.0+
- Git installed on the system

## License

See LICENSE file.
