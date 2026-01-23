import Foundation

/// Represents a single git commit
public struct GitCommit: Sendable, Identifiable {
    public let id: String  // commit hash
    public let shortHash: String  // abbreviated hash (7 chars)
    public let message: String
    public let author: String
    public let timestamp: Date

    public init(
        hash: String,
        message: String,
        author: String,
        timestamp: Date
    ) {
        self.id = hash
        self.shortHash = String(hash.prefix(7))
        self.message = message
        self.author = author
        self.timestamp = timestamp
    }

    /// Relative time string (e.g., "2 hours ago")
    public var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
