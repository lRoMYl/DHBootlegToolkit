import Foundation

/// Represents a single translation entity in a localization file.
///
/// Each entity has a unique key name and associated content such as
/// the translation text, notes for translators, and optional metadata.
public struct TranslationEntity: Identifiable, Hashable, Sendable {
    /// Unique identifier for this entity instance
    public let id: UUID

    /// Key name used in the JSON file (e.g., "LOGIN_BUTTON")
    public var key: String

    /// Translated text content
    public var translation: String

    /// Notes for translators
    public var notes: String

    /// Optional list of target language codes
    public var targetLanguages: [String]?

    /// Optional character limit for the translation
    public var charLimit: Int?

    /// Whether this entity was newly created (not yet saved)
    public let isNew: Bool

    /// Whether the entity has all required fields filled
    public var isValid: Bool {
        !key.isEmpty && !translation.isEmpty && !notes.isEmpty
    }

    public init(
        id: UUID = UUID(),
        key: String = "",
        translation: String = "",
        notes: String = "",
        targetLanguages: [String]? = nil,
        charLimit: Int? = nil,
        isNew: Bool = false
    ) {
        self.id = id
        self.key = key
        self.translation = translation
        self.notes = notes
        self.targetLanguages = targetLanguages
        self.charLimit = charLimit
        self.isNew = isNew
    }
}

// MARK: - Key Validation

extension TranslationEntity {
    /// Validates the key format against the default pattern.
    ///
    /// The default pattern requires:
    /// - Start with a letter
    /// - Contain only letters, numbers, and underscores
    public var isKeyFormatValid: Bool {
        isKeyFormatValid(pattern: "^[A-Za-z][A-Za-z0-9_]*$")
    }

    /// Validates the key format against a custom pattern.
    public func isKeyFormatValid(pattern: String) -> Bool {
        guard !key.isEmpty else { return false }
        return key.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - JSON Encoding/Decoding

extension TranslationEntity {
    /// Decodes from the JSON format where keys are the entity key names.
    ///
    /// Expected format:
    /// ```json
    /// {
    ///   "KEY_NAME": {
    ///     "translation": "...",
    ///     "notes": "...",
    ///     "char_limit": 100,
    ///     "target_languages": ["de", "fr"]
    ///   }
    /// }
    /// ```
    public static func decode(from dictionary: [String: Any], key: String) -> TranslationEntity? {
        guard let translation = dictionary["translation"] as? String,
              let notes = dictionary["notes"] as? String else {
            return nil
        }

        let targetLanguages = dictionary["target_languages"] as? [String]
        let charLimit = dictionary["char_limit"] as? Int

        return TranslationEntity(
            key: key,
            translation: translation,
            notes: notes,
            targetLanguages: targetLanguages,
            charLimit: charLimit
        )
    }

    /// Encodes to dictionary for JSON serialization.
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "translation": translation,
            "notes": notes
        ]

        if let charLimit {
            dict["char_limit"] = charLimit
        }

        if let targetLanguages, !targetLanguages.isEmpty {
            dict["target_languages"] = targetLanguages
        }

        return dict
    }
}
