import Foundation

// MARK: - DynamicThreshold

/// Dynamic threshold values for sentiment categorization based on volatility
public struct DynamicThreshold: Sendable, Equatable {
    /// Threshold for moonshot category (≥ this value)
    public let moonshot: Double

    /// Lower threshold for gains category (> this value)
    public let gainsLower: Double

    /// Lower threshold for flat category (> this value)
    public let flatLower: Double

    /// Upper threshold for flat category (< this value)
    public let flatUpper: Double

    /// Upper threshold for gains category (< this value)
    public let gainsUpper: Double

    /// Lower threshold for losses category (> this value)
    public let lossesLower: Double

    /// Threshold for crash category (≤ this value)
    public let crash: Double

    /// Whether these are fixed or dynamically calculated thresholds
    public let isFixed: Bool

    /// The volatility ratio used (if dynamic)
    public let volatilityRatio: Double?

    /// Source of the threshold calculation
    public let source: Source

    /// Source of threshold calculation
    public enum Source: Sendable, Equatable {
        case dynamic(timeRange: ChartTimeRange, dataPoints: Int, volatilityRatio: Double)
        case fixed(reason: String)
    }

    /// Fixed baseline thresholds (fallback when no data available)
    public static let fixed = DynamicThreshold(
        moonshot: 5.0,
        gainsLower: 1.0,
        flatLower: -1.0,
        flatUpper: 1.0,
        gainsUpper: 5.0,
        lossesLower: -5.0,
        crash: -5.0,
        isFixed: true,
        volatilityRatio: nil,
        source: .fixed(reason: "Baseline fixed thresholds")
    )

    public init(
        moonshot: Double,
        gainsLower: Double,
        flatLower: Double,
        flatUpper: Double,
        gainsUpper: Double,
        lossesLower: Double,
        crash: Double,
        isFixed: Bool,
        volatilityRatio: Double?,
        source: Source
    ) {
        self.moonshot = moonshot
        self.gainsLower = gainsLower
        self.flatLower = flatLower
        self.flatUpper = flatUpper
        self.gainsUpper = gainsUpper
        self.lossesLower = lossesLower
        self.crash = crash
        self.isFixed = isFixed
        self.volatilityRatio = volatilityRatio
        self.source = source
    }
}

// MARK: - VolatilityCalculator

/// Calculator for stock volatility and dynamic sentiment thresholds
public struct VolatilityCalculator {

    // MARK: - Constants

    /// Baseline annualized volatility (30% = typical equity volatility)
    private static let baselineVolatility: Double = 0.30

    /// Minimum volatility ratio (prevents over-sensitivity)
    private static let minVolatilityRatio: Double = 0.5

    /// Maximum volatility ratio (tighter constraint to prevent overly wide thresholds)
    private static let maxVolatilityRatio: Double = 1.5

    /// Trading days per year for annualization
    private static let tradingDaysPerYear: Double = 252.0

    // MARK: - Public API

    /// Calculate dynamic thresholds from historical chart data
    ///
    /// - Parameters:
    ///   - chartData: Array of chart data points with close prices
    ///   - timeRange: Time range of the data (for metadata)
    ///   - minDataPoints: Minimum data points required for calculation (default: 30)
    /// - Returns: Dynamic thresholds or fixed fallback if insufficient data
    public static func calculateThresholds(
        from chartData: [ChartDataPoint],
        timeRange: ChartTimeRange,
        minDataPoints: Int = 30
    ) -> DynamicThreshold {

        // Validate sufficient data points
        guard chartData.count >= minDataPoints else {
            return DynamicThreshold(
                moonshot: 5.0,
                gainsLower: 1.0,
                flatLower: -1.0,
                flatUpper: 1.0,
                gainsUpper: 5.0,
                lossesLower: -5.0,
                crash: -5.0,
                isFixed: true,
                volatilityRatio: nil,
                source: .fixed(reason: "Insufficient data points: \(chartData.count) < \(minDataPoints)")
            )
        }

        // Calculate daily returns
        let returns = calculateDailyReturns(from: chartData)

        guard !returns.isEmpty else {
            return DynamicThreshold(
                moonshot: 5.0,
                gainsLower: 1.0,
                flatLower: -1.0,
                flatUpper: 1.0,
                gainsUpper: 5.0,
                lossesLower: -5.0,
                crash: -5.0,
                isFixed: true,
                volatilityRatio: nil,
                source: .fixed(reason: "No valid returns calculated")
            )
        }

        // Calculate standard deviation
        let mean = returns.reduce(0.0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(returns.count)
        let stdDev = sqrt(variance)

        // Annualize volatility
        let annualizedVol = stdDev * sqrt(tradingDaysPerYear)

        // Calculate volatility ratio
        let rawRatio = annualizedVol / baselineVolatility
        let boundedRatio = min(max(rawRatio, minVolatilityRatio), maxVolatilityRatio)

        // Scale fixed thresholds by volatility ratio
        let thresholds = DynamicThreshold(
            moonshot: 5.0 * boundedRatio,
            gainsLower: 1.0 * boundedRatio,
            flatLower: -1.0 * boundedRatio,
            flatUpper: 1.0 * boundedRatio,
            gainsUpper: 5.0 * boundedRatio,
            lossesLower: -5.0 * boundedRatio,
            crash: -5.0 * boundedRatio,
            isFixed: false,
            volatilityRatio: boundedRatio,
            source: .dynamic(
                timeRange: timeRange,
                dataPoints: chartData.count,
                volatilityRatio: boundedRatio
            )
        )

        return thresholds
    }

    /// Calculate annualized volatility from chart data
    ///
    /// - Parameter chartData: Array of chart data points with close prices
    /// - Returns: Annualized volatility as a decimal (e.g., 0.30 = 30%), or nil if calculation fails
    public static func calculateAnnualizedVolatility(
        from chartData: [ChartDataPoint]
    ) -> Double? {

        let returns = calculateDailyReturns(from: chartData)

        guard !returns.isEmpty else {
            return nil
        }

        // Calculate standard deviation
        let mean = returns.reduce(0.0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(returns.count)
        let stdDev = sqrt(variance)

        // Annualize
        return stdDev * sqrt(tradingDaysPerYear)
    }

    // MARK: - Private Helpers

    /// Calculate daily returns from price series
    ///
    /// - Parameter chartData: Array of chart data points with close prices
    /// - Returns: Array of daily returns as decimals (e.g., 0.02 = 2% gain)
    private static func calculateDailyReturns(
        from chartData: [ChartDataPoint]
    ) -> [Double] {

        guard chartData.count > 1 else {
            return []
        }

        var returns: [Double] = []

        for i in 1..<chartData.count {
            let currentClose = (chartData[i].close as NSDecimalNumber).doubleValue
            let previousClose = (chartData[i-1].close as NSDecimalNumber).doubleValue

            // Skip if previous close is zero (avoid division by zero)
            guard previousClose > 0 else {
                continue
            }

            let dailyReturn = (currentClose - previousClose) / previousClose
            returns.append(dailyReturn)
        }

        return returns
    }
}
