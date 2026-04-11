import Foundation
import Testing
@testable import LocalhostWatcher

struct ResourceLoadingTests {
    @Test("bundled app icon can be loaded from the SwiftPM resource bundle")
    func bundledAppIconResourceExists() throws {
        let iconURL = try #require(Bundle.module.url(forResource: "AppIcon", withExtension: "icns"))

        #expect(iconURL.lastPathComponent == "AppIcon.icns")
        #expect(iconURL.isFileURL)
    }
}
