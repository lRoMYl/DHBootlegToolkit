import SwiftUI
import DHBootlegToolkitCore

struct MarketStatsGrid: View {
    let stock: StockData

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            StatCard(label: "Volume", value: stock.formattedVolume, icon: "chart.bar.fill")
            StatCard(label: "Day High", value: stock.formattedPrice(stock.dayHigh), icon: "arrow.up")
            StatCard(label: "Day Low", value: stock.formattedPrice(stock.dayLow), icon: "arrow.down")
            StatCard(label: "Previous Close", value: stock.formattedPrice(stock.previousClose), icon: "clock.fill")
            StatCard(label: "Change", value: stock.formattedPrice(stock.priceChange), icon: "plus.forwardslash.minus")
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// Helper extension for formatting
extension StockData {
    func formattedPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = StockSymbol(ticker: symbol)?.currencyCode ?? "USD"
        formatter.currencySymbol = StockSymbol(ticker: symbol)?.currencySymbol ?? "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }
}

#Preview {
    MarketStatsGrid(stock: .mockDHER)
        .padding()
        .frame(width: 600)
}
