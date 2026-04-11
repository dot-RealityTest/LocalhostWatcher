import SwiftUI
import AppKit

@main
struct LocalhostWatcherApp: App {
    @AppStorage("selectedPanelTab") private var selectedPanelTab = PanelTab.active.rawValue
    @NSApplicationDelegateAdaptor(LocalhostWatcherAppDelegate.self) private var appDelegate
    private let appContext = AppContext.shared
    private static let bundledAppIcon = loadBundledAppIcon()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        Self.configureAppIcon()
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appInfo) {
                Button("About Localhost Watcher") {
                    Self.showAboutPanel()
                }
            }
            CommandMenu("Watcher") {
                Button("Refresh Now") {
                    appContext.watcherViewModel.refresh()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Divider()

                Button("Show Active") {
                    selectedPanelTab = PanelTab.active.rawValue
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Show Login") {
                    selectedPanelTab = PanelTab.login.rawValue
                }
                .keyboardShortcut("2", modifiers: [.command])

                Divider()

                Button("About Localhost Watcher") {
                    Self.showAboutPanel()
                }

                Divider()

                Button("Quit Localhost Watcher") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
        }
    }

    private static func configureAppIcon() {
        guard let iconImage = bundledAppIcon else {
            return
        }

        NSApplication.shared.applicationIconImage = iconImage
    }

    private static func showAboutPanel() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"

        NSApp.orderFrontStandardAboutPanel([
            NSApplication.AboutPanelOptionKey.applicationVersion: "\(version) · Made by kika",
            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(string: "Made by kika")
        ])
    }

    private static func loadBundledAppIcon() -> NSImage? {
        guard
            let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "icns"),
            let iconImage = NSImage(contentsOf: iconURL)
        else {
            return nil
        }

        iconImage.isTemplate = false
        return iconImage
    }
}
