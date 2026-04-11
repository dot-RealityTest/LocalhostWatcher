import Foundation

struct AutoStartConfiguration: Codable, Equatable, Identifiable {
    let port: Int
    let name: String
    let launchCommand: String
    let workingDirectory: String?

    var id: Int { port }
}
