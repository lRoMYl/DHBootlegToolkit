import SwiftUI
import DHBootlegToolkitCore

struct SentimentDisplay: View {
    let sentiment: MarketSentiment
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            // Emoji
            Text(sentiment.emoji)
                .font(.system(size: 72))
                .id("emoji-\(sentiment.id)")
                .transition(.scale.combined(with: .opacity))

            // Commentary with type-specific color
            Text(sentiment.commentary)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(commentaryColor)
                .id("commentary-\(sentiment.id)")
                .transition(.opacity)

            // Category badge and source button side by side
            HStack(spacing: 8) {
                categoryBadge

                if let sourceURL = sentiment.sourceURL {
                    sourceButton(url: sourceURL)
                }
            }

            // Tap hint
            tapHint
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(categoryColor.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onTap?()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Type-Specific Properties

    private var commentaryColor: Color {
        switch sentiment.type {
        case .positive: return .primary
        case .witty: return .orange
        case .special: return .purple
        }
    }

    // MARK: - Component Views

    private func sourceButton(url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 4) {
                Image(systemName: "link.circle.fill")
                    .font(.caption2)
                Text("Source")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    private var categoryBadge: some View {
        Text(sentiment.category.label)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(categoryColor.opacity(0.2))
            )
            .foregroundStyle(categoryColor)
    }

    private var tapHint: some View {
        Text("Tap to rotate commentary")
            .font(.caption2)
            .foregroundStyle(.secondary.opacity(0.6))
    }

    private var categoryColor: Color {
        switch sentiment.category {
        case .moonshot, .gains:
            return .green
        case .flat:
            return .gray
        case .losses, .crash:
            return .red
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Positive") {
    SentimentDisplay(sentiment: MarketSentiment(
        emoji: "📈",
        commentary: "Revenue up 22% YoY - solid growth",
        category: .gains,
        type: .positive
    ))
    .padding()
    .frame(width: 600)
}

#Preview("Witty") {
    SentimentDisplay(sentiment: MarketSentiment(
        emoji: "🚀",
        commentary: "Everyone's a DHER bull at €25, where were you at €14.92?",
        category: .moonshot,
        type: .witty
    ))
    .padding()
    .frame(width: 600)
}

#Preview("Special") {
    SentimentDisplay(sentiment: MarketSentiment(
        emoji: "⭐️",
        commentary: "€99M FCF after 13 years - persistence pays dividends",
        category: .moonshot,
        type: .special
    ))
    .padding()
    .frame(width: 600)
}

#Preview("Moonshot") {
    SentimentDisplay(sentiment: .mockMoonshot)
        .padding()
        .frame(width: 600)
}

#Preview("Crash") {
    SentimentDisplay(sentiment: .mockCrash)
        .padding()
        .frame(width: 600)
}

#Preview("With Source URL") {
    SentimentDisplay(sentiment: MarketSentiment(
        emoji: "🚀📈",
        commentary: "Talabat IPO vibes: Priced at the top of range, just like this move 🚀",
        category: .moonshot,
        sourceURL: URL(string: "https://www.menabytes.com/talabat-final-ipo-price/"),
        type: .witty
    ))
    .padding()
    .frame(width: 600)
}
#endif
