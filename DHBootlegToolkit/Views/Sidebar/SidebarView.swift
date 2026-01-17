import SwiftUI

enum SidebarTab: String, CaseIterable {
    case stockTicker
    case editor
    case s3Editor
    case logs

    var icon: String {
        switch self {
        case .stockTicker: return "chart.line.uptrend.xyaxis"
        case .editor: return "folder"
        case .s3Editor: return "cloud"
        case .logs: return "doc.plaintext"
        }
    }

    var label: String {
        switch self {
        case .stockTicker: return "Stock Ticker"
        case .editor: return "Localization"
        case .s3Editor: return "S3 Config"
        case .logs: return "Logs"
        }
    }

    var compactLabel: String {
        switch self {
        case .stockTicker: return "Stock"
        case .editor: return "Editor"
        case .s3Editor: return "S3 Config"
        case .logs: return "Logs"
        }
    }

    var detailTitle: String {
        switch self {
        case .stockTicker: return "Market Watch"
        case .editor: return "Not WebTranslateIt Editor"
        case .s3Editor: return "S3 Feature Config Editor"
        case .logs: return "Logger"
        }
    }
}

struct SidebarView: View {
    @Environment(AppStore.self) private var store
    @Environment(S3Store.self) private var s3Store
    @Binding var selectedTab: SidebarTab

    var body: some View {
        @Bindable var store = store
        @Bindable var s3Store = s3Store

        VStack(spacing: 8) {
            // Module segmented control
            HStack(spacing: 0) {
                ModuleSegmentedControl(selectedTab: $selectedTab)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            // Search bar below tabs (for Editor and S3Editor tabs)
            if selectedTab == .editor {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Filter features", text: $store.searchText)
                        .textFieldStyle(.plain)

                    if !store.searchText.isEmpty {
                        Button {
                            store.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 8)
            } else if selectedTab == .s3Editor {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Filter countries", text: $s3Store.searchText)
                        .textFieldStyle(.plain)

                    if !s3Store.searchText.isEmpty {
                        Button {
                            s3Store.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 8)
            }

            // Content
            switch selectedTab {
            case .stockTicker:
                StockTickerBrowserView()
            case .editor:
                LocalizationBrowserView()
            case .s3Editor:
                S3FeatureConfigBrowserView()
            case .logs:
                LogsView()
            }

            Spacer(minLength: 0)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
    }
}

// MARK: - Module Segmented Control

private struct ModuleSegmentedControl: View {
    @Binding var selectedTab: SidebarTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SidebarTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Image(systemName: tab.icon)
                        .imageScale(.small)
                        .fontWeight(selectedTab == tab ? .medium : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .background(
                        selectedTab == tab
                            ? Color.accentColor
                            : Color.clear
                    )
                    .foregroundStyle(
                        selectedTab == tab
                            ? .white
                            : .primary
                    )
                }
                .buttonStyle(.plain)
                .help(tab.label)  // Keep full label in tooltip
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
        .clipShape(Capsule())
    }
}

// MARK: - Logs View

struct LogsView: View {
    private let store = AppLogger.shared.store
    @State private var selectedLevel: LogLevel? = nil
    @State private var expandedGroups: Set<String> = []

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 0) {
            // Search bar and clear button
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Filter logs...", text: $store.searchText)
                    .textFieldStyle(.plain)

                if !store.searchText.isEmpty {
                    Button {
                        store.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .frame(height: 16)

                Button {
                    store.clear()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear all logs")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 8)

            // Level filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    LogFilterPill(
                        label: "All",
                        isSelected: selectedLevel == nil
                    ) {
                        selectedLevel = nil
                        store.filterLevel = nil
                    }

                    ForEach(LogLevel.allCases) { level in
                        LogFilterPill(
                            label: level.label,
                            color: level.color,
                            isSelected: selectedLevel == level
                        ) {
                            selectedLevel = level
                            store.filterLevel = level
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }

            Divider()

            // Log entries list with grouping
            if store.displayItems.isEmpty {
                ContentUnavailableView(
                    store.entries.isEmpty ? "No Logs" : "No Matching Logs",
                    systemImage: "doc.plaintext",
                    description: Text(store.entries.isEmpty
                        ? "Logs will appear here as operations run"
                        : "Try adjusting your filter")
                )
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(store.displayItems) { item in
                            switch item {
                            case .group(let group):
                                LogGroupRow(
                                    group: group,
                                    isExpanded: expandedGroups.contains(group.id)
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if expandedGroups.contains(group.id) {
                                            expandedGroups.remove(group.id)
                                        } else {
                                            expandedGroups.insert(group.id)
                                        }
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))

                                if expandedGroups.contains(group.id) {
                                    ForEach(group.entries) { entry in
                                        LogEntryRow(entry: entry, isIndented: true)
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 2, leading: 28, bottom: 2, trailing: 8))
                                    }
                                }

                            case .entry(let entry):
                                LogEntryRow(entry: entry, isIndented: false)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .onChange(of: store.entryCount) { _, _ in
                        if let last = store.entries.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Log Group Row

struct LogGroupRow: View {
    let group: LogGroup
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 12)

                Image(systemName: "clock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)

                Text(group.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                if let duration = group.formattedDuration {
                    Text(duration)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.green)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log Filter Pill

struct LogFilterPill: View {
    let label: String
    var color: Color = .secondary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .medium : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isSelected
                        ? color.opacity(0.2)
                        : Color(nsColor: .controlBackgroundColor)
                )
                .foregroundStyle(isSelected ? color : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: LogEntry
    var isIndented: Bool = false

    private var displayColor: Color {
        if entry.level == .timing && entry.duration != nil {
            return .green  // Completed timing logs are green
        }
        return entry.level.color
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(AppLogger.shared.formatTimestamp(entry.timestamp))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 75, alignment: .leading)

            // Icon
            Image(systemName: entry.level.icon)
                .font(.system(size: 11))
                .foregroundStyle(displayColor)
                .frame(width: 14)

            // Message and duration
            HStack(spacing: 4) {
                Text(entry.message)
                    .font(.system(size: 12))
                    .foregroundStyle(entry.isTimingStart ? .secondary : .primary)

                if let duration = entry.formattedDuration {
                    Text("(\(duration))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SidebarView(selectedTab: .constant(.editor))
        .environment(AppStore())
        .environment(S3Store())
        .frame(width: 280, height: 600)
}
