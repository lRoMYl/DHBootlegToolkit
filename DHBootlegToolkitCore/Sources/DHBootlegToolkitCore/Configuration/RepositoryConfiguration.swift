import Foundation

/// Protocol defining the configuration for a localization repository.
///
/// Implement this protocol to customize how the Core library interacts
/// with different repository structures. Apps can provide their own
/// configuration, or repositories can include a `.localization-schema.json`
/// file that overrides the default configuration.
///
/// ## Example Implementation
/// ```swift
/// struct MyAppConfiguration: RepositoryConfiguration {
///     let basePath = "content/translations"
///     let platforms = [PlatformDefinition.mobile, PlatformDefinition.web]
///     let entitySchema = EntitySchema.translation
/// }
/// ```
public protocol RepositoryConfiguration: Sendable {
    /// Base path within the repository where content is stored.
    ///
    /// Example: "translations/pandora/project"
    var basePath: String { get }

    /// Available platforms in this repository.
    ///
    /// Example: [PlatformDefinition.mobile, PlatformDefinition.web]
    var platforms: [PlatformDefinition] { get }

    /// Primary language file name in each feature folder.
    ///
    /// Example: "en.json"
    var primaryLanguageFile: String { get }

    /// Name of the assets/images folder within each feature.
    ///
    /// Example: "images"
    var assetsFolderName: String { get }

    /// Folder names to exclude during feature discovery.
    ///
    /// Example: ["legacy", ".git", "node_modules"]
    var excludedFolders: Set<String> { get }

    /// Branch names that are protected from direct commits.
    ///
    /// Example: ["main", "master"]
    var protectedBranches: Set<String> { get }

    /// Regex pattern for validating entity key names.
    ///
    /// Example: "^[A-Za-z][A-Za-z0-9_]*$"
    var keyValidationPattern: String { get }

    /// Schema defining the structure of JSON entities.
    var entitySchema: EntitySchema { get }
}

// MARK: - Default Implementations

extension RepositoryConfiguration {
    public var primaryLanguageFile: String { "en.json" }
    public var assetsFolderName: String { "images" }
    public var excludedFolders: Set<String> { ["legacy", ".git", "node_modules"] }
    public var protectedBranches: Set<String> { ["main", "master", "origin"] }
    public var keyValidationPattern: String { "^[A-Za-z][A-Za-z0-9_]*$" }
}

// MARK: - JSON-Decodable Configuration

/// A `RepositoryConfiguration` implementation that can be decoded from JSON.
///
/// This is used when loading configuration from a `.localization-schema.json`
/// file in the repository root.
public struct JSONRepositoryConfiguration: RepositoryConfiguration, Codable, Sendable {
    public let basePath: String
    public let platforms: [PlatformDefinition]
    public let primaryLanguageFile: String
    public let assetsFolderName: String
    public let excludedFolders: Set<String>
    public let protectedBranches: Set<String>
    public let keyValidationPattern: String
    public let entitySchema: EntitySchema

    public init(
        basePath: String,
        platforms: [PlatformDefinition],
        primaryLanguageFile: String = "en.json",
        assetsFolderName: String = "images",
        excludedFolders: Set<String> = ["legacy", ".git", "node_modules"],
        protectedBranches: Set<String> = ["main", "master"],
        keyValidationPattern: String = "^[A-Za-z][A-Za-z0-9_]*$",
        entitySchema: EntitySchema
    ) {
        self.basePath = basePath
        self.platforms = platforms
        self.primaryLanguageFile = primaryLanguageFile
        self.assetsFolderName = assetsFolderName
        self.excludedFolders = excludedFolders
        self.protectedBranches = protectedBranches
        self.keyValidationPattern = keyValidationPattern
        self.entitySchema = entitySchema
    }
}

// MARK: - Configuration Helpers

extension RepositoryConfiguration {
    /// Checks if a branch name is protected.
    public func isProtectedBranch(_ branchName: String) -> Bool {
        protectedBranches.contains(branchName)
    }

    /// Validates an entity key name against the configured pattern.
    public func isValidKeyName(_ keyName: String) -> Bool {
        keyName.range(of: keyValidationPattern, options: .regularExpression) != nil
    }

    /// Returns the full path to a platform folder within a repository.
    public func platformPath(in repositoryURL: URL, for platform: PlatformDefinition) -> URL {
        repositoryURL
            .appendingPathComponent(basePath)
            .appendingPathComponent(platform.folderName)
    }
}
