import Foundation

/// Actor-based engine for generating market sentiment commentary (witty and positive)
public actor CommentaryEngine {
    // MARK: - Properties

    /// Track last used commentaries to avoid repetition
    private var lastCommentaries: [String: [String]] = [:]
    private let maxHistorySize = 3

    /// Track last sentiment change time for rotation logic
    private var lastRotation: [String: Date] = [:]
    private let rotationInterval: TimeInterval = 300 // 5 minutes

    /// Track previous price change for detecting major swings
    private var previousChangePercent: [String: Double] = [:]

    // MARK: - Public API

    public init() {}

    /// Calculate sentiment for a stock with dynamic commentary
    /// - Parameters:
    ///   - stockData: Full stock data for interpolation
    ///   - previousSentiment: Optional previous sentiment for comparison
    ///   - chartData: Optional chart data for dynamic threshold calculation
    ///   - timeRange: Time range of chart data (default: 3 months)
    /// - Returns: New market sentiment with emoji and interpolated commentary
    public func calculateSentiment(
        for stockData: StockData,
        previousSentiment: MarketSentiment?,
        chartData: [ChartDataPoint]? = nil,
        timeRange: ChartTimeRange = .threeMonths
    ) -> MarketSentiment {
        // Calculate dynamic or fixed thresholds
        let thresholds: DynamicThreshold
        if let chartData = chartData {
            thresholds = VolatilityCalculator.calculateThresholds(
                from: chartData,
                timeRange: timeRange
            )
        } else {
            thresholds = .fixed
        }

        // Determine category with thresholds
        let category = SentimentCategory.from(
            priceChangePercent: stockData.priceChangePercent,
            thresholds: thresholds
        )

        // Check if we should rotate commentary
        let shouldRotate = shouldRotateCommentary(
            for: stockData.symbol,
            priceChangePercent: stockData.priceChangePercent,
            previousCategory: previousSentiment?.category
        )

        let commentary: String
        let sourceURL: URL?
        let type: SentimentType
        if shouldRotate || previousSentiment == nil {
            let template = selectCommentaryTemplate(for: category, symbol: stockData.symbol)
            commentary = interpolate(template, with: stockData)
            sourceURL = SentimentCategory.sourceURL(for: template)

            // Determine type based on template source
            if SentimentCategory.specialContextualTemplates.contains(template) {
                type = .special
            } else if category.wittyCommentaryTemplates.contains(template) {
                type = .witty
            } else {
                type = .positive
            }

            lastRotation[stockData.symbol] = Date()
        } else {
            // Keep previous commentary and URL if no rotation needed
            commentary = previousSentiment?.commentary ?? {
                let template = selectCommentaryTemplate(for: category, symbol: stockData.symbol)
                return interpolate(template, with: stockData)
            }()
            sourceURL = previousSentiment?.sourceURL
            type = previousSentiment?.type ?? .positive
        }

        // Update tracking
        previousChangePercent[stockData.symbol] = stockData.priceChangePercent

        return MarketSentiment(
            emoji: category.emoji,
            commentary: commentary,
            category: category,
            sourceURL: sourceURL,
            type: type
        )
    }

    /// Clear history for a symbol (useful for testing)
    public func clearHistory(for symbol: String) {
        lastCommentaries[symbol] = nil
        lastRotation[symbol] = nil
        previousChangePercent[symbol] = nil
    }

    /// Force rotation of commentary for a symbol (user-triggered)
    /// - Parameters:
    ///   - stockData: Stock data to generate sentiment for
    ///   - chartData: Optional chart data for dynamic threshold calculation
    /// - Returns: New market sentiment with rotated commentary
    public func forceRotation(
        for stockData: StockData,
        chartData: [ChartDataPoint]? = nil
    ) -> MarketSentiment {
        // Calculate dynamic or fixed thresholds
        let thresholds: DynamicThreshold
        if let chartData = chartData {
            thresholds = VolatilityCalculator.calculateThresholds(
                from: chartData,
                timeRange: .threeMonths
            )
        } else {
            thresholds = .fixed
        }

        // Determine category with thresholds
        let category = SentimentCategory.from(
            priceChangePercent: stockData.priceChangePercent,
            thresholds: thresholds
        )

        // Select new commentary template
        let template = selectCommentaryTemplate(for: category, symbol: stockData.symbol)
        let commentary = interpolate(template, with: stockData)
        let sourceURL = SentimentCategory.sourceURL(for: template)

        // Determine type based on template source
        let type: SentimentType
        if SentimentCategory.specialContextualTemplates.contains(template) {
            type = .special
        } else if category.wittyCommentaryTemplates.contains(template) {
            type = .witty
        } else {
            type = .positive
        }

        // Reset rotation timer
        lastRotation[stockData.symbol] = Date()
        previousChangePercent[stockData.symbol] = stockData.priceChangePercent

        return MarketSentiment(
            emoji: category.emoji,
            commentary: commentary,
            category: category,
            sourceURL: sourceURL,
            type: type
        )
    }

    // MARK: - Commentary Selection & Interpolation

    private func selectCommentaryTemplate(for category: SentimentCategory, symbol: String) -> String {
        // 10% chance to use special contextual template
        if Double.random(in: 0..<1) < 0.1 {
            return SentimentCategory.specialContextualTemplates.randomElement() ?? category.commentaryTemplates.first ?? "..."
        }

        let pool = category.commentaryTemplates
        let history = lastCommentaries[symbol] ?? []

        // Filter out recently used templates
        let available = pool.filter { !history.contains($0) }

        // If all have been used, reset history
        let candidates = available.isEmpty ? pool : available

        // Select random template
        let selected = candidates.randomElement() ?? pool.first ?? "..."

        // Update history
        var updatedHistory = history
        updatedHistory.append(selected)

        // Keep only last N templates
        if updatedHistory.count > maxHistorySize {
            updatedHistory.removeFirst()
        }

        lastCommentaries[symbol] = updatedHistory

        return selected
    }

    /// Interpolate template placeholders with actual stock data
    private func interpolate(_ template: String, with data: StockData) -> String {
        var result = template

        // Replace placeholders with actual values
        if let percentFromPeak = data.absPercentFromPeak {
            result = result.replacingOccurrences(of: "{percentFromPeak}", with: percentFromPeak)
        }

        if let allTimeHigh = data.formattedAllTimeHigh {
            result = result.replacingOccurrences(of: "{allTimeHigh}", with: allTimeHigh)
        }

        result = result.replacingOccurrences(of: "{currentPrice}", with: data.formattedCurrentPrice)
        result = result.replacingOccurrences(of: "{currency}", with: data.currencySymbol)
        result = result.replacingOccurrences(of: "{symbol}", with: data.symbol)

        return result
    }

    // MARK: - Rotation Logic

    private func shouldRotateCommentary(
        for symbol: String,
        priceChangePercent: Double,
        previousCategory: SentimentCategory?
    ) -> Bool {
        let currentCategory = SentimentCategory.from(priceChangePercent: priceChangePercent)

        // Always rotate if category changed
        if let previous = previousCategory, previous != currentCategory {
            return true
        }

        // Rotate on major swing (>2% change from last rotation)
        if let previousPercent = previousChangePercent[symbol] {
            let percentDelta = abs(priceChangePercent - previousPercent)
            if percentDelta > 2.0 {
                return true
            }
        }

        // Rotate after time interval
        if let lastRotationTime = lastRotation[symbol] {
            let timeSinceRotation = Date().timeIntervalSince(lastRotationTime)
            if timeSinceRotation >= rotationInterval {
                return true
            }
        }

        return false
    }
}

// MARK: - Testing Support

#if DEBUG
extension CommentaryEngine {
    /// Get commentary history for testing
    public func getHistory(for symbol: String) -> [String] {
        lastCommentaries[symbol] ?? []
    }

    /// Test commentary selection without side effects
    public func previewCommentary(for category: SentimentCategory) -> String {
        category.commentaryTemplates.randomElement() ?? "..."
    }
}
#endif
