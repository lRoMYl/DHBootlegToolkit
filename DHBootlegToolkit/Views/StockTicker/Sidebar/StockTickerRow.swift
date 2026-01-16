import SwiftUI
import DHBootlegToolkitCore

struct StockTickerRow: View {
    @Environment(StockTickerStore.self) private var store
    let symbol: String

    @State private var pulseAnimation = false

    var body: some View {
        if let stockData = store.stocks[symbol], let sentiment = store.sentiments[symbol] {
            HStack(spacing: 8) {
                // Emoji sentiment
                Text(sentiment.emoji)
                    .font(.title3)
                    .frame(width: 32)

                // Symbol and price info
                VStack(alignment: .leading, spacing: 2) {
                    Text(symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(stockData.formattedPrice)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .id("price-\(symbol)-\(stockData.currentPrice)")
                        .transition(.opacity)
                }

                Spacer()

                // Change percentage with arrow
                HStack(spacing: 2) {
                    Text(stockData.directionArrow)
                        .font(.system(size: 12))
                        .foregroundStyle(priceColor(for: stockData))

                    Text(stockData.formattedChangePercent)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(priceColor(for: stockData))
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pulseAnimation)
            .onChange(of: stockData.currentPrice) { _, _ in
                // Trigger pulse animation on price change
                pulseAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    pulseAnimation = false
                }
            }
        } else {
            // Loading state
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func priceColor(for stockData: StockData) -> Color {
        if stockData.isUp {
            return .green
        } else if stockData.isDown {
            return .red
        } else {
            return .secondary
        }
    }
}

#Preview("DHER.DE - Up") {
    PreviewWrapper()
}

#Preview("TALABAT - Down") {
    PreviewWrapper2()
}

private struct PreviewWrapper: View {
    let store: StockTickerStore

    init() {
        let s = StockTickerStore()
        let symbol = StockSymbol.deliveryHero.ticker
        s.stocks[symbol] = .mockDHER
        s.sentiments[symbol] = .mockGains
        self.store = s
    }

    var body: some View {
        List {
            StockTickerRow(symbol: StockSymbol.deliveryHero.ticker)
        }
        .listStyle(.sidebar)
        .environment(store)
        .frame(width: 280, height: 100)
    }
}

private struct PreviewWrapper2: View {
    let store: StockTickerStore

    init() {
        let s = StockTickerStore()
        s.stocks["TALABAT"] = .mockTALABAT
        s.sentiments["TALABAT"] = .mockLosses
        self.store = s
    }

    var body: some View {
        List {
            StockTickerRow(symbol: "TALABAT")
        }
        .listStyle(.sidebar)
        .environment(store)
        .frame(width: 280, height: 100)
    }
}
