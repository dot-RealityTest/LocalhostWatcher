import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: WatcherViewModel
    @EnvironmentObject private var launchAtLogin: LaunchAtLoginService
    @EnvironmentObject private var autoStartService: AutoStartService
    @AppStorage("selectedPanelTab") private var selectedTabRawValue = PanelTab.active.rawValue

    var body: some View {
        GeometryReader { proxy in
            let layout = ResponsiveLayout(width: proxy.size.width)

            VStack(spacing: 0) {
                header(layout: layout)
                Divider()
                content(layout: layout)
                Divider()
                footer(layout: layout)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 260, minHeight: 280)
    }

    // MARK: - Header

    @ViewBuilder
    private func header(layout: ResponsiveLayout) -> some View {
        if layout == .compact {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Localhost Watcher", systemImage: "network")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    refreshButton
                }

                Text(statusSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        } else {
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.primary)
                Text("Localhost Watcher")
                    .font(.headline)
                Spacer()
                Text(statusSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                refreshButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var refreshButton: some View {
        Button {
            vm.refresh()
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(.plain)
        .help("Refresh now")
        .accessibilityLabel("Refresh")
    }

    private var statusSummary: String {
        switch selectedTab {
        case .active:
            let countLabel = vm.processes.count == 1 ? "1 server" : "\(vm.processes.count) servers"
            guard vm.unhealthyCount > 0 else {
                return countLabel
            }

            let unhealthyLabel = vm.unhealthyCount == 1 ? "1 unhealthy" : "\(vm.unhealthyCount) unhealthy"
            return "\(countLabel) · \(unhealthyLabel)"
        case .login:
            return loginConfigurations.count == 1 ? "1 saved app" : "\(loginConfigurations.count) saved apps"
        }
    }

    // MARK: - Empty state

    private var activeEmptyState: some View {
        ContentUnavailableView(
            "No Servers Detected",
            systemImage: "server.rack",
            description: Text("Launch a localhost service and refresh to see it here.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loginEmptyState: some View {
        ContentUnavailableView(
            "No Login Apps Saved",
            systemImage: "powerplug",
            description: Text("Save running servers from the Active view to relaunch them at login.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - List

    @ViewBuilder
    private func content(layout: ResponsiveLayout) -> some View {
        switch selectedTab {
        case .active:
            if vm.processes.isEmpty {
                activeEmptyState
            } else {
                serverList(layout: layout)
            }
        case .login:
            if loginConfigurations.isEmpty {
                loginEmptyState
            } else {
                loginSection(layout: layout)
            }
        }
    }

    private func serverList(layout: ResponsiveLayout) -> some View {
        VStack(spacing: 0) {
            if layout == .regular {
                listHeader
                Divider()
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.processes) { process in
                        ServerRow(
                            process: process,
                            healthStatus: vm.healthStatuses[process.port] ?? .unknown,
                            tick: vm.tick,
                            layout: layout,
                            isSavedForLogin: autoStartService.isEnabled(for: process)
                        ) {
                            vm.stop(process: process)
                        } onSaveToLogin: {
                            if !launchAtLogin.isEnabled {
                                launchAtLogin.setEnabled(true)
                            }
                            autoStartService.setEnabled(true, for: process)
                        }
                        Divider().padding(.leading, layout == .compact ? 12 : 16)
                    }
                }
            }
        }
    }

    private var listHeader: some View {
        HStack {
            Text("PROCESS").frame(maxWidth: .infinity, alignment: .leading)
            Text("PORT").frame(width: 60, alignment: .trailing)
            Text("UPTIME").frame(width: 90, alignment: .trailing)
            Text("LOGIN").frame(width: 58, alignment: .center)
            Spacer().frame(width: 34)   // Open
            Spacer().frame(width: 44)   // Stop
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func loginSection(layout: ResponsiveLayout) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Saved for Login")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !launchAtLogin.isEnabled {
                    Text("Enable watcher launch at login to run saved apps")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, layout == .compact ? 12 : 16)
            .padding(.vertical, 8)

            ForEach(loginConfigurations) { configuration in
                LoginRow(
                    configuration: configuration,
                    activeProcess: vm.processes.first(where: { $0.port == configuration.port }),
                    layout: layout
                ) {
                    autoStartService.removeConfiguration(port: configuration.port)
                }

                if configuration.id != loginConfigurations.last?.id {
                    Divider().padding(.leading, layout == .compact ? 12 : 16)
                }
            }
        }
    }

    @ViewBuilder
    private func footer(layout: ResponsiveLayout) -> some View {
        if layout == .compact {
            HStack(spacing: 12) {
                viewModeToggle
                launchAtLoginToggle

                Spacer()

                quitButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        } else {
            HStack(spacing: 12) {
                viewModeToggle
                launchAtLoginToggle

                Spacer()

                quitButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var quitButton: some View {
        Button("Quit") {
            NSApp.terminate(nil)
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var viewModeToggle: some View {
        Toggle(isOn: loginModeBinding) {
            Text("Login View")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .help("Switch between active servers and saved login apps")
        .accessibilityLabel("Login view")
    }

    private var launchAtLoginToggle: some View {
        Toggle(isOn: launchAtLoginBinding) {
            Text("Launch Watcher at Login")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin.isEnabled },
            set: { launchAtLogin.setEnabled($0) }
        )
    }

    private var loginConfigurations: [AutoStartConfiguration] {
        autoStartService.configurations
    }

    private var loginModeBinding: Binding<Bool> {
        Binding(
            get: { selectedTab == .login },
            set: { selectedTab = $0 ? .login : .active }
        )
    }

    private var selectedTab: PanelTab {
        get { PanelTab(rawValue: selectedTabRawValue) ?? .active }
        nonmutating set { selectedTabRawValue = newValue.rawValue }
    }

}

enum PanelTab: String {
    case active
    case login
}

enum ResponsiveLayout {
    case compact
    case regular

    init(width: CGFloat) {
        self = width < 360 ? .compact : .regular
    }
}

// MARK: - Row

struct ServerRow: View {
    let process: ServerProcess
    let healthStatus: HealthStatus
    let tick: Int
    let layout: ResponsiveLayout
    let isSavedForLogin: Bool
    let onStop: () -> Void
    let onSaveToLogin: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var confirmStop = false

    private var localURL: URL { URL(string: "http://localhost:\(process.port)")! }

    var body: some View {
        Group {
            if layout == .compact {
                compactRow
            } else {
                regularRow
            }
        }
        .padding(.horizontal, layout == .compact ? 12 : 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var regularRow: some View {
        HStack(spacing: 12) {
            healthIndicator

            processSummary
                .frame(maxWidth: .infinity, alignment: .leading)

            portButton
                .frame(width: 60, alignment: .trailing)

            uptimeText
                .frame(width: 90, alignment: .trailing)

            loginControl
                .frame(width: 58)

            openButton
                .frame(width: 34)

            stopControls
                .frame(width: 44, alignment: .trailing)
        }
    }

    private var compactRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                healthIndicator

                processSummary

                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    openButton
                    stopControls
                }
            }

            HStack(spacing: 12) {
                portButton
                Spacer(minLength: 0)
                loginControl
                uptimeText
            }
            .padding(.leading, 30)
        }
    }

    private var healthIndicator: some View {
        Circle()
            .fill(healthColor)
            .frame(width: 8, height: 8)
            .frame(width: 20)
            .help(healthDescription)
    }

    private var processSummary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(process.name)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
            Text("PID \(process.id)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var portButton: some View {
        Button {
            openURL(localURL)
        } label: {
            Text(":\(process.port)")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .help("Open http://localhost:\(process.port)")
    }

    private var uptimeText: some View {
        Text(process.formattedUptime)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var loginControl: some View {
        if isSavedForLogin {
            utilityBadge("Saved", tint: .secondary)
        } else if process.canStartAtLogin {
            Button {
                onSaveToLogin()
            } label: {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Add to Login")
            .accessibilityLabel("Save for login")
        } else {
            Text("—")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .help("Launch command unavailable")
        }
    }

    private var openButton: some View {
        Button {
            openURL(localURL)
        } label: {
            Image(systemName: "arrow.up.right.square")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Open in browser")
        .accessibilityLabel("Open localhost port")
    }

    @ViewBuilder
    private var stopControls: some View {
        if confirmStop {
            HStack(spacing: 8) {
                Button {
                    confirmStop = false
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cancel stop")
                .accessibilityLabel("Cancel stop")

                Button {
                    confirmStop = false
                    onStop()
                } label: {
                    Text("Stop")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Confirm stop process")
                .accessibilityLabel("Confirm stop")
            }
        } else {
            Button("Stop") {
                confirmStop = true
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.red)
            .help("Stop process")
            .accessibilityLabel("Stop process")
        }
    }

    private func utilityBadge(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
            }
    }

    private var healthColor: Color {
        switch healthStatus {
        case .healthy:
            return Color.secondary.opacity(0.8)
        case .unhealthy:
            return .red
        case .unknown:
            return Color.secondary.opacity(0.35)
        }
    }

    private var healthDescription: String {
        switch healthStatus {
        case .healthy:
            return "Healthy HTTP endpoint"
        case .unhealthy:
            return "HTTP endpoint responded with an error or stopped accepting connections"
        case .unknown:
            return "Health check inconclusive or non-HTTP service"
        }
    }
}

struct LoginRow: View {
    let configuration: AutoStartConfiguration
    let activeProcess: ServerProcess?
    let layout: ResponsiveLayout
    let onRemove: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var confirmRemove = false

    private var isRunning: Bool {
        activeProcess != nil
    }

    private var localURL: URL { URL(string: "http://localhost:\(configuration.port)")! }

    var body: some View {
        Group {
            if layout == .compact {
                compactRow
            } else {
                regularRow
            }
        }
        .padding(.horizontal, layout == .compact ? 12 : 16)
        .padding(.vertical, 10)
    }

    private var regularRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isRunning ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(configuration.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(configuration.workingDirectory ?? configuration.launchCommand)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(":\(configuration.port)")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)

            openButton

            statusBadge
                .frame(width: 76, alignment: .trailing)

            removeControls
        }
    }

    private var compactRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(isRunning ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(configuration.name)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    HStack(spacing: 6) {
                        Text(":\(configuration.port)")
                        statusBadge
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                openButton
                removeControls
            }

            Text(configuration.workingDirectory ?? configuration.launchCommand)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .padding(.leading, 30)
        }
    }

    private var statusBadge: some View {
        utilityBadge(isRunning ? "Running" : "On Login", tint: isRunning ? .green : .secondary)
    }

    @ViewBuilder
    private var removeControls: some View {
        if confirmRemove {
            HStack(spacing: 8) {
                Button {
                    confirmRemove = false
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cancel remove")

                Button {
                    confirmRemove = false
                    onRemove()
                } label: {
                    Text("Remove")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Confirm remove from Login")
            }
        } else {
            Button("Remove") {
                confirmRemove = true
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.red)
            .help("Remove from Login")
        }
    }

    private var openButton: some View {
        Button {
            openURL(localURL)
        } label: {
            Image(systemName: "arrow.up.right.square")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Open http://localhost:\(configuration.port)")
        .accessibilityLabel("Open localhost port")
    }

    private func utilityBadge(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
            }
    }
}
