import SwiftUI

// MARK: - JSON Search Bar

/// Search bar with text editor-style navigation (next/prev buttons)
public struct JSONSearchBar: View {
    @Binding var searchQuery: String
    @Binding var exactMatch: Bool
    @Binding var caseSensitive: Bool
    let currentMatch: Int
    let totalMatches: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let focusCoordinator: FieldFocusCoordinator
    @FocusState private var localFocus: FieldIdentifier?

    public init(
        searchQuery: Binding<String>,
        exactMatch: Binding<Bool>,
        caseSensitive: Binding<Bool>,
        currentMatch: Int,
        totalMatches: Int,
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        focusCoordinator: FieldFocusCoordinator
    ) {
        self._searchQuery = searchQuery
        self._exactMatch = exactMatch
        self._caseSensitive = caseSensitive
        self.currentMatch = currentMatch
        self.totalMatches = totalMatches
        self.onNext = onNext
        self.onPrevious = onPrevious
        self.focusCoordinator = focusCoordinator
    }

    public var body: some View {
        Group {
            Image(systemName: "magnifyingglass")
                .imageScale(.small)
                .foregroundStyle(.secondary)
                .frame(width: 12, height: 12)

            TextField("Search keys...", text: $searchQuery)
                .textFieldStyle(.plain)
                .focused($localFocus, equals: .searchBar)

            if !searchQuery.isEmpty {
                matchCounterView
                navigationButtons
                clearButton

                Divider()
                    .frame(height: 20)

                Toggle("Aa", isOn: $caseSensitive)
                    .font(.caption)
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .help("Case sensitive search")

                Toggle("exact", isOn: $exactMatch)
                    .font(.caption)
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .help("Exact match")
            }
        }
        .onChange(of: focusCoordinator.focusedField) { _, newValue in
            localFocus = newValue
        }
        .onChange(of: localFocus) { _, newValue in
            if newValue != focusCoordinator.focusedField {
                if let newValue = newValue {
                    focusCoordinator.requestFocus(newValue)
                } else {
                    focusCoordinator.clearFocus()
                }
            }
        }
    }

    @ViewBuilder
    private var matchCounterView: some View {
        if totalMatches > 0 {
            Text("\(currentMatch) of \(totalMatches)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .padding(.horizontal, 6)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        } else {
            Text("No matches")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .padding(.horizontal, 6)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 4) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(totalMatches == 0)

            Button(action: onNext) {
                Image(systemName: "chevron.down")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(totalMatches == 0)
        }
    }

    private var clearButton: some View {
        Button {
            searchQuery = ""
        } label: {
            Image(systemName: "xmark.circle.fill")
                .imageScale(.small)
                .foregroundStyle(.secondary)
                .frame(width: 12, height: 12)
        }
        .buttonStyle(.plain)
        .controlSize(.small)
    }
}
