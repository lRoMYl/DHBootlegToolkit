import Foundation
import Observation
import DHBootlegToolkitCore

@Observable
@MainActor
final class StockTickerStore {
    // MARK: - Constants

    /// UserDefaults key for selected chart range persistence
    private static let selectedChartRangeKey = "selectedChartRange"

    // MARK: - State

    /// Current stock data by symbol
    var stocks: [String: StockData] = [:]

    /// Market sentiments by symbol
    var sentiments: [String: MarketSentiment] = [:]

    /// Connection status
    private(set) var isConnected: Bool = false

    /// Loading state
    private(set) var isLoading: Bool = false

    /// Error message (if any)
    private(set) var errorMessage: String?

    /// Currently selected stock symbol
    var selectedSymbol: String? = StockSymbol.deliveryHero.ticker

    /// Selected chart time range
    var selectedChartRange: ChartTimeRange = .oneDay

    /// Cached chart data by symbol and range
    private var chartDataCache: [String: [ChartTimeRange: [ChartDataPoint]]] = [:]

    /// Loading state for chart data
    private(set) var isLoadingChartData: Bool = false

    /// Cached dynamic thresholds by symbol
    private var thresholdCache: [String: DynamicThreshold] = [:]
    private var thresholdCacheTime: [String: Date] = [:]
    private let thresholdCacheDuration: TimeInterval = 3600 // 1 hour

    // MARK: - Constants

    private let symbols = StockSymbol.allTickers

    // MARK: - Dependencies

    private var yahooWorker: YahooFinanceWorker?
    private let commentaryEngine = CommentaryEngine()
    private var monitoringTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var selectedStock: StockData? {
        guard let symbol = selectedSymbol else { return nil }
        return stocks[symbol]
    }

    var selectedSentiment: MarketSentiment? {
        guard let symbol = selectedSymbol else { return nil }
        return sentiments[symbol]
    }

    var allStocks: [StockData] {
        Array(stocks.values).sorted { $0.symbol < $1.symbol }
    }

    /// Get current thresholds for the selected stock (for legend display)
    var currentThresholds: DynamicThreshold {
        guard let symbol = selectedSymbol else {
            return .fixed
        }

        // Use the user's selected chart range for threshold calculation
        let chartData = chartDataCache[symbol]?[selectedChartRange]
            ?? chartDataCache[symbol]?[.threeMonths]
            ?? chartDataCache[symbol]?[.oneMonth]
            ?? chartDataCache[symbol]?[.oneYear]

        // Determine which time range was actually used for calculation
        let usedTimeRange: ChartTimeRange
        if chartDataCache[symbol]?[selectedChartRange] != nil {
            usedTimeRange = selectedChartRange
        } else if chartDataCache[symbol]?[.threeMonths] != nil {
            usedTimeRange = .threeMonths
        } else if chartDataCache[symbol]?[.oneMonth] != nil {
            usedTimeRange = .oneMonth
        } else {
            usedTimeRange = .oneYear
        }

        if let chartData = chartData {
            return VolatilityCalculator.calculateThresholds(
                from: chartData,
                timeRange: usedTimeRange
            )
        } else {
            return .fixed
        }
    }

    // MARK: - Lifecycle

    init() {
        // Load cached data
        loadCachedData()
    }

    deinit {
        Task { [weak self] in
            await self?.stopMonitoring()
        }
    }

    // MARK: - Public API

    func startMonitoring() async {
        guard monitoringTask == nil else { return }

        isLoading = true
        errorMessage = nil

        // Create worker
        let worker = YahooFinanceWorker(symbols: symbols)
        yahooWorker = worker

        // Prefetch volatility data for all symbols
        for symbol in symbols {
            Task {
                await prefetchVolatilityData(for: symbol)
            }
        }

        // Start monitoring in background task
        monitoringTask = Task {
            do {
                let stream = await worker.startMonitoring()

                await MainActor.run {
                    self.isConnected = true
                    self.isLoading = false
                }

                // Process updates
                for await stockData in stream {
                    await MainActor.run {
                        self.updateStock(stockData)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopMonitoring() async {
        monitoringTask?.cancel()
        monitoringTask = nil

        if let worker = yahooWorker {
            await worker.stopMonitoring()
        }

        yahooWorker = nil
        isConnected = false
    }

    func selectStock(_ symbol: String) {
        selectedSymbol = symbol
    }

    /// Manually refresh stock data
    func refreshData() async {
        guard let worker = yahooWorker else { return }
        await worker.refreshData()
    }

    /// Rotate sentiment commentary (user-triggered)
    func rotateSentiment(for symbol: String) {
        guard let stockData = stocks[symbol] else { return }

        Task {
            // Get chart data for dynamic thresholds
            let chartData = chartDataCache[symbol]?[.threeMonths]
                ?? chartDataCache[symbol]?[.oneMonth]
                ?? chartDataCache[symbol]?[.oneYear]

            let newSentiment = await commentaryEngine.forceRotation(
                for: stockData,
                chartData: chartData
            )

            await MainActor.run {
                self.sentiments[symbol] = newSentiment
            }
        }
    }

    // MARK: - Chart Data Management

    /// Fetch chart data for a specific time range
    func fetchChartData(for symbol: String, range: ChartTimeRange) async {
        print("[StockTickerStore] fetchChartData called for \(symbol) range: \(range.rawValue)")

        guard let worker = yahooWorker else {
            print("[StockTickerStore] No worker available")
            return
        }

        // Check if already cached
        if chartDataCache[symbol]?[range] != nil {
            print("[StockTickerStore] Data already cached for \(symbol) \(range.rawValue)")
            return
        }

        print("[StockTickerStore] Starting fetch for \(symbol) \(range.rawValue)")
        isLoadingChartData = true

        do {
            let chartData = try await worker.fetchChartData(symbol: symbol, range: range)
            print("[StockTickerStore] Received \(chartData.count) points for \(symbol) \(range.rawValue)")

            // Update cache
            if chartDataCache[symbol] == nil {
                chartDataCache[symbol] = [:]
            }
            chartDataCache[symbol]?[range] = chartData
            isLoadingChartData = false
            print("[StockTickerStore] Cached data for \(symbol) \(range.rawValue)")
        } catch {
            print("[StockTickerStore] Error fetching chart data: \(error.localizedDescription)")
            isLoadingChartData = false
            errorMessage = "Failed to load chart data: \(error.localizedDescription)"
        }
    }

    /// Get cached chart data for the current selection
    func getChartData(for symbol: String) -> [ChartDataPoint]? {
        return chartDataCache[symbol]?[selectedChartRange]
    }

    /// Change chart time range and fetch data if needed
    func selectChartRange(_ range: ChartTimeRange) {
        print("[StockTickerStore] selectChartRange called: \(range.rawValue)")
        selectedChartRange = range

        // Persist the selection
        UserDefaults.standard.set(range.rawValue, forKey: Self.selectedChartRangeKey)

        // Fetch data if not cached
        if let symbol = selectedSymbol {
            print("[StockTickerStore] Selected symbol: \(symbol)")
            if chartDataCache[symbol]?[range] == nil {
                print("[StockTickerStore] Data not cached, will fetch")
                Task {
                    await fetchChartData(for: symbol, range: range)
                }
            } else {
                print("[StockTickerStore] Data already cached for \(symbol) \(range.rawValue)")
            }
        } else {
            print("[StockTickerStore] No selected symbol")
        }
    }

    // MARK: - Private Helpers

    private func updateStock(_ stockData: StockData) {
        // Update stock data
        stocks[stockData.symbol] = stockData

        // Calculate sentiment with full stock data for dynamic commentary
        Task {
            let previousSentiment = sentiments[stockData.symbol]

            // Try to get chart data (prefer 3M, fallback to others)
            let chartData = chartDataCache[stockData.symbol]?[.threeMonths]
                ?? chartDataCache[stockData.symbol]?[.oneMonth]
                ?? chartDataCache[stockData.symbol]?[.oneYear]

            let newSentiment = await commentaryEngine.calculateSentiment(
                for: stockData,
                previousSentiment: previousSentiment,
                chartData: chartData
            )

            await MainActor.run {
                self.sentiments[stockData.symbol] = newSentiment
            }
        }

        // Cache data
        cacheData(stockData)
    }

    /// Prefetch chart data for dynamic threshold calculation
    private func prefetchVolatilityData(for symbol: String) async {
        // Only fetch if not already cached
        if chartDataCache[symbol]?[.threeMonths] == nil {
            await fetchChartData(for: symbol, range: .threeMonths)
        }
    }

    // MARK: - Caching

    private func loadCachedData() {
        for symbol in symbols {
            // Load cached stock data
            if let cachedData = UserDefaults.standard.data(forKey: "stock_\(symbol)"),
               let stockData = try? JSONDecoder().decode(CachedStockData.self, from: cachedData) {
                stocks[symbol] = stockData.toStockData()
            }

            // Load cached sentiment
            if let cachedSentiment = UserDefaults.standard.data(forKey: "sentiment_\(symbol)"),
               let sentiment = try? JSONDecoder().decode(CachedSentiment.self, from: cachedSentiment) {
                sentiments[symbol] = sentiment.toMarketSentiment()
            }
        }

        // Load selected chart range
        if let savedRange = UserDefaults.standard.string(forKey: Self.selectedChartRangeKey),
           let range = ChartTimeRange(rawValue: savedRange) {
            selectedChartRange = range
            print("[StockTickerStore] Restored chart range: \(range.rawValue)")
        }
    }

    private func cacheData(_ stockData: StockData) {
        let cachedData = CachedStockData(from: stockData)
        if let encoded = try? JSONEncoder().encode(cachedData) {
            UserDefaults.standard.set(encoded, forKey: "stock_\(stockData.symbol)")
        }
    }
}

// MARK: - Cached Data Structures (for UserDefaults persistence)

private struct CachedStockData: Codable {
    let symbol: String
    let currentPrice: Double
    let priceChange: Double
    let priceChangePercent: Double
    let volume: Int64
    let dayHigh: Double
    let dayLow: Double
    let marketCap: Int64?
    let previousClose: Double
    let lastUpdated: Date

    init(from stockData: StockData) {
        self.symbol = stockData.symbol
        self.currentPrice = (stockData.currentPrice as NSDecimalNumber).doubleValue
        self.priceChange = (stockData.priceChange as NSDecimalNumber).doubleValue
        self.priceChangePercent = stockData.priceChangePercent
        self.volume = stockData.volume
        self.dayHigh = (stockData.dayHigh as NSDecimalNumber).doubleValue
        self.dayLow = (stockData.dayLow as NSDecimalNumber).doubleValue
        self.marketCap = stockData.marketCap
        self.previousClose = (stockData.previousClose as NSDecimalNumber).doubleValue
        self.lastUpdated = stockData.lastUpdated
    }

    func toStockData() -> StockData {
        StockData(
            symbol: symbol,
            currentPrice: Decimal(currentPrice),
            priceChange: Decimal(priceChange),
            priceChangePercent: priceChangePercent,
            volume: volume,
            dayHigh: Decimal(dayHigh),
            dayLow: Decimal(dayLow),
            marketCap: marketCap,
            previousClose: Decimal(previousClose),
            lastUpdated: lastUpdated
        )
    }
}

private struct CachedSentiment: Codable {
    let emoji: String
    let commentary: String
    let categoryRawValue: String
    let generatedAt: Date

    init(from sentiment: MarketSentiment) {
        self.emoji = sentiment.emoji
        self.commentary = sentiment.commentary
        self.categoryRawValue = sentiment.category.rawValue
        self.generatedAt = sentiment.generatedAt
    }

    func toMarketSentiment() -> MarketSentiment {
        MarketSentiment(
            emoji: emoji,
            commentary: commentary,
            category: SentimentCategory(rawValue: categoryRawValue) ?? .flat,
            generatedAt: generatedAt
        )
    }
}
