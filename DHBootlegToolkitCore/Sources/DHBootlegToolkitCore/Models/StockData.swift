import Foundation

/// Represents a single price point in historical chart data
public struct ChartDataPoint: Sendable, Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let open: Decimal?
    public let high: Decimal?
    public let low: Decimal?
    public let close: Decimal
    public let volume: Int64?

    public init(
        timestamp: Date,
        open: Decimal? = nil,
        high: Decimal? = nil,
        low: Decimal? = nil,
        close: Decimal,
        volume: Int64? = nil
    ) {
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

/// Represents a selected range on the chart for comparison
public struct ChartRangeSelection: Equatable, Sendable {
    public let startDate: Date
    public let endDate: Date
    public let startPrice: Decimal
    public let endPrice: Decimal

    public init(startDate: Date, endDate: Date, startPrice: Decimal, endPrice: Decimal) {
        self.startDate = startDate
        self.endDate = endDate
        self.startPrice = startPrice
        self.endPrice = endPrice
    }

    public var priceChange: Decimal {
        endPrice - startPrice
    }

    public var percentChange: Double {
        guard startPrice > 0 else { return 0 }
        let change = (endPrice - startPrice) / startPrice * 100
        return change.doubleValue
    }

    public var isPositive: Bool {
        priceChange >= 0
    }
}

/// Time range options for stock chart display
public enum ChartTimeRange: String, CaseIterable, Sendable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case yearToDate = "YTD"
    case oneYear = "1Y"
    case twoYears = "2Y"
    case fiveYears = "5Y"
    case tenYears = "10Y"
    case all = "All"

    /// Yahoo Finance API range parameter
    public var apiRange: String {
        switch self {
        case .oneDay: return "1d"
        case .oneWeek: return "5d"
        case .oneMonth: return "1mo"
        case .threeMonths: return "3mo"
        case .sixMonths: return "6mo"
        case .yearToDate: return "ytd"
        case .oneYear: return "1y"
        case .twoYears: return "2y"
        case .fiveYears: return "5y"
        case .tenYears: return "10y"
        case .all: return "max"
        }
    }

    /// Yahoo Finance API interval parameter
    public var apiInterval: String {
        switch self {
        case .oneDay: return "1m"
        case .oneWeek: return "5m"
        case .oneMonth: return "30m"
        case .threeMonths, .sixMonths, .yearToDate, .oneYear: return "1d"
        case .twoYears, .fiveYears: return "1wk"
        case .tenYears, .all: return "1mo"
        }
    }
}

/// Stock market data for a single security
public struct StockData: Sendable, Identifiable {
    public let id: String  // Same as symbol for convenience
    public let symbol: String
    public let currentPrice: Decimal
    public let priceChange: Decimal
    public let priceChangePercent: Double
    public let volume: Int64
    public let dayHigh: Decimal
    public let dayLow: Decimal
    public let marketCap: Int64?
    public let previousClose: Decimal
    public let lastUpdated: Date

    // Historical data for context-aware commentary
    public let fiftyTwoWeekHigh: Decimal?
    public let fiftyTwoWeekLow: Decimal?
    public let allTimeHigh: Decimal?
    public let allTimeHighDate: Date?

    // Historical chart data points
    public let chartData: [ChartDataPoint]?

    // Trading hours and timezone information
    public let regularMarketTime: Date?
    public let marketStartTime: Date?
    public let marketEndTime: Date?
    public let exchangeTimezoneName: String?
    public let gmtOffset: Int?

    public init(
        symbol: String,
        currentPrice: Decimal,
        priceChange: Decimal,
        priceChangePercent: Double,
        volume: Int64,
        dayHigh: Decimal,
        dayLow: Decimal,
        marketCap: Int64?,
        previousClose: Decimal,
        lastUpdated: Date,
        fiftyTwoWeekHigh: Decimal? = nil,
        fiftyTwoWeekLow: Decimal? = nil,
        allTimeHigh: Decimal? = nil,
        allTimeHighDate: Date? = nil,
        chartData: [ChartDataPoint]? = nil,
        regularMarketTime: Date? = nil,
        marketStartTime: Date? = nil,
        marketEndTime: Date? = nil,
        exchangeTimezoneName: String? = nil,
        gmtOffset: Int? = nil
    ) {
        self.id = symbol
        self.symbol = symbol
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.priceChangePercent = priceChangePercent
        self.volume = volume
        self.dayHigh = dayHigh
        self.dayLow = dayLow
        self.marketCap = marketCap
        self.previousClose = previousClose
        self.lastUpdated = lastUpdated
        self.fiftyTwoWeekHigh = fiftyTwoWeekHigh
        self.fiftyTwoWeekLow = fiftyTwoWeekLow
        self.allTimeHigh = allTimeHigh
        self.allTimeHighDate = allTimeHighDate
        self.chartData = chartData
        self.regularMarketTime = regularMarketTime
        self.marketStartTime = marketStartTime
        self.marketEndTime = marketEndTime
        self.exchangeTimezoneName = exchangeTimezoneName
        self.gmtOffset = gmtOffset
    }

    // MARK: - Computed Properties

    /// True if price is up from previous close
    public var isUp: Bool {
        priceChange > 0
    }

    /// True if price is down from previous close
    public var isDown: Bool {
        priceChange < 0
    }

    /// True if price change is minimal (< 1%)
    public var isFlat: Bool {
        abs(priceChangePercent) < 1.0
    }

    /// Percentage from all-time high (negative value)
    public var percentageFromAllTimeHigh: Double? {
        guard let ath = allTimeHigh else { return nil }
        let athDouble = (ath as NSDecimalNumber).doubleValue
        let currentDouble = (currentPrice as NSDecimalNumber).doubleValue
        return ((currentDouble - athDouble) / athDouble) * 100
    }

    // MARK: - Formatting Helpers

    /// Formatted price string with currency symbol
    public var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = currencySymbol  // Explicitly set symbol to override locale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: currentPrice as NSDecimalNumber) ?? "\(currentPrice)"
    }

    /// Formatted change percentage with sign
    public var formattedChangePercent: String {
        let sign = priceChangePercent >= 0 ? "+" : ""
        return String(format: "\(sign)%.2f%%", priceChangePercent)
    }

    /// Formatted volume with abbreviations (K, M, B)
    public var formattedVolume: String {
        formatLargeNumber(volume)
    }

    /// Formatted market cap with abbreviations
    public var formattedMarketCap: String? {
        guard let marketCap = marketCap else { return nil }
        return formatLargeNumber(marketCap)
    }

    /// Arrow indicator for price direction
    public var directionArrow: String {
        if isUp {
            return "↑"
        } else if isDown {
            return "↓"
        } else {
            return "→"
        }
    }

    // MARK: - Commentary Template Helpers

    /// Currency symbol for this stock
    public var currencySymbol: String {
        StockSymbol(ticker: symbol)?.currencySymbol ?? "$"
    }

    /// Formatted all-time high with currency symbol (for templates)
    public var formattedAllTimeHigh: String? {
        guard let ath = allTimeHigh else { return nil }
        return "\(currencySymbol)\(String(format: "%.0f", (ath as NSDecimalNumber).doubleValue))"
    }

    /// Formatted current price with currency symbol (for templates)
    public var formattedCurrentPrice: String {
        "\(currencySymbol)\(String(format: "%.0f", (currentPrice as NSDecimalNumber).doubleValue))"
    }

    /// Absolute percentage from peak (positive value for templates)
    public var absPercentFromPeak: String? {
        guard let pct = percentageFromAllTimeHigh else { return nil }
        return String(format: "%.0f", abs(pct))
    }

    /// Formatted trading hours string (e.g., "09:00 - 17:30 CET")
    public var formattedTradingHours: String? {
        guard let start = marketStartTime,
              let end = marketEndTime,
              let timezone = exchangeTimezoneName else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: timezone)

        let startTime = formatter.string(from: start)
        let endTime = formatter.string(from: end)

        // Extract timezone abbreviation (e.g., "CET", "EST")
        let timezoneAbbr = TimeZone(identifier: timezone)?.abbreviation() ?? ""

        return "\(startTime) - \(endTime) \(timezoneAbbr)"
    }

    /// Formatted trading hours in local timezone (e.g., "03:00 - 11:30 EST")
    /// Returns nil if timezone is same as market timezone
    public var formattedTradingHoursLocal: String? {
        guard let start = marketStartTime,
              let end = marketEndTime,
              let marketTimezone = exchangeTimezoneName else {
            return nil
        }

        let localTimezone = TimeZone.current

        // Don't show local time if it's the same as market timezone
        guard localTimezone.identifier != marketTimezone else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = localTimezone

        let startTime = formatter.string(from: start)
        let endTime = formatter.string(from: end)

        // Extract timezone abbreviation
        let timezoneAbbr = localTimezone.abbreviation() ?? ""

        return "\(startTime) - \(endTime) \(timezoneAbbr)"
    }

    /// Check if the market is currently open based on trading hours
    /// Returns nil if trading hours information is not available
    public var isMarketOpen: Bool? {
        guard let startTime = marketStartTime,
              let endTime = marketEndTime,
              let timezoneName = exchangeTimezoneName,
              let timezone = TimeZone(identifier: timezoneName) else {
            return nil
        }

        // Get current time in market timezone
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let now = Date()

        // Extract hour and minute components from start and end times
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)

        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute,
              let nowHour = nowComponents.hour,
              let nowMinute = nowComponents.minute else {
            return nil
        }

        // Convert to minutes since midnight for easy comparison
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        let nowMinutes = nowHour * 60 + nowMinute

        // Check if current time falls within market hours
        return nowMinutes >= startMinutes && nowMinutes <= endMinutes
    }

    // MARK: - Private Helpers

    private var currencyCode: String {
        StockSymbol(ticker: symbol)?.currencyCode ?? "USD"
    }

    private func formatLargeNumber(_ number: Int64) -> String {
        let absNumber = abs(Double(number))
        let sign = number < 0 ? "-" : ""

        switch absNumber {
        case 1_000_000_000...:
            return String(format: "\(sign)%.1fB", absNumber / 1_000_000_000)
        case 1_000_000...:
            return String(format: "\(sign)%.1fM", absNumber / 1_000_000)
        case 1_000...:
            return String(format: "\(sign)%.1fK", absNumber / 1_000)
        default:
            return "\(sign)\(Int(absNumber))"
        }
    }
}

// MARK: - Extensions

extension Decimal {
    /// Convert Decimal to Double for chart rendering
    public var doubleValue: Double {
        (self as NSDecimalNumber).doubleValue
    }
}

// MARK: - Mock Data (for development/testing)

#if DEBUG
extension StockData {
    /// Mock DHER.DE data for previews
    public static let mockDHER = StockData(
        symbol: StockSymbol.deliveryHero.ticker,
        currentPrice: 23.45,
        priceChange: 0.56,
        priceChangePercent: 2.45,
        volume: 1_234_567,
        dayHigh: 23.67,
        dayLow: 22.89,
        marketCap: 2_345_678_900,
        previousClose: 22.89,
        lastUpdated: Date(),
        fiftyTwoWeekHigh: 35.20,
        fiftyTwoWeekLow: 20.10,
        allTimeHigh: StockSymbol.deliveryHero.allTimeHigh,
        allTimeHighDate: StockSymbol.deliveryHero.allTimeHighDate
    )

    /// Mock TALABAT data for previews
    public static let mockTALABAT = StockData(
        symbol: StockSymbol.talabat.ticker,
        currentPrice: 0.961,
        priceChange: -0.045,
        priceChangePercent: -3.52,
        volume: 987_654,
        dayHigh: 1.05,
        dayLow: 0.95,
        marketCap: 1_500_000_000,
        previousClose: 1.006,
        lastUpdated: Date(),
        fiftyTwoWeekHigh: 1.60,
        fiftyTwoWeekLow: 0.92,
        allTimeHigh: StockSymbol.talabat.allTimeHigh,
        allTimeHighDate: StockSymbol.talabat.allTimeHighDate
    )
}
#endif
