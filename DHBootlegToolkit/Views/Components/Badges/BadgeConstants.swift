import SwiftUI

// MARK: - Badge Style Constants

/// Shared styling constants for all badge components
enum BadgeStyle {
    static let font: Font = .caption2.weight(.medium)
    static let cornerRadius: CGFloat = 4
    static let strokeOpacity: Double = 0.4
    static let strokeWidth: CGFloat = 1
    static let letterSize: CGFloat = 18
    static let counterPaddingH: CGFloat = 6
    static let counterPaddingV: CGFloat = 2
    static let iconSpacing: CGFloat = 3
    static let counterSpacing: CGFloat = 4

    // MARK: - Tooltip Text Constants

    /// Tooltip text for status badges
    enum StatusTooltip {
        static let added = "Added in current changes"
        static let modified = "Modified in current changes"
        static let deleted = "Deleted in current changes"
    }

    /// Tooltip text for type badges
    enum TypeTooltip {
        static let string = "String type"
        static let int = "Integer type"
        static let float = "Float type"
        static let bool = "Boolean type"
        static let null = "Null value"
        static let object = "Object type"
        static let array = "Array type"
        static let stringArray = "String array type"
        static let intArray = "Integer array type"
        static let any = "Unknown type"
    }
}
