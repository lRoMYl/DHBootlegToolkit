import SwiftUI
import Charts
import DHBootlegToolkitCore

struct StockChartView: View {
    let stock: StockData
    @Environment(StockTickerStore.self) private var store
    @State private var selectedDate: Date?
    @State private var rangeSelection: ChartRangeSelection?
    @State private var isDragging: Bool = false
    @State private var dragStartX: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Price Chart")
                    .font(.headline)

                Spacer()

                ChartTimeRangeSelector(
                    selectedRange: Binding(
                        get: { store.selectedChartRange },
                        set: { _ in }
                    ),
                    onRangeChange: { range in
                        store.selectChartRange(range)
                        rangeSelection = nil  // Clear range when changing time range
                    }
                )
            }

            if store.isLoadingChartData {
                loadingView
            } else if let chartData = store.getChartData(for: stock.symbol), !chartData.isEmpty {
                chartView(data: chartData)
            } else {
                emptyStateView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .task {
            // Load initial chart data when view appears
            await store.fetchChartData(for: stock.symbol, range: store.selectedChartRange)
        }
        .onChange(of: stock.symbol) { _, newSymbol in
            // Fetch data for newly selected stock
            rangeSelection = nil
            Task {
                await store.fetchChartData(for: newSymbol, range: store.selectedChartRange)
            }
        }
    }

    @ViewBuilder
    private func chartView(data: [ChartDataPoint]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            priceInfoView(data: data)

            GeometryReader { geometry in
                Chart {
                    chartMarks(for: data)
                }
                .chartXSelection(value: $selectedDate)
                .chartYScale(domain: calculateYAxisDomain(data: data))
                .chartXAxis {
                    AxisMarks(values: .stride(by: xAxisStride())) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.3))
                        AxisValueLabel(format: xAxisFormat())
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.3))
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text(formatPrice(price))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            // Clear hover selection when dragging
                            selectedDate = nil
                            isDragging = true

                            if dragStartX == nil {
                                dragStartX = value.startLocation.x
                            }

                            guard let startX = dragStartX else { return }

                            let chartWidth = geometry.size.width
                            if let startDate = dateFromXPosition(startX, in: data, chartWidth: chartWidth),
                               let endDate = dateFromXPosition(
                                value.location.x,
                                in: data,
                                chartWidth: chartWidth
                               ),
                               let startPoint = findNearestPoint(to: startDate, in: data),
                               let endPoint = findNearestPoint(to: endDate, in: data) {

                                // Keep original order: start = first click, end = current drag position
                                rangeSelection = ChartRangeSelection(
                                    startDate: startPoint.timestamp,
                                    endDate: endPoint.timestamp,
                                    startPrice: startPoint.close,
                                    endPrice: endPoint.close
                                )
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            dragStartX = nil
                            rangeSelection = nil  // Clear selection on release
                        }
                )
            }
            .frame(height: 300)
            .clipped()
        }
    }

    @ViewBuilder
    private func priceInfoView(data: [ChartDataPoint]) -> some View {
        HStack {
            if let range = rangeSelection {
                rangeStatisticsView(range: range)
            } else if let selectedDate = selectedDate,
                      let selectedPoint = findNearestPoint(to: selectedDate, in: data) {
                Text(formatPrice(selectedPoint.close.doubleValue))
                    .font(.system(size: 16, weight: .semibold))

                Text(selectedPoint.timestamp, format: .dateTime.month().day().hour().minute())
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            } else {
                Text(formatPrice(data.last?.close.doubleValue ?? stock.currentPrice.doubleValue))
                    .font(.system(size: 16, weight: .semibold))

                Text("Current")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 32)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    @ChartContentBuilder
    private func chartMarks(for data: [ChartDataPoint]) -> some ChartContent {
        // Base area mark - single pass through data
        ForEach(data) { point in
            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Price", point.close.doubleValue)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [lineColor.opacity(0.5), lineColor.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }

        // Line mark - single pass through data
        ForEach(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Price", point.close.doubleValue)
            )
            .foregroundStyle(lineColor)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }

        // Range selection overlay
        if let range = rangeSelection {
            rangeSelectionMarks(for: data, range: range)
        }

        // Selection marker - only show when hovering
        if rangeSelection == nil,
           let selectedDate = selectedDate,
           let selectedPoint = findNearestPoint(to: selectedDate, in: data) {
            PointMark(
                x: .value("Time", selectedPoint.timestamp),
                y: .value("Price", selectedPoint.close.doubleValue)
            )
            .foregroundStyle(lineColor)
            .symbolSize(80)
        }
    }

    @ChartContentBuilder
    private func rangeSelectionMarks(
        for data: [ChartDataPoint],
        range: ChartRangeSelection
    ) -> some ChartContent {
        let rangeData = data.filter { point in
            let minDate = min(range.startDate, range.endDate)
            let maxDate = max(range.startDate, range.endDate)
            let pointTime = point.timestamp.timeIntervalSince1970
            let minTime = minDate.timeIntervalSince1970
            let maxTime = maxDate.timeIntervalSince1970
            let tolerance: TimeInterval = 1.0
            return pointTime >= (minTime - tolerance) && pointTime <= (maxTime + tolerance)
        }

        let rangeColor: Color = range.priceChange > 0 ? .green : (range.priceChange < 0 ? .red : .blue)

        ForEach(rangeData) { point in
            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Price", point.close.doubleValue)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [rangeColor.opacity(0.7), rangeColor.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }

        ForEach(rangeData) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Price", point.close.doubleValue)
            )
            .foregroundStyle(rangeColor)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3))
        }

        ForEach(data) { point in
            let markerColor: Color = range.priceChange > 0 ? .green : (range.priceChange < 0 ? .red : .blue)

            if Calendar.current.isDate(point.timestamp, equalTo: range.startDate, toGranularity: .minute) {
                RuleMark(x: .value("Start", range.startDate))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .foregroundStyle(markerColor.opacity(0.7))

                PointMark(
                    x: .value("Time", range.startDate),
                    y: .value("Price", range.startPrice.doubleValue)
                )
                .foregroundStyle(markerColor)
                .symbolSize(100)
            }

            if Calendar.current.isDate(point.timestamp, equalTo: range.endDate, toGranularity: .minute) {
                RuleMark(x: .value("End", range.endDate))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .foregroundStyle(markerColor.opacity(0.7))

                PointMark(
                    x: .value("Time", range.endDate),
                    y: .value("Price", range.endPrice.doubleValue)
                )
                .foregroundStyle(markerColor)
                .symbolSize(100)
            }
        }
    }

    @ViewBuilder
    private func rangeStatisticsView(range: ChartRangeSelection) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Start")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatPrice(range.startPrice.doubleValue))
                    .font(.caption.weight(.semibold))
            }

            Divider().frame(height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("End")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatPrice(range.endPrice.doubleValue))
                    .font(.caption.weight(.semibold))
            }

            Divider().frame(height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Change")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(formatPriceChange(range.priceChange.doubleValue))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(range.isPositive ? .green : .red)
                    Text(String(format: "(%+.2f%%)", range.percentChange))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(range.isPositive ? .green : .red)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private var loadingView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(nsColor: .controlBackgroundColor))
            .frame(height: 300)
            .overlay(
                ProgressView()
            )
    }

    private var emptyStateView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(nsColor: .controlBackgroundColor))
            .frame(height: 300)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("No chart data available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            )
    }

    // MARK: - Helper Methods

    private var lineColor: Color {
        stock.isUp ? .green : (stock.isDown ? .red : .gray)
    }

    private func calculateYAxisDomain(data: [ChartDataPoint]) -> ClosedRange<Double> {
        let prices = data.map { $0.close.doubleValue }
        guard let minPrice = prices.min(), let maxPrice = prices.max() else {
            return 0...100
        }

        let padding = (maxPrice - minPrice) * 0.05
        return (minPrice - padding)...(maxPrice + padding)
    }

    private func xAxisStride() -> Calendar.Component {
        switch store.selectedChartRange {
        case .oneDay:
            return .hour
        case .oneWeek:
            return .day
        case .oneMonth:
            return .weekOfYear
        case .threeMonths, .sixMonths:
            return .month
        case .yearToDate, .oneYear:
            return .month
        case .twoYears, .fiveYears, .tenYears, .all:
            return .year
        }
    }

    private func xAxisFormat() -> Date.FormatStyle {
        switch store.selectedChartRange {
        case .oneDay:
            return .dateTime.hour()
        case .oneWeek:
            return .dateTime.weekday(.abbreviated)
        case .oneMonth:
            return .dateTime.day()
        case .threeMonths, .sixMonths:
            return .dateTime.month(.abbreviated).day()
        case .yearToDate, .oneYear:
            return .dateTime.month(.abbreviated)
        case .twoYears, .fiveYears, .tenYears, .all:
            return .dateTime.year()
        }
    }

    private func dateFromXPosition(
        _ xPosition: CGFloat,
        in data: [ChartDataPoint],
        chartWidth: CGFloat
    ) -> Date? {
        guard !data.isEmpty, chartWidth > 0 else { return nil }

        let minDate = data.first!.timestamp
        let maxDate = data.last!.timestamp
        let timeRange = maxDate.timeIntervalSince(minDate)

        let ratio = xPosition / chartWidth
        let timeOffset = timeRange * ratio

        return minDate.addingTimeInterval(timeOffset)
    }

    private func findNearestPoint(to date: Date, in data: [ChartDataPoint]) -> ChartDataPoint? {
        data.min(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) })
    }

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = StockSymbol(ticker: stock.symbol)?.currencyCode ?? "USD"
        formatter.currencySymbol = StockSymbol(ticker: stock.symbol)?.currencySymbol ?? "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }

    private func formatPriceChange(_ change: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = StockSymbol(ticker: stock.symbol)?.currencyCode ?? "USD"
        formatter.currencySymbol = StockSymbol(ticker: stock.symbol)?.currencySymbol ?? "$"
        formatter.positivePrefix = "+"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: change)) ?? "\(change)"
    }
}

#Preview {
    @Previewable @State var store = StockTickerStore()

    StockChartView(stock: .mockDHER)
        .environment(store)
        .padding()
        .frame(width: 700)
}
