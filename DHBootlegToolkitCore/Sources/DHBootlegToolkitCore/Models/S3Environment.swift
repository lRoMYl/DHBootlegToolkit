import Foundation

// MARK: - S3 Environment

/// Represents the deployment environment for S3 feature configurations
public enum S3Environment: String, CaseIterable, Sendable, Codable {
    case staging
    case production

    /// Display name for UI
    public var displayName: String {
        rawValue.capitalized
    }

    /// Folder name in the repository structure
    public var folderName: String {
        rawValue
    }
}
