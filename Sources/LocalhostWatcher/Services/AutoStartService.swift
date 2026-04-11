import Foundation
import Combine

final class AutoStartService: ObservableObject {
    @Published private(set) var configurationsByPort: [Int: AutoStartConfiguration] = [:]

    private let defaults: UserDefaults
    private let storageKey = "LocalhostWatcher.AutoStartConfigurations"
    private var hasAttemptedLaunch = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func isEnabled(for process: ServerProcess) -> Bool {
        configurationsByPort[process.port] != nil
    }

    var configurations: [AutoStartConfiguration] {
        configurationsByPort.values.sorted(by: { $0.port < $1.port })
    }

    func setEnabled(_ enabled: Bool, for process: ServerProcess) {
        if enabled {
            guard
                let launchCommand = process.launchCommand?.trimmingCharacters(in: .whitespacesAndNewlines),
                !launchCommand.isEmpty
            else {
                return
            }

            configurationsByPort[process.port] = AutoStartConfiguration(
                port: process.port,
                name: process.name,
                launchCommand: launchCommand,
                workingDirectory: process.workingDirectory
            )
        } else {
            configurationsByPort.removeValue(forKey: process.port)
        }

        persist()
    }

    func removeConfiguration(port: Int) {
        configurationsByPort.removeValue(forKey: port)
        persist()
    }

    @discardableResult
    func launchSavedProcessesIfNeeded(skipping activePorts: Set<Int>) -> Bool {
        guard !hasAttemptedLaunch else { return false }
        hasAttemptedLaunch = true

        var launchedAny = false
        for configuration in configurationsByPort.values.sorted(by: { $0.port < $1.port }) {
            guard !activePorts.contains(configuration.port) else { continue }
            launchedAny = launch(configuration) || launchedAny
        }

        return launchedAny
    }

    private func launch(_ configuration: AutoStartConfiguration) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", configuration.launchCommand]
        task.standardOutput = nil
        task.standardError = nil

        if let workingDirectory = configuration.workingDirectory, !workingDirectory.isEmpty {
            task.currentDirectoryURL = URL(fileURLWithPath: workingDirectory, isDirectory: true)
        }

        do {
            try task.run()
            return true
        } catch {
            NSLog("[AutoStart] Failed to launch port %d (%@): %@", configuration.port, configuration.name, error.localizedDescription)
            return false
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }

        do {
            let configurations = try JSONDecoder().decode([AutoStartConfiguration].self, from: data)
            configurationsByPort = Dictionary(uniqueKeysWithValues: configurations.map { ($0.port, $0) })
        } catch {
            NSLog("[AutoStart] Failed to decode saved configurations: %@", error.localizedDescription)
            configurationsByPort = [:]
        }
    }

    private func persist() {
        let configurations = configurationsByPort.values.sorted(by: { $0.port < $1.port })

        do {
            let data = try JSONEncoder().encode(configurations)
            defaults.set(data, forKey: storageKey)
        } catch {
            NSLog("[AutoStart] Failed to encode configurations: %@", error.localizedDescription)
        }
    }
}
