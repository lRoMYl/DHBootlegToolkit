import Foundation

/// Represents a feature folder in the repository.
///
/// A feature folder contains translation files and optionally images/screenshots.
/// It belongs to a specific platform (e.g., mobile, web).
public struct FeatureFolder: Identifiable, Hashable, Sendable {
    /// Unique identifier combining platform and folder name
    public let id: String

    /// Folder name in the file system
    public let name: String

    /// Platform this feature belongs to
    public let platform: PlatformDefinition

    /// Full URL to the feature folder
    public let url: URL

    /// Whether the primary language file exists
    public let hasPrimaryLanguageFile: Bool

    /// Whether the assets folder exists
    public let hasAssetsFolder: Bool

    /// Name of the primary language file (for URL building)
    public let primaryLanguageFileName: String

    /// Name of the assets folder (for URL building)
    public let assetsFolderName: String

    /// Display name - returns the raw folder name without transformation
    public var displayName: String {
        name
    }

    /// URL to the primary language file
    public var primaryLanguageFileURL: URL {
        url.appendingPathComponent(primaryLanguageFileName)
    }

    /// URL to the assets folder
    public var assetsFolderURL: URL {
        url.appendingPathComponent(assetsFolderName)
    }

    public init(
        name: String,
        platform: PlatformDefinition,
        url: URL,
        hasPrimaryLanguageFile: Bool = false,
        hasAssetsFolder: Bool = false,
        primaryLanguageFileName: String = "en.json",
        assetsFolderName: String = "images"
    ) {
        self.id = "\(platform.id)_\(name)"
        self.name = name
        self.platform = platform
        self.url = url
        self.hasPrimaryLanguageFile = hasPrimaryLanguageFile
        self.hasAssetsFolder = hasAssetsFolder
        self.primaryLanguageFileName = primaryLanguageFileName
        self.assetsFolderName = assetsFolderName
    }
}

// MARK: - Convenience Initializer

extension FeatureFolder {
    /// Creates a FeatureFolder using configuration values for file names.
    public init(
        name: String,
        platform: PlatformDefinition,
        url: URL,
        hasPrimaryLanguageFile: Bool,
        hasAssetsFolder: Bool,
        configuration: RepositoryConfiguration
    ) {
        self.init(
            name: name,
            platform: platform,
            url: url,
            hasPrimaryLanguageFile: hasPrimaryLanguageFile,
            hasAssetsFolder: hasAssetsFolder,
            primaryLanguageFileName: configuration.primaryLanguageFile,
            assetsFolderName: configuration.assetsFolderName
        )
    }
}
