import Foundation

@MainActor
final class HealthChecker: ObservableObject {
    @Published private(set) var statuses: [Int: HealthStatus] = [:]

    private let session: URLSession
    private var ports: [Int] = []
    private var timer: Timer?

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 2
            configuration.timeoutIntervalForResource = 2
            configuration.allowsCellularAccess = false
            configuration.waitsForConnectivity = false
            self.session = URLSession(configuration: configuration)
        }
    }

    func start() {
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func update(ports: [Int]) {
        self.ports = ports.sorted()

        let activePorts = Set(ports)
        statuses = statuses.filter { activePorts.contains($0.key) }

        Task {
            await checkAll()
        }
    }

    func checkAll() async {
        let currentPorts = ports
        guard !currentPorts.isEmpty else {
            statuses = [:]
            return
        }

        let session = self.session
        var nextStatuses: [Int: HealthStatus] = [:]

        await withTaskGroup(of: (Int, HealthStatus).self) { group in
            for port in currentPorts {
                group.addTask {
                    let status = await Self.probe(port: port, session: session)
                    return (port, status)
                }
            }

            for await (port, status) in group {
                nextStatuses[port] = status
            }
        }

        statuses = nextStatuses
    }

    private static func probe(port: Int, session: URLSession) async -> HealthStatus {
        guard let url = URL(string: "http://localhost:\(port)") else {
            return .unknown
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .unknown
            }

            if (200...399).contains(httpResponse.statusCode) {
                return .healthy
            }

            return .unhealthy
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                return .unknown
            case .cannotConnectToHost:
                return .unhealthy
            default:
                return .unknown
            }
        } catch {
            return .unknown
        }
    }
}
