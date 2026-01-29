import Foundation

/// Generic process executor for running shell commands.
///
/// Provides a reusable, nonisolated async interface for executing
/// shell commands with proper environment setup and error handling.
///
/// ## Example Usage
/// ```swift
/// let output = try await ProcessExecutor.run(
///     executable: "/usr/bin/git",
///     arguments: ["status"],
///     workingDirectory: repoURL
/// )
/// ```
public struct ProcessExecutor: Sendable {

    /// Errors that can occur during process execution.
    public enum ProcessError: LocalizedError, Sendable, Equatable {
        /// The command failed with the given output.
        case commandFailed(String)
        /// The command timed out.
        case timeout

        public var errorDescription: String? {
            switch self {
            case .commandFailed(let message):
                return "Command failed: \(message)"
            case .timeout:
                return "Process timed out"
            }
        }
    }

    /// Runs a command and returns its output.
    ///
    /// This method is nonisolated and Sendable, allowing parallel execution
    /// from multiple actors without requiring synchronization.
    ///
    /// - Parameters:
    ///   - executable: Full path to the executable (e.g., "/usr/bin/git")
    ///   - arguments: Command-line arguments to pass
    ///   - workingDirectory: Directory to run the command in
    ///   - environment: Optional custom environment variables. If nil, uses `defaultEnvironment()`
    ///   - timeout: Maximum time to wait for the command to complete (default: 30 seconds)
    /// - Returns: The command's standard output as a string
    /// - Throws: `ProcessError.commandFailed` if the command exits with non-zero status,
    ///           `ProcessError.timeout` if the command exceeds the timeout
    public static func run(
        executable: String,
        arguments: [String],
        workingDirectory: URL,
        environment: [String: String]? = nil,
        timeout: TimeInterval = 30.0
    ) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory
        process.environment = environment ?? defaultEnvironment()

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()

        // Read pipe data BEFORE waiting - prevents buffer deadlock.
        // If the process outputs more than ~64KB, it will block waiting
        // to write to the pipe. Reading first prevents this deadlock.
        async let outputTask: Data = {
            outputPipe.fileHandleForReading.readDataToEndOfFile()
        }()
        async let errorTask: Data = {
            errorPipe.fileHandleForReading.readDataToEndOfFile()
        }()

        // Wait for process with timeout using a thread-safe state wrapper
        final class ResumeState: @unchecked Sendable {
            private let lock = NSLock()
            private var hasResumed = false

            func tryResume() -> Bool {
                lock.lock()
                defer { lock.unlock() }
                if hasResumed {
                    return false
                }
                hasResumed = true
                return true
            }
        }

        let didComplete = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let state = ResumeState()

            DispatchQueue.global().async {
                process.waitUntilExit()
                if state.tryResume() {
                    continuation.resume(returning: true)
                }
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if state.tryResume() {
                    process.terminate()
                    continuation.resume(returning: false)
                }
            }
        }

        // Await the pipe reads
        let outputData = await outputTask
        let errorData = await errorTask

        if !didComplete {
            throw ProcessError.timeout
        }

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw ProcessError.commandFailed(errorOutput.isEmpty ? output : errorOutput)
        }

        return output
    }

    /// Returns a default environment with standard PATH locations.
    ///
    /// Ensures common tool locations are available:
    /// - `/opt/homebrew/bin` (Apple Silicon Homebrew)
    /// - `/usr/local/bin` (Intel Homebrew)
    /// - `/usr/bin`, `/bin` (System binaries)
    ///
    /// - Returns: Environment dictionary suitable for Process.environment
    public static func defaultEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        environment["HOME"] = home

        let standardPaths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
        if let existing = environment["PATH"], !existing.isEmpty {
            let parts = Set(existing.split(separator: ":").map(String.init))
            let missing = standardPaths.filter { !parts.contains($0) }
            if !missing.isEmpty {
                environment["PATH"] = existing + ":" + missing.joined(separator: ":")
            }
        } else {
            environment["PATH"] = standardPaths.joined(separator: ":")
        }

        return environment
    }
}
