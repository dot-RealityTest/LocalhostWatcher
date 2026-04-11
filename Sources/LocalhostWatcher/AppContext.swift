import Foundation

@MainActor
final class AppContext {
    static let shared = AppContext()

    let launchAtLoginService: LaunchAtLoginService
    let autoStartService: AutoStartService
    let watcherViewModel: WatcherViewModel

    private init() {
        let autoStartService = AutoStartService()
        self.autoStartService = autoStartService
        self.launchAtLoginService = LaunchAtLoginService()
        self.watcherViewModel = WatcherViewModel(autoStartService: autoStartService)
    }
}
