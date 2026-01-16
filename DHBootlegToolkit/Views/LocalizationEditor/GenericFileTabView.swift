import SwiftUI

/// A view that displays a generic file in the editor tab area.
/// Shows file icon and name without preview (since file types vary).
struct GenericFileTabView: View {
    let fileURL: URL
    let fileName: String
    let iconName: String

    var body: some View {
        VStack(spacing: 0) {
            // Main content area with icon
            VStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text(fileName)
                    .font(.title2)
                    .fontWeight(.medium)

                Text("No preview available for this file type")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Footer with file info
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
    }
}
