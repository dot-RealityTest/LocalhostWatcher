import Foundation

struct ServerProcess: Identifiable, Equatable {
    let id: Int          // PID
    let name: String
    let port: Int
    let startedAt: Date
    let launchCommand: String?
    let workingDirectory: String?

    var uptime: TimeInterval { Date().timeIntervalSince(startedAt) }

    var canStartAtLogin: Bool {
        guard let launchCommand else { return false }
        return !launchCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var formattedUptime: String {
        let s = Int(uptime)
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
        let h = s / 3600
        let m = (s % 3600) / 60
        return "\(h)h \(m)m"
    }

    static func == (lhs: ServerProcess, rhs: ServerProcess) -> Bool {
        lhs.id == rhs.id && lhs.port == rhs.port
    }
}
