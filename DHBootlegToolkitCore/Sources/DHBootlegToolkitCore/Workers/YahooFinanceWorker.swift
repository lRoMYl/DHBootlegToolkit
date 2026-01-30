import Foundation

// Import models from the same module
#if canImport(DHOpsToolsCore)
// Models will be available in the same module
#endif

/// Actor-based worker for Yahoo Finance WebSocket and REST API integration
public actor YahooFinanceWorker {
    // MARK: - Properties

    private let symbols: [String]
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var isConnected = false
    private var reconnectAttempt = 0
    private var maxReconnectDelay: TimeInterval = 30.0
    private var pingTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?

    // AsyncStream for broadcasting stock updates
    private var continuation: AsyncStream<StockData>.Continuation?
    private var updateStream: AsyncStream<StockData>?

    // MARK: - Initialization

    public init(symbols: [String]) {
        self.symbols = symbols
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Start monitoring stock prices via WebSocket
    /// - Returns: AsyncStream of stock data updates
    public func startMonitoring() -> AsyncStream<StockData> {
        let stream = AsyncStream<StockData> { continuation in
            self.continuation = continuation
        }
        self.updateStream = stream

        // Start connection in a task
        Task {
            await connect()
        }

        return stream
    }

    /// Stop monitoring and disconnect
    public func stopMonitoring() async {
        await disconnect()
        continuation?.finish()
        continuation = nil
    }

    /// Fetch initial stock data via REST API
    public func fetchInitialData(symbol: String) async throws -> StockData {
        let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=1m&range=1d")!
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw YahooFinanceError.invalidResponse
        }

        return try parseRESTResponse(data, symbol: symbol)
    }

    /// Fetch chart data for a specific time range
    public func fetchChartData(symbol: String, range: ChartTimeRange) async throws -> [ChartDataPoint] {
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=\(range.apiInterval)&range=\(range.apiRange)"

        let url = URL(string: urlString)!
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooFinanceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw YahooFinanceError.invalidResponse
        }

        let stockData = try parseRESTResponse(data, symbol: symbol)
        return stockData.chartData ?? []
    }

    /// Manually refresh stock data for all symbols
    public func refreshData() async {
        for symbol in symbols {
            if let stockData = try? await fetchInitialData(symbol: symbol) {
                continuation?.yield(stockData)
            }
        }
    }

    // MARK: - WebSocket Connection

    private func connect() async {
        guard !isConnected else { return }

        // Note: Yahoo Finance WebSocket endpoint may require authentication
        // For this implementation, we'll use a fallback REST polling approach
        // since the actual WebSocket endpoint is not publicly documented

        // Start REST polling as fallback
        await startRESTPolling()
    }

    private func disconnect() async {
        isConnected = false
        reconnectAttempt = 0

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        pingTask?.cancel()
        pingTask = nil

        receiveTask?.cancel()
        receiveTask = nil
    }

    // MARK: - REST Polling Fallback

    private func startRESTPolling() async {
        isConnected = true

        // Fetch initial data for all symbols
        for symbol in symbols {
            if let stockData = try? await fetchInitialData(symbol: symbol) {
                continuation?.yield(stockData)
            }
        }

        // Start polling task (every 60 seconds to avoid rate limits)
        Task {
            while isConnected && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))

                for symbol in symbols {
                    if let stockData = try? await fetchInitialData(symbol: symbol) {
                        continuation?.yield(stockData)
                    }
                }
            }
        }
    }

    // MARK: - WebSocket Message Handling (for future use)

    private func receiveMessage() async {
        guard let task = webSocketTask else { return }

        do {
            let message = try await task.receive()

            switch message {
            case .string(let text):
                await handleTextMessage(text)
            case .data(let data):
                await handleDataMessage(data)
            @unknown default:
                break
            }

            // Continue receiving
            await receiveMessage()

        } catch {
            await handleDisconnection()
        }
    }

    private func handleTextMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else { return }
        await handleDataMessage(data)
    }

    private func handleDataMessage(_ data: Data) async {
        // Parse Yahoo Finance WebSocket message format
        // This is a placeholder - actual format depends on Yahoo's API
        if let stockData = try? parseWebSocketMessage(data) {
            continuation?.yield(stockData)
        }
    }

    private func sendSubscribeMessage() async {
        guard let task = webSocketTask else { return }

        let subscribeMessage: [String: Any] = [
            "subscribe": symbols
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: subscribeMessage),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let message = URLSessionWebSocketTask.Message.string(jsonString)

        do {
            try await task.send(message)
        } catch {
            // Failed to send subscribe message
        }
    }

    // MARK: - Ping/Heartbeat

    private func startPingTimer() {
        pingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await sendPing()
            }
        }
    }

    private func sendPing() async {
        guard let task = webSocketTask else { return }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                task.sendPing { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            await handleDisconnection()
        }
    }

    // MARK: - Reconnection Logic

    private func handleDisconnection() async {
        isConnected = false
        await scheduleReconnect()
    }

    private func scheduleReconnect() async {
        let delay = calculateBackoffDelay()
        reconnectAttempt += 1

        try? await Task.sleep(for: .seconds(delay))
        await connect()
    }

    private func calculateBackoffDelay() -> TimeInterval {
        let baseDelay = 1.0
        let exponentialDelay = baseDelay * pow(2.0, Double(reconnectAttempt))
        return min(exponentialDelay, maxReconnectDelay)
    }

    // MARK: - Message Parsing

    private func parseWebSocketMessage(_ data: Data) throws -> StockData {
        // Placeholder for actual Yahoo Finance WebSocket message format
        // This would need to be updated based on actual API documentation
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let symbol = json?["id"] as? String,
              let price = json?["price"] as? Double,
              let change = json?["change"] as? Double,
              let changePercent = json?["changePercent"] as? Double,
              let volume = json?["volume"] as? Int64 else {
            throw YahooFinanceError.invalidData
        }

        return StockData(
            symbol: symbol,
            currentPrice: Decimal(price),
            priceChange: Decimal(change),
            priceChangePercent: changePercent,
            volume: volume,
            dayHigh: Decimal(price + abs(change)),
            dayLow: Decimal(price - abs(change)),
            marketCap: json?["marketCap"] as? Int64,
            previousClose: Decimal(price - change),
            lastUpdated: Date()
        )
    }

    private func parseRESTResponse(_ data: Data, symbol: String) throws -> StockData {
        struct YahooChartResponse: Codable {
            struct Chart: Codable {
                struct Result: Codable {
                    struct Meta: Codable {
                        struct TradingPeriod: Codable {
                            let start: Int?
                            let end: Int?
                            let gmtoffset: Int?
                        }

                        struct CurrentTradingPeriod: Codable {
                            let pre: TradingPeriod?
                            let regular: TradingPeriod?
                            let post: TradingPeriod?
                        }

                        let regularMarketPrice: Double?
                        let previousClose: Double?
                        let regularMarketVolume: Int64?
                        let regularMarketDayHigh: Double?
                        let regularMarketDayLow: Double?
                        let fiftyTwoWeekHigh: Double?
                        let fiftyTwoWeekLow: Double?
                        let regularMarketTime: Int?
                        let exchangeTimezoneName: String?
                        let gmtoffset: Int?
                        let currentTradingPeriod: CurrentTradingPeriod?
                        let marketCap: Int64?
                    }

                    struct Indicators: Codable {
                        struct Quote: Codable {
                            let open: [Double?]?
                            let high: [Double?]?
                            let low: [Double?]?
                            let close: [Double?]?
                            let volume: [Int64?]?
                        }
                        let quote: [Quote]?
                    }

                    let meta: Meta
                    let timestamp: [Int]?
                    let indicators: Indicators?
                }

                let result: [Result]?
                let error: ErrorInfo?

                struct ErrorInfo: Codable {
                    let description: String
                }
            }

            let chart: Chart
        }

        let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)

        guard let result = response.chart.result?.first else {
            if let error = response.chart.error {
                throw YahooFinanceError.apiError(error.description)
            }
            throw YahooFinanceError.invalidData
        }

        let meta = result.meta

        // For historical data queries, current price fields may not be present
        // Use last close price as fallback if needed
        let currentPrice: Double
        let previousClose: Double

        if let regularMarketPrice = meta.regularMarketPrice,
           let regularPreviousClose = meta.previousClose {
            // Real-time data available
            currentPrice = regularMarketPrice
            previousClose = regularPreviousClose
        } else if let quote = result.indicators?.quote?.first,
                  let closes = quote.close,
                  !closes.isEmpty {
            // Historical data only - use last available close price
            let lastIndex = closes.count - 1
            currentPrice = closes[lastIndex] ?? 0
            previousClose = lastIndex > 0 ? (closes[lastIndex - 1] ?? currentPrice) : currentPrice
        } else {
            throw YahooFinanceError.missingFields
        }

        let priceChange = currentPrice - previousClose
        let priceChangePercent = previousClose > 0 ? (priceChange / previousClose) * 100 : 0

        // Get all-time high from centralized StockSymbol enum
        let allTimeHigh: Decimal? = {
            if let stockSymbol = StockSymbol(ticker: symbol) {
                return stockSymbol.allTimeHigh
            }
            return meta.fiftyTwoWeekHigh.map { Decimal($0) }
        }()

        // Parse historical chart data points
        let chartData: [ChartDataPoint]? = {
            guard let timestamps = result.timestamp else {
                return nil
            }

            guard let quote = result.indicators?.quote?.first else {
                return nil
            }

            guard let closes = quote.close, !closes.isEmpty else {
                return nil
            }

            let points = timestamps.enumerated().compactMap { index, timestamp -> ChartDataPoint? in
                guard let closePrice = closes[safe: index], let close = closePrice else {
                    return nil
                }

                return ChartDataPoint(
                    timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                    open: quote.open?[safe: index].flatMap { $0 }.map { Decimal($0) },
                    high: quote.high?[safe: index].flatMap { $0 }.map { Decimal($0) },
                    low: quote.low?[safe: index].flatMap { $0 }.map { Decimal($0) },
                    close: Decimal(close),
                    volume: quote.volume?[safe: index].flatMap { $0 }
                )
            }

            return points
        }()

        // Extract trading hours information
        let regularMarketTime = meta.regularMarketTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        let marketStartTime = meta.currentTradingPeriod?.regular?.start.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        let marketEndTime = meta.currentTradingPeriod?.regular?.end.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        let exchangeTimezoneName = meta.exchangeTimezoneName
        let gmtOffset = meta.gmtoffset

        return StockData(
            symbol: symbol,
            currentPrice: Decimal(currentPrice),
            priceChange: Decimal(priceChange),
            priceChangePercent: priceChangePercent,
            volume: meta.regularMarketVolume ?? 0,
            dayHigh: Decimal(meta.regularMarketDayHigh ?? currentPrice),
            dayLow: Decimal(meta.regularMarketDayLow ?? currentPrice),
            marketCap: meta.marketCap,
            previousClose: Decimal(previousClose),
            lastUpdated: Date(),
            fiftyTwoWeekHigh: meta.fiftyTwoWeekHigh.map { Decimal($0) },
            fiftyTwoWeekLow: meta.fiftyTwoWeekLow.map { Decimal($0) },
            allTimeHigh: allTimeHigh,
            allTimeHighDate: StockSymbol(ticker: symbol)?.allTimeHighDate,
            chartData: chartData,
            regularMarketTime: regularMarketTime,
            marketStartTime: marketStartTime,
            marketEndTime: marketEndTime,
            exchangeTimezoneName: exchangeTimezoneName,
            gmtOffset: gmtOffset
        )
    }

}

// MARK: - Extensions

private extension Array {
    /// Safe array access that returns nil if index is out of bounds
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Errors

public enum YahooFinanceError: Error, LocalizedError {
    case invalidResponse
    case invalidData
    case missingFields
    case apiError(String)
    case connectionFailed

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Yahoo Finance"
        case .invalidData:
            return "Failed to parse stock data"
        case .missingFields:
            return "Missing required fields in response"
        case .apiError(let message):
            return "Yahoo Finance API error: \(message)"
        case .connectionFailed:
            return "Failed to connect to Yahoo Finance"
        }
    }
}
