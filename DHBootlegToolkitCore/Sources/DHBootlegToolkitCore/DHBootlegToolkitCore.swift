/// DHBootlegToolkitCore provides reusable components for managing localization repositories and stock tracking.
///
/// ## Key Components
///
/// ### Configuration
/// - ``RepositoryConfiguration``: Protocol defining repository structure and behavior
/// - ``EntitySchema``: Defines JSON entity structure for parsing
/// - ``ConfigurationLoader``: Loads configuration from repository or fallback
///
/// ### Models
/// - ``StockSymbol``: Centralized tracked stock symbols
/// - ``PlatformDefinition``: Configurable platform definition
/// - ``FeatureFolder``: Represents a feature folder in the repository
/// - ``TranslationEntity``: A single translation entity
/// - ``GitStatus``: Current git status information
/// - ``EntityDiff``: Diff information between HEAD and working directory
/// - ``StockData``: Stock market data for a single security
/// - ``MarketSentiment``: Market sentiment with emoji and commentary
/// - ``SentimentCategory``: Sentiment categories based on price thresholds
///
/// ### Workers
/// - ``GitWorker``: Git operations (branches, commits, PRs)
/// - ``FileSystemWorker``: File I/O and repository validation
/// - ``DiffWorker``: Computes diffs between HEAD and working directory
/// - ``YahooFinanceWorker``: Yahoo Finance API integration for stock data
/// - ``CommentaryEngine``: Generates market sentiment commentary (witty and positive)
///
/// ## Usage
///
/// ```swift
/// import DHBootlegToolkitCore
///
/// // Create configuration
/// struct MyConfig: RepositoryConfiguration {
///     let basePath = "translations/project"
///     let platforms = [PlatformDefinition.mobile]
///     let entitySchema = EntitySchema.translation
/// }
///
/// // Use workers
/// let fsWorker = FileSystemWorker(configuration: MyConfig())
/// let validation = fsWorker.validateRepository(url)
///
/// // Stock tracking
/// let yahooWorker = YahooFinanceWorker(symbols: StockSymbol.allTickers)
/// let stream = await yahooWorker.startMonitoring()
/// for await stockData in stream {
///     print("Price update: \(stockData)")
/// }
/// ```
public enum DHBootlegToolkitCore {
    /// Library version
    public static let version = "1.0.0"
}
