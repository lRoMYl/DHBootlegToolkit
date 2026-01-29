import SwiftUI

// MARK: - Browser Shell View

/// Generic 3-state UI shell for repository-based editors
/// Handles prompt/loading/error/content states with consistent UX
public struct BrowserShellView<Content: View>: View {
    let repositoryURL: URL?
    let isLoading: Bool
    let errorMessage: String?
    let promptTitle: String
    let promptMessage: String
    let promptButtonLabel: String
    @ViewBuilder let content: () -> Content
    let onSelectRepository: () -> Void

    public init(
        repositoryURL: URL?,
        isLoading: Bool = false,
        errorMessage: String? = nil,
        promptTitle: String = "No Repository Selected",
        promptMessage: String = "Select a repository to get started",
        promptButtonLabel: String = "Select Repository",
        onSelectRepository: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.repositoryURL = repositoryURL
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.promptTitle = promptTitle
        self.promptMessage = promptMessage
        self.promptButtonLabel = promptButtonLabel
        self.onSelectRepository = onSelectRepository
        self.content = content
    }

    public var body: some View {
        if repositoryURL == nil {
            // State 1: No repository selected - show prompt
            RepositoryPromptView(
                title: promptTitle,
                message: promptMessage,
                buttonLabel: promptButtonLabel,
                onSelect: onSelectRepository
            )
        } else if isLoading {
            // State 2: Loading - show progress indicator
            LoadingStateView()
        } else if let error = errorMessage {
            // State 3: Error - show error message
            ErrorStateView(message: error)
        } else {
            // State 4: Ready - show content
            content()
        }
    }
}

// MARK: - Repository Prompt View

private struct RepositoryPromptView: View {
    let title: String
    let message: String
    let buttonLabel: String
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: onSelect) {
                Label(buttonLabel, systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading State View

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error State View

private struct ErrorStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("Error")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("No Repository") {
    BrowserShellView(
        repositoryURL: nil,
        onSelectRepository: {}
    ) {
        Text("Content (should not be visible)")
    }
    .frame(width: 300, height: 400)
}

#Preview("Loading") {
    BrowserShellView(
        repositoryURL: URL(string: "file:///path/to/repo"),
        isLoading: true,
        onSelectRepository: {}
    ) {
        Text("Content (should not be visible)")
    }
    .frame(width: 300, height: 400)
}

#Preview("Error") {
    BrowserShellView(
        repositoryURL: URL(string: "file:///path/to/repo"),
        errorMessage: "Failed to load repository: Invalid configuration",
        onSelectRepository: {}
    ) {
        Text("Content (should not be visible)")
    }
    .frame(width: 300, height: 400)
}

#Preview("Content Ready") {
    BrowserShellView(
        repositoryURL: URL(string: "file:///path/to/repo"),
        onSelectRepository: {}
    ) {
        VStack(spacing: 16) {
            Text("Repository Content")
                .font(.headline)
            List {
                Text("Item 1")
                Text("Item 2")
                Text("Item 3")
            }
        }
    }
    .frame(width: 300, height: 400)
}
