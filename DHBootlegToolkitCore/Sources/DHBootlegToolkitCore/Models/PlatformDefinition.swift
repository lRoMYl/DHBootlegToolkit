import Foundation

/// Defines a platform for organizing content in the repository.
///
/// Unlike a hardcoded enum, `PlatformDefinition` allows apps to configure
/// any number of platforms with custom folder names and display names.
public struct PlatformDefinition: Sendable, Identifiable, Hashable, Codable {
    /// Unique identifier for the platform
    public let id: String

    /// Folder name in the repository (e.g., "mobile", "web")
    public let folderName: String

    /// Human-readable display name (e.g., "Mobile", "Web")
    public let displayName: String

    public init(id: String, folderName: String, displayName: String) {
        self.id = id
        self.folderName = folderName
        self.displayName = displayName
    }

    /// Convenience initializer when id matches folderName
    public init(folderName: String, displayName: String) {
        self.id = folderName
        self.folderName = folderName
        self.displayName = displayName
    }
}

// MARK: - Common Platform Definitions

extension PlatformDefinition {
    /// Mobile platform with folder name "mobile"
    public static let mobile = PlatformDefinition(
        folderName: "mobile",
        displayName: "Mobile"
    )

    /// Web platform with folder name "web"
    public static let web = PlatformDefinition(
        folderName: "web",
        displayName: "Web"
    )
}
