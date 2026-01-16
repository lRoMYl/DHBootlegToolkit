import Foundation

struct PendingScreenshot: Identifiable, Sendable {
    let id: UUID
    let originalURL: URL
    let originalName: String
    let renamedName: String
    let destinationURL: URL

    /// Full initializer for direct creation (used by NewKeyWizard)
    init(id: UUID = UUID(), originalURL: URL, originalName: String, renamedName: String, destinationURL: URL) {
        self.id = id
        self.originalURL = originalURL
        self.originalName = originalName
        self.renamedName = renamedName
        self.destinationURL = destinationURL
    }

    /// Convenience initializer with auto-rename (used by ScreenshotDropZone)
    init(originalURL: URL, destinationFolder: URL) {
        self.id = UUID()
        self.originalURL = originalURL
        self.originalName = originalURL.lastPathComponent

        // Generate PR date format: DD_MM_YYYY.png
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd_MM_yyyy"
        let dateString = dateFormatter.string(from: Date())

        // Preserve suffix if exists (e.g., _swimlane_title)
        let stem = originalURL.deletingPathExtension().lastPathComponent
        let suffix = Self.extractSuffix(from: stem)
        self.renamedName = suffix.isEmpty ? "\(dateString).png" : "\(dateString)_\(suffix).png"
        self.destinationURL = destinationFolder.appendingPathComponent(renamedName)
    }

    private static func extractSuffix(from filename: String) -> String {
        let components = filename.components(separatedBy: "_")
        guard components.count > 1 else { return "" }

        // Filter out parts that look like dates (all numbers)
        let nonDateParts = components.filter { part in
            !part.allSatisfy { $0.isNumber } && part.count > 2
        }
        return nonDateParts.joined(separator: "_")
    }
}
