import SwiftUI

// MARK: - Timing Group

struct TimingGroup: Sendable {
    let id: String
    let name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    /// Convenience initializer using name as id
    init(_ name: String) {
        self.id = name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = name
    }
}

// MARK: - Log Level

enum LogLevel: String, CaseIterable, Identifiable {
    case info
    case warning
    case error
    case timing

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .timing: return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: return .secondary
        case .warning: return .orange
        case .error: return .red
        case .timing: return .blue
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

// MARK: - Log Entry

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let duration: TimeInterval?
    let isTimingStart: Bool
    let groupId: String?
    let groupName: String?
    let isGroupEnd: Bool

    init(
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        duration: TimeInterval? = nil,
        isTimingStart: Bool = false,
        groupId: String? = nil,
        groupName: String? = nil,
        isGroupEnd: Bool = false
    ) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.duration = duration
        self.isTimingStart = isTimingStart
        self.groupId = groupId
        self.groupName = groupName
        self.isGroupEnd = isGroupEnd
    }

    /// Formatted duration string (e.g., "123ms" or "1.2s")
    var formattedDuration: String? {
        guard let duration else { return nil }
        if duration < 1.0 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.2fs", duration)
        }
    }
}
