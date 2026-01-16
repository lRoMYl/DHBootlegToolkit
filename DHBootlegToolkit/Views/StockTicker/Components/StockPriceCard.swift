import SwiftUI
import DHBootlegToolkitCore

struct StockPriceCard: View {
    let stock: StockData
    let isConnected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with symbol and connection status
            HStack {
                Text(stock.symbol)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Connection indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)

                    Text(isConnected ? "Connected" : "Offline")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Trading hours
            if let tradingHours = stock.formattedTradingHours {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(tradingHours)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            // Market status indicator (separate row)
            if let isOpen = stock.isMarketOpen {
                HStack(spacing: 3) {
                    Circle()
                        .fill(isOpen ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(isOpen ? "Open" : "Closed")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isOpen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                )
                .foregroundStyle(isOpen ? .green : .red)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .padding(.vertical, 4)

            // Price display - more compact
            VStack(alignment: .leading, spacing: 8) {
                Text(stock.formattedPrice)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text(stock.directionArrow)
                            .font(.body)
                            .foregroundStyle(priceColor)

                        Text(stock.formattedChangePercent)
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(priceColor)
                    }

                    Text(String(format: "%@ %@", stock.priceChange >= 0 ? "+" : "", formatDecimal(stock.priceChange)))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            // Last updated timestamp
            Text("Updated: \(formatTime(stock.lastUpdated))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(priceColor.opacity(0.2), lineWidth: 2)
        )
    }

    private var priceColor: Color {
        if stock.isUp {
            return .green
        } else if stock.isDown {
            return .red
        } else {
            return .secondary
        }
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = StockSymbol(ticker: stock.symbol)?.currencyCode ?? "USD"
        formatter.currencySymbol = StockSymbol(ticker: stock.symbol)?.currencySymbol ?? "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

#Preview("Up") {
    StockPriceCard(stock: .mockDHER, isConnected: true)
        .padding()
        .frame(width: 600)
}

#Preview("Down") {
    StockPriceCard(stock: .mockTALABAT, isConnected: true)
        .padding()
        .frame(width: 600)
}
