import Foundation

/// Represents a GEID (Global Entity ID) mapping with metadata
public struct GEIDMapping: Sendable, Equatable {
    public let geid: String
    public let countryCode: String          // Directory code (e.g., "op", "po", "mj", "sg")
    public let isoCountryCode: String       // ISO 3166-1 alpha-2 code (e.g., "se", "fi", "at")
    public let countryName: String
    public let brandName: String
    public let status: GEIDStatus
    public let replacementGEID: String?
    public let notes: String?

    public enum GEIDStatus: String, Sendable, Equatable {
        case active
        case deprecated
        case closed
        case migrated
    }

    public init(
        geid: String,
        countryCode: String,
        isoCountryCode: String? = nil,  // Optional - defaults to countryCode
        countryName: String,
        brandName: String,
        status: GEIDStatus,
        replacementGEID: String? = nil,
        notes: String? = nil
    ) {
        self.geid = geid
        self.countryCode = countryCode
        self.isoCountryCode = isoCountryCode ?? countryCode  // Default to countryCode if not provided
        self.countryName = countryName
        self.brandName = brandName
        self.status = status
        self.replacementGEID = replacementGEID
        self.notes = notes
    }
}

/// Central registry for all GEID mappings
public struct GEIDRegistry {
    /// All GEID mappings (active + deprecated)
    public static let allMappings: [GEIDMapping] = [
        // Active GEIDs (20 entries)
        GEIDMapping(geid: "FO_NO", countryCode: "no", countryName: "Norway", brandName: "foodora", status: .active),
        GEIDMapping(geid: "FP_BD", countryCode: "bd", countryName: "Bangladesh", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "FP_SG", countryCode: "sg", countryName: "Singapore", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "FP_HK", countryCode: "hk", countryName: "Hong Kong", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "FP_MY", countryCode: "my", countryName: "Malaysia", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "FP_PK", countryCode: "pk", countryName: "Pakistan", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "FP_PH", countryCode: "ph", countryName: "Philippines", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "FP_TW", countryCode: "tw", countryName: "Taiwan", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "FP_TH", countryCode: "th", countryName: "Thailand", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "OP_SE", countryCode: "op", isoCountryCode: "se", countryName: "Sweden", brandName: "foodora", status: .active, notes: "Previously onlinepizza"),
        GEIDMapping(geid: "PO_FI", countryCode: "po", isoCountryCode: "fi", countryName: "Finland", brandName: "foodora", status: .active, notes: "Previously pizzaonline"),
        GEIDMapping(geid: "FP_KH", countryCode: "kh", countryName: "Cambodia", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "FP_LA", countryCode: "la", countryName: "Laos", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "FP_MM", countryCode: "mm", countryName: "Myanmar", brandName: "foodpanda", status: .active),
        GEIDMapping(geid: "DJ_CZ", countryCode: "cz", countryName: "Czech Republic", brandName: "foodora", status: .active, notes: "Previously Dáme jídlo"),
        GEIDMapping(geid: "NP_HU", countryCode: "hu", countryName: "Hungary", brandName: "foodora", status: .active, notes: "Previously Netpincér"),
        GEIDMapping(geid: "MJM_AT", countryCode: "mj", isoCountryCode: "at", countryName: "Austria", brandName: "foodora", status: .active, notes: "Previously mjam"),
        GEIDMapping(geid: "FP_DE", countryCode: "dl", isoCountryCode: "de", countryName: "Germany", brandName: "foodora", status: .active, notes: "Previously Foodpanda EU"),
        GEIDMapping(geid: "YS_TR", countryCode: "tr", countryName: "Turkey", brandName: "yemeksepeti", status: .active),

        // Deprecated GEIDs (9 entries)
        GEIDMapping(geid: "FO_FI", countryCode: "fi", countryName: "Finland", brandName: "foodora",
                    status: .deprecated, replacementGEID: "PO_FI", notes: "Replaced by PO_FI"),
        GEIDMapping(geid: "FO_SE", countryCode: "se", countryName: "Sweden", brandName: "foodora",
                    status: .deprecated, replacementGEID: "OP_SE", notes: "Replaced by OP_SE"),
        GEIDMapping(geid: "FO_AT", countryCode: "at", countryName: "Austria", brandName: "foodora",
                    status: .deprecated, replacementGEID: "MJM_AT", notes: "Replaced by MJM_AT"),
        GEIDMapping(geid: "FO_CA", countryCode: "ca", countryName: "Canada", brandName: "foodora",
                    status: .closed, notes: "Closed"),
        GEIDMapping(geid: "FO_DE", countryCode: "de", countryName: "Germany", brandName: "foodora",
                    status: .closed, replacementGEID: "FP_DE", notes: "Closed, FP_DE opened later"),
        GEIDMapping(geid: "FP_RO", countryCode: "ro", countryName: "Romania", brandName: "foodpanda",
                    status: .migrated, notes: "Migrated to Glovo"),
        GEIDMapping(geid: "FP_BG", countryCode: "bg", countryName: "Bulgaria", brandName: "foodpanda",
                    status: .migrated, notes: "Migrated to Glovo"),
        GEIDMapping(geid: "FP_JP", countryCode: "jp", countryName: "Japan", brandName: "foodpanda",
                    status: .closed, notes: "Closed"),
        GEIDMapping(geid: "FP_SK", countryCode: "sk", countryName: "Slovakia", brandName: "foodpanda",
                    status: .closed, notes: "Closed"),
        GEIDMapping(geid: "HN_DK", countryCode: "dk", countryName: "Denmark", brandName: "hungry",
                    status: .closed, notes: "Closed"),
    ]

    // MARK: - Cached Lookup Dictionaries (O(1) access)

    /// Cached dictionary for active GEIDs by country code
    private static let activeGEIDsByCountryCode: [String: GEIDMapping] = {
        Dictionary(
            allMappings
                .filter { $0.status == .active }
                .map { ($0.countryCode, $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }()

    /// Cached dictionary for deprecated/closed/migrated GEIDs by country code
    private static let deprecatedGEIDsByCountryCode: [String: [GEIDMapping]] = {
        Dictionary(
            grouping: allMappings.filter { $0.status != .active },
            by: { $0.countryCode }
        )
    }()

    // MARK: - Lookup Methods

    /// Lookup active GEID by country code - O(1) dictionary lookup
    public static func activeGEID(forCountryCode code: String) -> GEIDMapping? {
        activeGEIDsByCountryCode[code]
    }

    /// Lookup deprecated GEIDs for a country code - O(1) dictionary lookup
    public static func deprecatedGEIDs(forCountryCode code: String) -> [GEIDMapping] {
        deprecatedGEIDsByCountryCode[code] ?? []
    }

    /// Get flag emoji for country code
    public static func flagEmoji(forCountryCode code: String) -> String {
        // Try to find the GEID mapping to get the ISO country code
        if let mapping = activeGEID(forCountryCode: code) {
            return generateFlagEmoji(from: mapping.isoCountryCode)
        }

        // Fallback: assume the code is already an ISO code
        return generateFlagEmoji(from: code)
    }

    /// Generate flag emoji from ISO country code (e.g., "se" → "🇸🇪")
    private static func generateFlagEmoji(from isoCode: String) -> String {
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in isoCode.uppercased().unicodeScalars {
            if let unicodeScalar = UnicodeScalar(base + scalar.value) {
                emoji.append(String(unicodeScalar))
            }
        }
        return emoji
    }
}
