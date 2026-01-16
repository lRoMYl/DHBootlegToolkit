import Foundation
import DHBootlegToolkitCore

/// Configuration for S3 feature config repositories.
///
/// This is a minimal configuration to enable GitWorker integration
/// for git-based discard operations in the S3 feature config editor.
struct S3RepositoryConfiguration: RepositoryConfiguration {
    /// Base path for S3 feature configs (countries are stored under this path)
    let basePath = "static.fd-api.com/s3root/feature-config"

    /// S3 configs don't use platform folders - empty array
    let platforms: [PlatformDefinition] = []

    /// Primary config file name
    let primaryLanguageFile = "config.json"

    /// S3 configs don't use an assets folder
    let assetsFolderName = ""

    /// Folders to exclude during discovery
    let excludedFolders: Set<String> = [".git", "_schema", "node_modules"]

    /// Protected branches for git operations
    let protectedBranches: Set<String> = ["main", "master"]

    /// S3 configs allow any key names
    let keyValidationPattern = ".*"

    /// S3 configs don't use the translation entity schema
    let entitySchema: EntitySchema = .translation
}
