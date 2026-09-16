import SwiftUI

@main
struct TidelineMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}
