import Foundation
import Combine
import UIKit

@MainActor
final class OncoSenseStore: ObservableObject {
    @Published private(set) var result: ScreeningResult?
    @Published private(set) var snapshots: [HealthSnapshot] = []
    @Published private(set) var lastSnapshot: HealthSnapshot?
    @Published private(set) var isHealthConnected = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published var isOnboardingComplete: Bool

    let health = HealthDataManager()
    let sync = OncoSenseConnectivity.shared

    private let key = "oncosense.snapshots.v5"
    private let onboardingKey = "oncosense.onboarding.complete.v1"

    init() {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: onboardingKey)
        configureTabBarAppearance()
        load()
        sync.onSnapshot = { [weak self] snapshot in
            Task { @MainActor in
                self?.ingest(snapshot)
            }
        }
        sync.activate()
        // Connectivity may activate asynchronously. The connectivity layer
        // retains this snapshot and sends it as soon as the session activates.
        if let latest = lastSnapshot {
            sync.send(snapshot: latest)
        }
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func resetOnboarding() {
        isOnboardingComplete = false
        UserDefaults.standard.set(false, forKey: onboardingKey)
    }

    func startSetup() async -> Bool {
        do {
            try await health.requestAuthorization()
            isHealthConnected = true
            errorMessage = nil
            await refresh()
            completeOnboarding()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func connectHealth() {
        Task { _ = await startSetup() }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let snapshot = try await health.fetchLatestSnapshot()
            isHealthConnected = true
            ingest(snapshot)
            sync.send(snapshot: snapshot)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func syncLatestToWatch() {
        sync.activate()
        if let latest = lastSnapshot {
            sync.send(snapshot: latest)
        }
        // This is queued, not a live message, so the Watch does not have to be
        // open at the exact moment the button is pressed.
        sync.requestSnapshotFromWatch()
    }

    func ingest(_ snapshot: HealthSnapshot) {
        if let existing = snapshots.first, measurementsMatch(existing, snapshot) {
            lastSnapshot = existing
            result = ScreeningEngine.analyze(snapshots)
            return
        }

        guard !snapshots.contains(where: { $0.id == snapshot.id }) else { return }
        snapshots.append(snapshot)
        snapshots.sort { $0.timestamp > $1.timestamp }
        snapshots = Array(snapshots.prefix(500))
        lastSnapshot = snapshots.first
        result = ScreeningEngine.analyze(snapshots)
        save()
    }

    var watchStatusText: String {
        guard sync.isActivated else {
            return sync.isPaired ? "Apple Watch paired · connecting" : "Looking for a paired Apple Watch"
        }
        guard sync.counterpartInstalled else {
            return sync.isPaired ? "Apple Watch paired · OncoSense Watch app not installed" : "No Apple Watch paired"
        }
        if sync.isReachable { return "Apple Watch connected now" }
        return "Apple Watch paired · background sync ready"
    }

    var availableSignalCount: Int {
        guard let snapshot = lastSnapshot else { return 0 }
        return [snapshot.restingHeartRate, snapshot.heartRate, snapshot.hrv, snapshot.respiratoryRate,
                snapshot.temperature, snapshot.sleepHours, snapshot.activityMinutes, snapshot.steps,
                snapshot.activeEnergy, snapshot.weightKg].compactMap { $0 }.count
    }

    var signalCoverage: Int {
        Int((Double(availableSignalCount) / 10.0 * 100).rounded())
    }

    private func measurementsMatch(_ a: HealthSnapshot, _ b: HealthSnapshot) -> Bool {
        a.restingHeartRate == b.restingHeartRate &&
        a.heartRate == b.heartRate &&
        a.hrv == b.hrv &&
        a.respiratoryRate == b.respiratoryRate &&
        a.temperature == b.temperature &&
        a.sleepHours == b.sleepHours &&
        a.activityMinutes == b.activityMinutes &&
        a.steps == b.steps &&
        a.activeEnergy == b.activeEnergy &&
        a.weightKg == b.weightKg
    }

    private func save() {
        if let data = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let values = try? JSONDecoder().decode([HealthSnapshot].self, from: data) else { return }
        snapshots = values.sorted { $0.timestamp > $1.timestamp }
        lastSnapshot = snapshots.first
        result = ScreeningEngine.analyze(snapshots)
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = true
    }
}
