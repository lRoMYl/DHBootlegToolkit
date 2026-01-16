import SwiftUI

/// A view that displays text-based files with syntax highlighting or rendering.
/// Supports plain text (.txt), JSON (syntax-highlighted), and Markdown (rendered).
struct TextTabView: View {
    let fileURL: URL
    let fileName: String
    let fileExtension: String

    @State private var fileContent: String?
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            if let content = fileContent {
                ScrollView([.horizontal, .vertical]) {
                    textContent(content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(nsColor: .textBackgroundColor))
            } else if let error = loadError {
                errorView(error)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // Footer with file info
            footer
        }
        .task {
            await loadContent()
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private func textContent(_ content: String) -> some View {
        switch fileExtension {
        case "json":
            // Syntax-highlighted JSON
            Text(syntaxHighlightedJSON(content))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        case "md", "markdown":
            // Rendered Markdown
            Text(markdownAttributedString(content))
                .textSelection(.enabled)
        default:
            // Plain text
            Text(content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Failed to load file")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fileName)
                    .font(.headline)
                Text(fileURL.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Show in Finder button
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Content Loading

    private func loadContent() async {
        do {
            let data = try Data(contentsOf: fileURL)
            if let content = String(data: data, encoding: .utf8) {
                fileContent = content
            } else {
                loadError = "Unable to decode file as text"
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Syntax Highlighting

    private func syntaxHighlightedJSON(_ json: String) -> AttributedString {
        var result = AttributedString()

        // Tokenize JSON for syntax highlighting
        var index = json.startIndex
        while index < json.endIndex {
            let char = json[index]

            if char == "\"" {
                // String literal
                let stringStart = index
                index = json.index(after: index)

                // Find closing quote
                while index < json.endIndex {
                    let c = json[index]
                    if c == "\\" && json.index(after: index) < json.endIndex {
                        // Skip escaped character
                        index = json.index(index, offsetBy: 2)
                    } else if c == "\"" {
                        index = json.index(after: index)
                        break
                    } else {
                        index = json.index(after: index)
                    }
                }

                let stringValue = String(json[stringStart..<index])

                // Check if this is a key (followed by colon) or value
                var tempIndex = index
                while tempIndex < json.endIndex && json[tempIndex].isWhitespace {
                    tempIndex = json.index(after: tempIndex)
                }

                var attr = AttributedString(stringValue)
                if tempIndex < json.endIndex && json[tempIndex] == ":" {
                    // It's a key - use blue color
                    attr.foregroundColor = .systemBlue
                } else {
                    // It's a string value - use green color
                    attr.foregroundColor = .systemGreen
                }
                result.append(attr)

            } else if char == ":" || char == "," || char == "{" || char == "}" || char == "[" || char == "]" {
                // Structural characters
                var attr = AttributedString(String(char))
                attr.foregroundColor = .labelColor
                result.append(attr)
                index = json.index(after: index)

            } else if char.isNumber || char == "-" {
                // Number
                let numStart = index
                if char == "-" {
                    index = json.index(after: index)
                }
                while index < json.endIndex && (json[index].isNumber || json[index] == "." || json[index] == "e" || json[index] == "E" || json[index] == "+" || json[index] == "-") {
                    index = json.index(after: index)
                }
                let numStr = String(json[numStart..<index])
                var attr = AttributedString(numStr)
                attr.foregroundColor = .systemOrange
                result.append(attr)

            } else if json[index...].hasPrefix("true") {
                var attr = AttributedString("true")
                attr.foregroundColor = .systemPurple
                result.append(attr)
                index = json.index(index, offsetBy: 4)

            } else if json[index...].hasPrefix("false") {
                var attr = AttributedString("false")
                attr.foregroundColor = .systemPurple
                result.append(attr)
                index = json.index(index, offsetBy: 5)

            } else if json[index...].hasPrefix("null") {
                var attr = AttributedString("null")
                attr.foregroundColor = .systemRed
                result.append(attr)
                index = json.index(index, offsetBy: 4)

            } else {
                // Other characters (whitespace, etc.)
                result.append(AttributedString(String(char)))
                index = json.index(after: index)
            }
        }

        return result
    }

    private func markdownAttributedString(_ markdown: String) -> AttributedString {
        do {
            return try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))
        } catch {
            // Fallback to plain text if markdown parsing fails
            return AttributedString(markdown)
        }
    }
}
