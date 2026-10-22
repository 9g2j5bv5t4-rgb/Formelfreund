import Foundation

/// Ergebnis eines externen Programmaufrufs.
public struct ProcessResult: Sendable {
    public var exitCode: Int32
    public var standardOutput: String
    public var standardError: String
}

/// Startet ein externes Programm (z. B. `tectonic`) asynchron.
///
/// - Wartet nie blockierend: Das Ende des Prozesses wird über Callbacks gemeldet.
/// - Liest Standard- und Fehlerausgabe parallel, damit volle Puffer den Prozess
///   nicht blockieren können.
/// - Wird die aufrufende Swift-Task abgebrochen (z. B. weil der Nutzer
///   weitertippt), wird der Prozess beendet.
public enum ProcessRunner {
    public enum RunError: Error, LocalizedError {
        case launchFailed(String)

        public var errorDescription: String? {
            switch self {
            case .launchFailed(let reason): return "Programm konnte nicht gestartet werden: \(reason)"
            }
        }
    }

    /// - Parameter onOutputLine: Wird für jede Ausgabezeile (stdout und stderr) aufgerufen,
    ///   z. B. um den Fortschritt anzuzeigen. Läuft auf einem Hintergrund-Thread.
    public static func run(
        executable: URL,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String]? = nil,
        onOutputLine: (@Sendable (String) -> Void)? = nil
    ) async throws -> ProcessResult {
        let state = RunState(onOutputLine: onOutputLine)

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ProcessResult, Error>) in
                state.start(
                    executable: executable,
                    arguments: arguments,
                    currentDirectory: currentDirectory,
                    environment: environment,
                    continuation: continuation
                )
            }
        } onCancel: {
            state.cancel()
        }
    }
}

/// Gemeinsamer Zustand eines laufenden Prozesses. Alle Zugriffe laufen über `lock`,
/// deshalb ist die Klasse trotz veränderlicher Felder threadsicher.
private final class RunState: @unchecked Sendable {
    private let lock = NSLock()
    private let process = Process()
    private let stdoutPipe = Pipe()
    private let stderrPipe = Pipe()
    private let onOutputLine: (@Sendable (String) -> Void)?

    private var stdoutData = Data()
    private var stderrData = Data()
    private var pendingLine = Data()
    private var stdoutClosed = false
    private var stderrClosed = false
    private var terminated = false
    private var launched = false
    private var cancelled = false
    private var continuation: CheckedContinuation<ProcessResult, Error>?

    init(onOutputLine: (@Sendable (String) -> Void)?) {
        self.onOutputLine = onOutputLine
    }

    func start(
        executable: URL,
        arguments: [String],
        currentDirectory: URL?,
        environment: [String: String]?,
        continuation: CheckedContinuation<ProcessResult, Error>
    ) {
        lock.lock()
        if cancelled {
            lock.unlock()
            continuation.resume(throwing: CancellationError())
            return
        }
        self.continuation = continuation
        lock.unlock()

        process.executableURL = executable
        process.arguments = arguments
        if let currentDirectory { process.currentDirectoryURL = currentDirectory }
        if let environment { process.environment = environment }
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = FileHandle.nullDevice

        process.terminationHandler = { [weak self] _ in
            self?.markTerminated()
        }

        do {
            try process.run()
            lock.lock()
            launched = true
            let shouldTerminate = cancelled
            lock.unlock()
            // Beide Ausgaben auf eigenen Threads lesen, bis das Programm sie schliesst.
            Thread.detachNewThread { self.drain(isStdout: true) }
            Thread.detachNewThread { self.drain(isStdout: false) }
            // Abbruch kam während des Starts: jetzt nachholen.
            if shouldTerminate { terminate() }
        } catch {
            lock.lock()
            let pending = self.continuation
            self.continuation = nil
            lock.unlock()
            pending?.resume(throwing: ProcessRunner.RunError.launchFailed(error.localizedDescription))
        }
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let shouldTerminate = launched && !terminated
        lock.unlock()
        guard shouldTerminate else { return }
        terminate()
    }

    /// Beendet den Prozess; reagiert er nicht auf SIGTERM, nach einer Sekunde hart.
    private func terminate() {
        process.terminate()
        let pid = process.processIdentifier
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.lock.lock()
            let stillRunning = !self.terminated
            self.lock.unlock()
            if stillRunning { kill(pid, SIGKILL) }
        }
    }

    /// Liest blockierend bis zum Dateiende (läuft auf einem eigenen Thread).
    private func drain(isStdout: Bool) {
        let handle = (isStdout ? stdoutPipe : stderrPipe).fileHandleForReading
        while true {
            let data = handle.availableData
            if data.isEmpty { break }
            append(data, isStdout: isStdout)
        }
        finishStream(isStdout: isStdout)
    }

    private func append(_ data: Data, isStdout: Bool) {
        var lines: [String] = []
        lock.lock()
        if isStdout { stdoutData.append(data) } else { stderrData.append(data) }
        if onOutputLine != nil {
            pendingLine.append(data)
            while let newline = pendingLine.firstIndex(of: 0x0A) {
                let lineData = pendingLine[pendingLine.startIndex..<newline]
                lines.append(String(decoding: lineData, as: UTF8.self))
                pendingLine.removeSubrange(pendingLine.startIndex...newline)
            }
        }
        lock.unlock()
        if let onOutputLine {
            for line in lines { onOutputLine(line) }
        }
    }

    private func finishStream(isStdout: Bool) {
        lock.lock()
        if isStdout { stdoutClosed = true } else { stderrClosed = true }
        lock.unlock()
        resumeIfFinished()
    }

    private func markTerminated() {
        lock.lock()
        terminated = true
        lock.unlock()
        resumeIfFinished()
    }

    /// Meldet das Ergebnis erst, wenn der Prozess beendet *und* alle Ausgaben gelesen sind.
    private func resumeIfFinished() {
        lock.lock()
        guard terminated, stdoutClosed, stderrClosed, let continuation else {
            lock.unlock()
            return
        }
        self.continuation = nil
        let wasCancelled = cancelled
        let result = ProcessResult(
            exitCode: process.terminationStatus,
            standardOutput: String(decoding: stdoutData, as: UTF8.self),
            standardError: String(decoding: stderrData, as: UTF8.self)
        )
        lock.unlock()

        if wasCancelled {
            continuation.resume(throwing: CancellationError())
        } else {
            continuation.resume(returning: result)
        }
    }
}
