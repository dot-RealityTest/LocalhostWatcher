import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let appContext: AppContext
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var subscriptions = Set<AnyCancellable>()

    init(appContext: AppContext) {
        self.appContext = appContext
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configurePopover()
        configureStatusItem()
        bindState()
        updateButton()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 340, height: 320)
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(appContext.watcherViewModel)
                .environmentObject(appContext.launchAtLoginService)
                .environmentObject(appContext.autoStartService)
        )
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeading
        button.toolTip = "Localhost Watcher"
    }

    private func bindState() {
        appContext.watcherViewModel.$processes
            .sink { [weak self] _ in
                self?.updateButton()
            }
            .store(in: &subscriptions)

        appContext.watcherViewModel.$healthStatuses
            .sink { [weak self] _ in
                self?.updateButton()
            }
            .store(in: &subscriptions)
    }

    private func updateButton() {
        guard let button = statusItem.button else { return }

        let symbolName = appContext.watcherViewModel.hasUnhealthyServer
            ? "point.3.filled.connected.trianglepath.dotted"
            : "point.3.connected.trianglepath.dotted"
        let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Localhost Watcher")?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = true

        button.image = image
        button.contentTintColor = .labelColor
        button.title = "\(appContext.watcherViewModel.processes.count)"
        button.setAccessibilityLabel("Localhost Watcher")
        button.setAccessibilityValue(menuBarSummary)
        button.toolTip = menuBarSummary
    }

    private var menuBarSummary: String {
        let count = appContext.watcherViewModel.processes.count
        let countText = count == 1 ? "1 active server" : "\(count) active servers"
        return appContext.watcherViewModel.hasUnhealthyServer ? "\(countText), attention needed" : countText
    }

    @objc private func handleStatusItemClick(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }

        switch event.type {
        case .rightMouseUp:
            showContextMenu()
        default:
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showContextMenu() {
        guard let button = statusItem.button else { return }

        statusItem.menu = makeContextMenu()
        button.performClick(nil)
        statusItem.menu = nil
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()

        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let killUnhealthyItem = NSMenuItem(title: "Kill All Unhealthy", action: #selector(killAllUnhealthy), keyEquivalent: "")
        killUnhealthyItem.target = self
        killUnhealthyItem.isEnabled = appContext.watcherViewModel.unhealthyCount > 0
        menu.addItem(killUnhealthyItem)

        menu.addItem(.separator())

        let activeItem = NSMenuItem(title: "Show Active", action: #selector(showActive), keyEquivalent: "")
        activeItem.target = self
        activeItem.state = selectedPanelTab == .active ? .on : .off
        menu.addItem(activeItem)

        let loginItem = NSMenuItem(title: "Show Login", action: #selector(showLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = selectedPanelTab == .login ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let launchAtLoginItem = NSMenuItem(title: "Launch Watcher at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = appContext.launchAtLoginService.isEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About Localhost Watcher", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Localhost Watcher", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func refreshNow() {
        appContext.watcherViewModel.refresh()
    }

    @objc private func killAllUnhealthy() {
        appContext.watcherViewModel.stopUnhealthyProcesses()
    }

    @objc private func showActive() {
        selectedPanelTab = .active
    }

    @objc private func showLogin() {
        selectedPanelTab = .login
    }

    @objc private func toggleLaunchAtLogin() {
        appContext.launchAtLoginService.setEnabled(!appContext.launchAtLoginService.isEnabled)
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private var selectedPanelTab: PanelTab {
        get {
            let rawValue = UserDefaults.standard.string(forKey: "selectedPanelTab") ?? PanelTab.active.rawValue
            return PanelTab(rawValue: rawValue) ?? .active
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedPanelTab")
        }
    }
}

@MainActor
final class LocalhostWatcherAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(appContext: AppContext.shared)
    }
}
