import Foundation

/// Centralized definition of tracked stock symbols
public enum StockSymbol: String, CaseIterable, Sendable, Identifiable {
    case deliveryHero = "DHER.DE"
    case talabat = "TALABAT.AE"

    public var id: String { rawValue }

    // MARK: - Display Properties

    /// Human-readable name
    public var displayName: String {
        switch self {
        case .deliveryHero:
            return "Delivery Hero"
        case .talabat:
            return "Talabat"
        }
    }

    /// Stock symbol (ticker)
    public var ticker: String {
        rawValue
    }

    // MARK: - Currency & Exchange

    /// Currency symbol for this stock
    public var currencySymbol: String {
        switch self {
        case .deliveryHero:
            return "€"
        case .talabat:
            return "AED"
        }
    }

    /// Currency code (ISO 4217)
    public var currencyCode: String {
        switch self {
        case .deliveryHero:
            return "EUR"
        case .talabat:
            return "AED"
        }
    }

    /// Exchange name
    public var exchange: String {
        switch self {
        case .deliveryHero:
            return "XETRA"
        case .talabat:
            return "DFM" // Dubai Financial Market
        }
    }

    // MARK: - Historical Data

    /// All-time high price
    public var allTimeHigh: Decimal {
        switch self {
        case .deliveryHero:
            return 145.40
        case .talabat:
            return 1.60
        }
    }

    /// Date of all-time high
    public var allTimeHighDate: Date {
        switch self {
        case .deliveryHero:
            return Date(timeIntervalSince1970: 1539388800) // Oct 2018
        case .talabat:
            return Date(timeIntervalSince1970: 1733011200) // Dec 2024
        }
    }

    // MARK: - Convenience Methods

    /// All tracked symbols as array of strings
    public static var allTickers: [String] {
        allCases.map(\.rawValue)
    }

    /// Check if string matches this symbol
    public func matches(_ string: String) -> Bool {
        rawValue == string
    }

    /// Initialize from ticker string (case-insensitive)
    public init?(ticker: String) {
        if let symbol = Self.allCases.first(where: { $0.rawValue.lowercased() == ticker.lowercased() }) {
            self = symbol
        } else {
            return nil
        }
    }
}
