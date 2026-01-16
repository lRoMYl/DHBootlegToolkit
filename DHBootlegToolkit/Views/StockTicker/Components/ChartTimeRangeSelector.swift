import SwiftUI
import DHBootlegToolkitCore

struct ChartTimeRangeSelector: View {
    @Binding var selectedRange: ChartTimeRange
    let onRangeChange: (ChartTimeRange) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ChartTimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedRange = range
                        onRangeChange(range)
                    }) {
                        Text(range.rawValue)
                            .font(.system(size: 11, weight: selectedRange == range ? .semibold : .regular))
                            .foregroundStyle(selectedRange == range ? .white : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(selectedRange == range ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: 32)
    }
}

#Preview {
    @Previewable @State var selectedRange: ChartTimeRange = .oneDay

    ChartTimeRangeSelector(selectedRange: $selectedRange) { range in
        print("Selected range: \(range.rawValue)")
    }
    .padding()
    .frame(width: 600)
}
