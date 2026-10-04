import SwiftUI

@main
struct OncoSenseWatchApp: App {
    @StateObject private var health = HealthDataManager()
    @StateObject private var sync = OncoSenseConnectivity.shared

    init() {
        // Activate WatchConnectivity at process launch, not only after the
        // dashboard appears. This lets queued transfers be received reliably
        // when the Watch app is launched by the system.
        OncoSenseConnectivity.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(health)
                .environmentObject(sync)
        }
    }
}
