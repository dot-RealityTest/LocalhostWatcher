import Foundation
import Combine

@MainActor
final class WatcherViewModel: ObservableObject {
    @Published var processes: [ServerProcess] = []
    @Published var healthStatuses: [Int: HealthStatus] = [:]
    @Published var tick: Int = 0

    var hasUnhealthyServer: Bool {
        healthStatuses.values.contains(.unhealthy)
    }

    var unhealthyCount: Int {
        healthStatuses.values.filter { $0 == .unhealthy }.count
    }

    var unhealthyProcesses: [ServerProcess] {
        processes.filter { healthStatuses[$0.port] == .unhealthy }
    }

    private let scanner: PortScanner
    private let healthChecker: HealthChecker
    private let autoStartService: AutoStartService
    private var refreshTimer: Timer?
    private var tickTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(
        scanner: PortScanner = PortScanner(),
        healthChecker: HealthChecker? = nil,
        autoStartService: AutoStartService? = nil
    ) {
        self.scanner = scanner
        self.healthChecker = healthChecker ?? HealthChecker()
        self.autoStartService = autoStartService ?? AutoStartService()

        self.healthChecker.$statuses
            .sink { [weak self] statuses in
                self?.healthStatuses = statuses
            }
            .store(in: &cancellables)

        startRefreshing()
    }

    func startRefreshing() {
        guard refreshTimer == nil, tickTimer == nil else { return }

        refresh()
        healthChecker.start()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }

        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick += 1 }
        }
    }

    func stopRefreshing() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        tickTimer?.invalidate()
        tickTimer = nil
        healthChecker.stop()
    }

    func refresh() {
        let scanner = self.scanner
        Task.detached {
            let found = scanner.scan()
            await MainActor.run { [weak self] in
                self?.processes = found
                self?.healthChecker.update(ports: found.map(\.port))

                let activePorts = Set(found.map(\.port))
                let launchedAny = self?.autoStartService.launchSavedProcessesIfNeeded(skipping: activePorts) ?? false
                if launchedAny {
                    self?.scheduleFollowUpRefresh()
                }
            }
        }
    }

    func stop(process: ServerProcess) {
        scanner.stop(process: process)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refresh()
        }
    }

    func stopUnhealthyProcesses() {
        let unhealthyProcesses = unhealthyProcesses
        guard !unhealthyProcesses.isEmpty else { return }

        for process in unhealthyProcesses {
            scanner.stop(process: process)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refresh()
        }
    }

    private func scheduleFollowUpRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.refresh()
        }
    }
}
