import SwiftUI

@main
struct OncoSenseWatchApp: App {
    @StateObject private var health = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(health)
        }
    }
}
