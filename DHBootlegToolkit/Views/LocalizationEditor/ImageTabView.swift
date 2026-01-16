import SwiftUI

/// A view that displays an image in the editor tab area.
/// Used when the user selects an image file from the sidebar.
struct ImageTabView: View {
    let imageURL: URL
    let imageName: String

    @State private var image: NSImage?
    @State private var loadError: String?
    @State private var zoomLevel: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Image content
            if let image = image {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(zoomLevel)
                        .frame(
                            minWidth: 100,
                            maxWidth: .infinity,
                            minHeight: 100,
                            maxHeight: .infinity
                        )
                }
                .background(Color(nsColor: .controlBackgroundColor))
            } else if let error = loadError {
                ContentUnavailableView {
                    Label("Unable to Load Image", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            } else {
                ProgressView()
                    .controlSize(.large)
            }

            Divider()

            // Footer with image info and zoom controls
            HStack {
                // Image name and path
                VStack(alignment: .leading, spacing: 2) {
                    Text(imageName)
                        .font(.headline)
                    Text(imageURL.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // Zoom controls
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            zoomLevel = max(0.1, zoomLevel - 0.25)
                        }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    .help("Zoom out")

                    Text("\(Int(zoomLevel * 100))%")
                        .font(.caption)
                        .frame(width: 50)
                        .foregroundStyle(.secondary)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            zoomLevel = min(5.0, zoomLevel + 0.25)
                        }
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    .help("Zoom in")

                    Divider()
                        .frame(height: 16)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            zoomLevel = 1.0
                        }
                    } label: {
                        Image(systemName: "1.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    .help("Reset zoom")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .task {
            loadImage()
        }
    }

    private func loadImage() {
        guard let nsImage = NSImage(contentsOf: imageURL) else {
            loadError = "Could not load image from: \(imageURL.lastPathComponent)"
            return
        }
        image = nsImage
    }
}

#Preview {
    ImageTabView(
        imageURL: URL(fileURLWithPath: "/tmp/test.png"),
        imageName: "test.png"
    )
    .frame(width: 600, height: 400)
}
