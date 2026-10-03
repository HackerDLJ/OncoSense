import SwiftUI

@main
struct OncoSenseWatchApp: App {
    @StateObject private var health = HealthDataManager()
    @StateObject private var sync = OncoSenseConnectivity.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(health)
                .environmentObject(sync)
        }
    }
}
