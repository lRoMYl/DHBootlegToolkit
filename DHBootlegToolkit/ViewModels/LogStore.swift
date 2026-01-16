import SwiftUI
import Observation

// MARK: - Log Display Item

/// Represents an item in the log display (either a group header or a single entry)
enum LogDisplayItem: Identifiable {
    case group(LogGroup)
    case entry(LogEntry)

    var id: String {
        switch self {
        case .group(let group): return "group-\(group.id)"
        case .entry(let entry): return entry.id.uuidString
        }
    }
}

// MARK: - Log Group

/// Represents a timing group with its child entries
struct LogGroup: Identifiable {
    let id: String
    let name: String
    let entries: [LogEntry]
    let totalDuration: TimeInterval?

    var formattedDuration: String? {
        guard let duration = totalDuration else { return nil }
        if duration < 1.0 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.2fs", duration)
        }
    }
}

// MARK: - Log Store

@Observable
@MainActor
final class LogStore {

    // MARK: - State

    private(set) var entries: [LogEntry] = []
    var filterLevel: LogLevel? = nil
    var searchText: String = ""

    // MARK: - Computed Properties

    var filteredEntries: [LogEntry] {
        entries.filter { entry in
            let matchesLevel = filterLevel == nil || entry.level == filterLevel
            let matchesSearch = searchText.isEmpty ||
                entry.message.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }

    var entryCount: Int {
        entries.count
    }

    /// Returns entries organized for display with groups
    var displayItems: [LogDisplayItem] {
        var items: [LogDisplayItem] = []
        var processedGroupIds: Set<String> = []
        var i = 0

        while i < filteredEntries.count {
            let entry = filteredEntries[i]

            // Check if this entry belongs to a group we haven't processed yet
            if let groupId = entry.groupId, !processedGroupIds.contains(groupId) {
                // Collect all entries for this group
                let groupEntries = filteredEntries.filter {
                    $0.groupId == groupId && !$0.isGroupEnd
                }

                // Find the group end entry to get total duration
                let groupEndEntry = filteredEntries.first { $0.groupId == groupId && $0.isGroupEnd }

                // Get group name from first entry or end entry
                let groupName = entry.groupName ?? groupEndEntry?.groupName ?? groupId

                let group = LogGroup(
                    id: groupId,
                    name: groupName,
                    entries: groupEntries,
                    totalDuration: groupEndEntry?.duration
                )
                items.append(.group(group))
                processedGroupIds.insert(groupId)
            } else if entry.groupId == nil {
                // Ungrouped entry
                items.append(.entry(entry))
            }
            // Skip grouped entries as they're handled above
            // Also skip group end entries as they're just for duration

            i += 1
        }

        return items
    }

    // MARK: - Actions

    func append(_ entry: LogEntry) {
        entries.append(entry)
    }

    func clear() {
        entries.removeAll()
    }
}
