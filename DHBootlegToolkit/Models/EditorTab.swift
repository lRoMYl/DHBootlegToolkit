import Foundation
import DHBootlegToolkitCore

/// Represents an open tab in the editor.
/// Supports different content types: translation keys, images, and generic files.
enum EditorTab: Identifiable, Equatable {
    case key(KeyTabData)
    case image(ImageTabData)
    case textFile(TextTabData)
    case genericFile(GenericFileTabData)

    var id: UUID {
        switch self {
        case .key(let data): return data.id
        case .image(let data): return data.id
        case .textFile(let data): return data.id
        case .genericFile(let data): return data.id
        }
    }

    var featureId: String {
        switch self {
        case .key(let data): return data.featureId
        case .image(let data): return data.featureId
        case .textFile(let data): return data.featureId
        case .genericFile(let data): return data.featureId
        }
    }

    var displayName: String {
        switch self {
        case .key(let data): return data.keyName
        case .image(let data): return data.imageName
        case .textFile(let data): return data.fileName
        case .genericFile(let data): return data.fileName
        }
    }

    /// Returns true if this is a key tab
    var isKeyTab: Bool {
        if case .key = self { return true }
        return false
    }

    /// Returns true if this is an image tab
    var isImageTab: Bool {
        if case .image = self { return true }
        return false
    }

    /// Returns true if this is a text file tab
    var isTextFileTab: Bool {
        if case .textFile = self { return true }
        return false
    }

    /// Returns true if this is a generic file tab
    var isGenericFileTab: Bool {
        if case .genericFile = self { return true }
        return false
    }

    /// Returns the key data if this is a key tab
    var keyData: KeyTabData? {
        if case .key(let data) = self { return data }
        return nil
    }

    /// Returns the image data if this is an image tab
    var imageData: ImageTabData? {
        if case .image(let data) = self { return data }
        return nil
    }

    /// Returns the text file data if this is a text file tab
    var textFileData: TextTabData? {
        if case .textFile(let data) = self { return data }
        return nil
    }

    /// Returns the generic file data if this is a generic file tab
    var genericFileData: GenericFileTabData? {
        if case .genericFile(let data) = self { return data }
        return nil
    }

    static func == (lhs: EditorTab, rhs: EditorTab) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Key Tab Data

/// Data for a translation key tab
struct KeyTabData: Equatable {
    let id: UUID
    let keyId: UUID              // TranslationKey.id
    let keyName: String          // For display (cached at open time)
    let featureId: String        // FeatureFolder.id
    var editedKey: TranslationKey?  // Draft state per tab
    var hasChanges: Bool = false

    init(key: TranslationKey, featureId: String) {
        self.id = UUID()
        self.keyId = key.id
        self.keyName = key.key
        self.featureId = featureId
        self.editedKey = key
    }

    static func == (lhs: KeyTabData, rhs: KeyTabData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Image Tab Data

/// Data for an image preview tab
struct ImageTabData: Equatable {
    let id: UUID
    let imageURL: URL
    let imageName: String
    let featureId: String

    init(imageURL: URL, featureId: String) {
        self.id = UUID()
        self.imageURL = imageURL
        self.imageName = imageURL.lastPathComponent
        self.featureId = featureId
    }

    static func == (lhs: ImageTabData, rhs: ImageTabData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Text File Tab Data

/// Data for a text file tab (previewable text-based files)
struct TextTabData: Equatable {
    let id: UUID
    let fileURL: URL
    let fileName: String
    let fileExtension: String
    let featureId: String

    init(fileURL: URL, featureId: String) {
        self.id = UUID()
        self.fileURL = fileURL
        self.fileName = fileURL.lastPathComponent
        self.fileExtension = fileURL.pathExtension.lowercased()
        self.featureId = featureId
    }

    static func == (lhs: TextTabData, rhs: TextTabData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Generic File Tab Data

/// Data for a generic file tab (non-image, non-primary JSON files)
struct GenericFileTabData: Equatable {
    let id: UUID
    let fileURL: URL
    let fileName: String
    let fileExtension: String
    let iconName: String
    let featureId: String

    init(fileURL: URL, iconName: String, featureId: String) {
        self.id = UUID()
        self.fileURL = fileURL
        self.fileName = fileURL.lastPathComponent
        self.fileExtension = fileURL.pathExtension.lowercased()
        self.iconName = iconName
        self.featureId = featureId
    }

    static func == (lhs: GenericFileTabData, rhs: GenericFileTabData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - EditorTab Extensions

extension EditorTab {
    /// Creates a key tab from a translation key
    static func keyTab(key: TranslationKey, featureId: String) -> EditorTab {
        .key(KeyTabData(key: key, featureId: featureId))
    }

    /// Creates an image tab from an image URL
    static func imageTab(url: URL, featureId: String) -> EditorTab {
        .image(ImageTabData(imageURL: url, featureId: featureId))
    }

    /// Creates a text file tab from a file URL
    static func textFileTab(url: URL, featureId: String) -> EditorTab {
        .textFile(TextTabData(fileURL: url, featureId: featureId))
    }

    /// Creates a generic file tab from a file URL
    static func genericFileTab(url: URL, iconName: String, featureId: String) -> EditorTab {
        .genericFile(GenericFileTabData(fileURL: url, iconName: iconName, featureId: featureId))
    }
}
