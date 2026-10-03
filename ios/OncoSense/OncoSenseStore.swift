import Foundation
import Combine

@MainActor
final class OncoSenseStore: ObservableObject {
    @Published private(set) var result: ScreeningResult?
    @Published private(set) var snapshots: [HealthSnapshot] = []
    @Published private(set) var lastSnapshot: HealthSnapshot?
    @Published private(set) var isHealthConnected = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?

    let health = HealthDataManager()
    let sync = OncoSenseConnectivity.shared

    private let key = "oncosense.snapshots.v3"

    init() {
        load()
        sync.onSnapshot = { [weak self] snapshot in
            Task { @MainActor in
                self?.ingest(snapshot)
            }
        }
        sync.activate()
    }

    func connectHealth() {
        Task {
            do {
                try await health.requestAuthorization()
                isHealthConnected = true
                errorMessage = nil
                await refresh()
            } catch {
                isHealthConnected = false
                errorMessage = error.localizedDescription
            }
        }
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

    func ingest(_ snapshot: HealthSnapshot) {
        guard !snapshots.contains(where: { $0.id == snapshot.id }) else { return }
        snapshots.append(snapshot)
        snapshots.sort { $0.timestamp > $1.timestamp }
        snapshots = Array(snapshots.prefix(500))
        lastSnapshot = snapshots.first
        result = ScreeningEngine.analyze(snapshots)
        save()
    }

    var watchStatusText: String {
        if sync.isReachable { return "Watch connected" }
        if sync.isActivated { return "Watch available · waiting for connection" }
        return "Watch not connected"
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
}
