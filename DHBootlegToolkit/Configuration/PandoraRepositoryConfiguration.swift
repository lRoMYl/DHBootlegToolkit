import Foundation
import SwiftUI
import DHBootlegToolkitCore

/// Configuration for the Pandora localization repository.
///
/// This configuration defines the structure expected for Pandora's
/// translation repositories, with mobile and web platforms.
struct PandoraRepositoryConfiguration: RepositoryConfiguration {
    let basePath = "translations/pandora/project"

    let platforms: [PlatformDefinition] = [
        .mobile,
        .web
    ]

    let entitySchema: EntitySchema = .translation
}

// MARK: - Type Aliases for Backward Compatibility

/// Alias for TranslationEntity to maintain existing code compatibility.
typealias TranslationKey = TranslationEntity

/// Alias for EntityDiff to maintain existing code compatibility.
typealias TranslationKeyDiff = EntityDiff

/// Alias for EntityChangeStatus to maintain existing code compatibility.
typealias KeyChangeStatus = EntityChangeStatus

/// Alias for PlatformDefinition to maintain existing code compatibility.
typealias Platform = PlatformDefinition

// MARK: - Platform Extension for CaseIterable-like behavior

extension PlatformDefinition {
    /// All available platforms for this app.
    static var allCases: [PlatformDefinition] {
        [.mobile, .web]
    }
}

// MARK: - EntityChangeStatus UI Extensions

extension EntityChangeStatus {
    /// Color for displaying the change status in the UI.
    var color: Color {
        switch self {
        case .added: return .green
        case .modified: return .orange
        case .deleted: return .red
        case .unchanged: return .clear
        }
    }
}

// MARK: - FeatureFolder Compatibility

extension FeatureFolder {
    /// Alias for backward compatibility with en.json references.
    var enJsonURL: URL {
        primaryLanguageFileURL
    }

    /// Alias for backward compatibility with images folder references.
    var imagesFolderURL: URL {
        assetsFolderURL
    }
}
