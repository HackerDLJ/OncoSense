import Foundation
import Combine

@MainActor
final class OncoSenseStore: ObservableObject {
    @Published private(set) var result: ScreeningResult = .demo
    @Published private(set) var snapshots: [HealthSnapshot] = []
    @Published var isMonitoring = true

    private let key = "oncosense.snapshots.v2"

    init() {
        load()
    }

    func ingest(_ snapshot: HealthSnapshot) {
        snapshots.append(snapshot)
        snapshots = Array(snapshots.sorted { $0.timestamp > $1.timestamp }.prefix(500))
        let baseline = snapshots.last
        result = ScreeningEngine.analyze(snapshots, baseline: baseline)
        save()
    }

    func runDemoAnalysis() {
        let baseline = HealthSnapshot(timestamp: .now.addingTimeInterval(-86400), restingHeartRate: 62, hrv: 58, respiratoryRate: 15, temperature: 36.5, sleepHours: 7.5, activityMinutes: 35)
        let current = HealthSnapshot(timestamp: .now, restingHeartRate: 62, hrv: 58, respiratoryRate: 15, temperature: 36.5, sleepHours: 7.5, activityMinutes: 35)
        snapshots = [current, baseline]
        result = ScreeningEngine.analyze(snapshots, baseline: baseline)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(snapshots) { UserDefaults.standard.set(data, forKey: key) }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key), let values = try? JSONDecoder().decode([HealthSnapshot].self, from: data) else { return }
        snapshots = values
    }
}
