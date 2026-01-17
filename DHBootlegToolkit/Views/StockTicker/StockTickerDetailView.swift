import SwiftUI
import DHBootlegToolkitCore

struct StockTickerDetailView: View {
    @Environment(StockTickerStore.self) private var store

    var body: some View {
        if let stock = store.selectedStock, let sentiment = store.selectedSentiment {
            ScrollView {
                VStack(spacing: 20) {
                    // Price and Threshold side by side
                    HStack(alignment: .top, spacing: 20) {
                        // Hero price card
                        StockPriceCard(stock: stock, isConnected: store.isConnected)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                        // Sentiment threshold legend
                        SentimentThresholdLegend(
                            thresholds: store.currentThresholds,
                            symbol: stock.symbol
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }

                    // Sentiment display
                    SentimentDisplay(sentiment: sentiment) {
                        store.rotateSentiment(for: stock.symbol)
                    }

                    // Market stats grid
                    MarketStatsGrid(stock: stock)

                    // Chart placeholder
                    StockChartView(stock: stock)
                }
                .padding()
            }
        } else {
            // Empty state
            ContentUnavailableView(
                "Select a Stock",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Choose a stock from the sidebar to see detailed information")
            )
        }
    }
}

#if DEBUG
#Preview {
    DetailViewPreview()
}

private struct DetailViewPreview: View {
    let store: StockTickerStore

    init() {
        let s = StockTickerStore()
        let symbol = StockSymbol.deliveryHero.ticker
        s.stocks[symbol] = .mockDHER
        s.sentiments[symbol] = .mockMoonshot
        s.selectedSymbol = symbol
        self.store = s
    }

    var body: some View {
        StockTickerDetailView()
            .environment(store)
            .frame(width: 800, height: 600)
    }
}
#endif
