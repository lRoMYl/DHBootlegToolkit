import SwiftUI
import DHBootlegToolkitCore

struct StockTickerBrowserView: View {
    @Environment(StockTickerStore.self) private var store

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 0) {
            // Stock list
            List(selection: $store.selectedSymbol) {
                Section("Tracking") {
                    ForEach(StockSymbol.allTickers, id: \.self) { symbol in
                        StockTickerRow(symbol: symbol)
                            .tag(symbol)
                    }
                }

                Section("Status") {
                    ConnectionStatusRow(isConnected: store.isConnected, isLoading: store.isLoading)
                }
            }
            .listStyle(.sidebar)

            // Manual refresh button
            HStack {
                Spacer()
                Button(action: {
                    Task {
                        await store.refreshData()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
}

struct ConnectionStatusRow: View {
    let isConnected: Bool
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 14, height: 14)
            } else {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isConnected ? Color.green.opacity(0.3) : Color.clear, lineWidth: 4)
                            .scaleEffect(isConnected ? 1.5 : 1.0)
                            .opacity(isConnected ? 0.5 : 0)
                            .animation(
                                isConnected ? .easeInOut(duration: 1.0).repeatForever(autoreverses: false) : .default,
                                value: isConnected
                            )
                    )
            }

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var statusText: String {
        if isLoading {
            return "Connecting..."
        } else if isConnected {
            return "Live Updates"
        } else {
            return "Offline"
        }
    }
}

#Preview {
    StockTickerBrowserView()
        .environment(StockTickerStore())
        .frame(width: 280, height: 600)
}
