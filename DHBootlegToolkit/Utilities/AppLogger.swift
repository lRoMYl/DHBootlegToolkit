import Foundation

// MARK: - Timing Group Context (Option B)

/// Context object provided to timedGroup closures for scoped timing
@MainActor
struct TimingGroupContext {
    let group: TimingGroup
    private let logger: AppLogger

    init(group: TimingGroup, logger: AppLogger) {
        self.group = group
        self.logger = logger
    }

    /// Times an async operation within this group
    func time<T: Sendable>(_ name: String, _ work: () async throws -> T) async rethrows -> T {
        try await logger.time(name, group: group, work)
    }

    /// Times an async operation within this group (no return value)
    func time(_ name: String, _ work: () async throws -> Void) async rethrows {
        try await logger.time(name, group: group, work)
    }
}

// MARK: - App Logger

@MainActor
final class AppLogger {

    // MARK: - Singleton

    static let shared = AppLogger()

    // MARK: - Properties

    let store = LogStore()

    private let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    /// Tracks start times for active timing groups
    private var groupStartTimes: [String: CFAbsoluteTime] = [:]

    // MARK: - Init

    private init() {}

    // MARK: - Logging Methods

    func info(_ message: String) {
        log(.info, message)
    }

    func warning(_ message: String) {
        log(.warning, message)
    }

    func error(_ message: String) {
        log(.error, message)
    }

    // MARK: - Timing Methods

    /// Times an async operation and logs start/completion with duration
    func time<T: Sendable>(_ name: String, _ work: () async throws -> T) async rethrows -> T {
        log(.timing, "\(name)...", isTimingStart: true)
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await work()
        let duration = CFAbsoluteTimeGetCurrent() - start
        log(.timing, "✓ \(name)", duration: duration)
        return result
    }

    /// Times an async operation without return value
    func time(_ name: String, _ work: () async throws -> Void) async rethrows {
        log(.timing, "\(name)...", isTimingStart: true)
        let start = CFAbsoluteTimeGetCurrent()
        try await work()
        let duration = CFAbsoluteTimeGetCurrent() - start
        log(.timing, "✓ \(name)", duration: duration)
    }

    /// Logs a timing summary (e.g., total startup time)
    func timingSummary(_ name: String, duration: TimeInterval) {
        let entry = LogEntry(
            level: .timing,
            message: "══ \(name): \(formatDuration(duration)) ══",
            duration: duration,
            isTimingStart: false
        )
        store.append(entry)
    }

    // MARK: - Group Timing Methods (Option A)

    /// Times an async operation within a group and logs start/completion with duration
    func time<T: Sendable>(_ name: String, group: TimingGroup, _ work: () async throws -> T) async rethrows -> T {
        // Start group timing on first call
        if groupStartTimes[group.id] == nil {
            groupStartTimes[group.id] = CFAbsoluteTimeGetCurrent()
        }

        log(.timing, "\(name)...", isTimingStart: true, groupId: group.id, groupName: group.name)
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await work()
        let duration = CFAbsoluteTimeGetCurrent() - start
        log(.timing, "✓ \(name)", duration: duration, groupId: group.id)
        return result
    }

    /// Times an async operation within a group without return value
    func time(_ name: String, group: TimingGroup, _ work: () async throws -> Void) async rethrows {
        // Start group timing on first call
        if groupStartTimes[group.id] == nil {
            groupStartTimes[group.id] = CFAbsoluteTimeGetCurrent()
        }

        log(.timing, "\(name)...", isTimingStart: true, groupId: group.id, groupName: group.name)
        let start = CFAbsoluteTimeGetCurrent()
        try await work()
        let duration = CFAbsoluteTimeGetCurrent() - start
        log(.timing, "✓ \(name)", duration: duration, groupId: group.id)
    }

    /// Ends a timing group and logs the total duration
    func endGroup(_ group: TimingGroup) {
        guard let startTime = groupStartTimes[group.id] else { return }
        let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
        groupStartTimes.removeValue(forKey: group.id)

        let entry = LogEntry(
            level: .timing,
            message: group.name,
            duration: totalDuration,
            isTimingStart: false,
            groupId: group.id,
            groupName: group.name,
            isGroupEnd: true
        )
        store.append(entry)
    }

    // MARK: - Scoped Group Timing (Option B)

    /// Times a group of operations using a scoped closure
    func timedGroup<T: Sendable>(_ name: String, _ work: (TimingGroupContext) async throws -> T) async rethrows -> T {
        let group = TimingGroup(name)
        let context = TimingGroupContext(group: group, logger: self)
        groupStartTimes[group.id] = CFAbsoluteTimeGetCurrent()

        let result = try await work(context)

        endGroup(group)
        return result
    }

    /// Times a group of operations using a scoped closure (no return value)
    func timedGroup(_ name: String, _ work: (TimingGroupContext) async throws -> Void) async rethrows {
        let group = TimingGroup(name)
        let context = TimingGroupContext(group: group, logger: self)
        groupStartTimes[group.id] = CFAbsoluteTimeGetCurrent()

        try await work(context)

        endGroup(group)
    }

    // MARK: - Private Helpers

    private func log(
        _ level: LogLevel,
        _ message: String,
        duration: TimeInterval? = nil,
        isTimingStart: Bool = false,
        groupId: String? = nil,
        groupName: String? = nil
    ) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            duration: duration,
            isTimingStart: isTimingStart,
            groupId: groupId,
            groupName: groupName
        )
        store.append(entry)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1.0 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.2fs", duration)
        }
    }

    /// Format timestamp for display
    func formatTimestamp(_ date: Date) -> String {
        timestampFormatter.string(from: date)
    }
}
