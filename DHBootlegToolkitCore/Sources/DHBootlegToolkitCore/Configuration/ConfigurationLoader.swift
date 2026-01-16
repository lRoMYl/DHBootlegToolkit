import Foundation

/// Loads repository configuration with fallback chain.
///
/// The loader first checks for an in-repository schema file (`.localization-schema.json`).
/// If not found, it falls back to the app-provided configuration.
///
/// ## Usage
/// ```swift
/// let loader = ConfigurationLoader()
/// let config = await loader.loadConfiguration(
///     repositoryURL: repoURL,
///     fallbackConfiguration: MyAppConfiguration()
/// )
/// ```
public actor ConfigurationLoader {

    /// File name to look for in repository root
    public static let inRepoSchemaFileName = ".localization-schema.json"

    public init() {}

    /// Attempts to load configuration from repository, falling back to provided config.
    ///
    /// - Parameters:
    ///   - repositoryURL: URL to the repository root
    ///   - fallbackConfiguration: Configuration to use if no in-repo schema is found
    /// - Returns: The loaded configuration (in-repo if available, otherwise fallback)
    public func loadConfiguration(
        repositoryURL: URL,
        fallbackConfiguration: RepositoryConfiguration
    ) async -> RepositoryConfiguration {
        let schemaFileURL = repositoryURL.appendingPathComponent(Self.inRepoSchemaFileName)

        // Check for in-repo schema file
        if FileManager.default.fileExists(atPath: schemaFileURL.path),
           let inRepoConfig = try? await parseInRepoSchema(from: schemaFileURL) {
            return inRepoConfig
        }

        // Fall back to app-provided configuration
        return fallbackConfiguration
    }

    /// Parses an in-repository schema file.
    ///
    /// - Parameter url: URL to the schema file
    /// - Returns: Parsed configuration
    /// - Throws: If the file cannot be read or parsed
    public func parseInRepoSchema(from url: URL) async throws -> JSONRepositoryConfiguration {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(JSONRepositoryConfiguration.self, from: data)
    }

    /// Checks if a repository has an in-repo schema file.
    ///
    /// - Parameter repositoryURL: URL to the repository root
    /// - Returns: true if schema file exists
    public nonisolated func hasInRepoSchema(at repositoryURL: URL) -> Bool {
        let schemaFileURL = repositoryURL.appendingPathComponent(Self.inRepoSchemaFileName)
        return FileManager.default.fileExists(atPath: schemaFileURL.path)
    }
}
