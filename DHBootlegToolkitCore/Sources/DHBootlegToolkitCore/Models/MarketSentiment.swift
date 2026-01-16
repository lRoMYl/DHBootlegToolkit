import Foundation

/// Market sentiment with emoji reaction and commentary
public struct MarketSentiment: Sendable, Identifiable {
    public let id = UUID()
    public let emoji: String
    public let commentary: String
    public let category: SentimentCategory
    public let generatedAt: Date
    public let sourceURL: URL?
    public let type: SentimentType

    public init(
        emoji: String,
        commentary: String,
        category: SentimentCategory,
        generatedAt: Date = Date(),
        sourceURL: URL? = nil,
        type: SentimentType = .positive
    ) {
        self.emoji = emoji
        self.commentary = commentary
        self.category = category
        self.generatedAt = generatedAt
        self.sourceURL = sourceURL
        self.type = type
    }
}

/// Type of sentiment commentary
public enum SentimentType: String, Sendable {
    case positive  // Fact-based, optimistic, progress-focused (70%)
    case witty     // Sarcastic, humorous, clever wordplay (30%)
    case special   // High-impact contextual commentary (10% selection rate)
}

// MARK: - Mock Data (for development/testing)

#if DEBUG
extension MarketSentiment {
    /// Mock moonshot sentiment (witty)
    public static let mockMoonshot = MarketSentiment(
        emoji: SentimentCategory.moonshot.emoji,
        commentary: "To the moon! 🌙",
        category: .moonshot,
        type: .witty
    )

    /// Mock gains sentiment (positive)
    public static let mockGains = MarketSentiment(
        emoji: SentimentCategory.gains.emoji,
        commentary: "Green is good",
        category: .gains,
        type: .positive
    )

    /// Mock flat sentiment (witty)
    public static let mockFlat = MarketSentiment(
        emoji: SentimentCategory.flat.emoji,
        commentary: "Meh.",
        category: .flat,
        type: .witty
    )

    /// Mock losses sentiment (witty)
    public static let mockLosses = MarketSentiment(
        emoji: SentimentCategory.losses.emoji,
        commentary: "Ouch",
        category: .losses,
        type: .witty
    )

    /// Mock crash sentiment (special)
    public static let mockCrash = MarketSentiment(
        emoji: SentimentCategory.crash.emoji,
        commentary: "Hide the portfolio",
        category: .crash,
        type: .special
    )
}
#endif
