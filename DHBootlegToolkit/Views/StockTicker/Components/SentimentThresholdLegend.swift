import SwiftUI
import DHBootlegToolkitCore

struct SentimentThresholdLegend: View {
    let thresholds: DynamicThreshold
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sentiment Thresholds")
                    .font(.headline)

                Spacer()

                // Indicator badge
                if thresholds.isFixed {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("Fixed")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                    )
                    .foregroundColor(.secondary)
                }
            }

            // Threshold legend items
            VStack(spacing: 8) {
                ThresholdRow(
                    category: .moonshot,
                    range: "≥ \(formatPercent(thresholds.moonshot))",
                    color: .green
                )

                ThresholdRow(
                    category: .gains,
                    range: "\(formatPercent(thresholds.gainsLower)) to \(formatPercent(thresholds.moonshot, exclusive: true))",
                    color: Color(red: 0.4, green: 0.8, blue: 0.4)
                )

                ThresholdRow(
                    category: .flat,
                    range: "\(formatPercent(thresholds.flatLower)) to \(formatPercent(thresholds.flatUpper, exclusive: true))",
                    color: .gray
                )

                ThresholdRow(
                    category: .losses,
                    range: "\(formatPercent(thresholds.lossesLower)) to \(formatPercent(thresholds.flatLower, exclusive: true))",
                    color: Color(red: 1.0, green: 0.6, blue: 0.4)
                )

                ThresholdRow(
                    category: .crash,
                    range: "≤ \(formatPercent(thresholds.crash))",
                    color: .red
                )
            }

            // Source info
            if !thresholds.isFixed {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)

                    switch thresholds.source {
                    case .dynamic(let timeRange, let dataPoints, let volatilityRatio):
                        Text("Based on \(timeRange.rawValue) volatility (\(dataPoints) points, \(formatRatio(volatilityRatio))x)")
                            .font(.caption2)
                    case .fixed:
                        Text("Using fixed baseline thresholds")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func formatPercent(_ value: Double, exclusive: Bool = false) -> String {
        let formatted = String(format: "%+.1f%%", value)
        return exclusive ? "< " + formatted : formatted
    }

    private func formatRatio(_ ratio: Double) -> String {
        return String(format: "%.2f", ratio)
    }
}

// MARK: - Threshold Row

private struct ThresholdRow: View {
    let category: SentimentCategory
    let range: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 8, height: 24)

            // Category emoji and label
            HStack(spacing: 6) {
                Text(category.emoji)
                    .font(.body)

                Text(category.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .leading)
            }

            Spacer()

            // Range
            Text(range)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .monospaced()
        }
    }
}

// MARK: - Previews

#Preview("Fixed Thresholds") {
    SentimentThresholdLegend(
        thresholds: .fixed,
        symbol: "DHER.DE"
    )
    .padding()
    .frame(width: 400)
}

#Preview("Dynamic - Low Volatility") {
    SentimentThresholdLegend(
        thresholds: DynamicThreshold(
            moonshot: 2.5,
            gainsLower: 0.5,
            flatLower: -0.5,
            flatUpper: 0.5,
            gainsUpper: 2.5,
            lossesLower: -2.5,
            crash: -2.5,
            isFixed: false,
            volatilityRatio: 0.5,
            source: .dynamic(timeRange: .threeMonths, dataPoints: 65, volatilityRatio: 0.5)
        ),
        symbol: "TALABAT.AE"
    )
    .padding()
    .frame(width: 400)
}

#Preview("Dynamic - High Volatility") {
    SentimentThresholdLegend(
        thresholds: DynamicThreshold(
            moonshot: 10.0,
            gainsLower: 2.0,
            flatLower: -2.0,
            flatUpper: 2.0,
            gainsUpper: 10.0,
            lossesLower: -10.0,
            crash: -10.0,
            isFixed: false,
            volatilityRatio: 2.0,
            source: .dynamic(timeRange: .threeMonths, dataPoints: 65, volatilityRatio: 2.0)
        ),
        symbol: "DHER.DE"
    )
    .padding()
    .frame(width: 400)
}
