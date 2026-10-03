import Foundation

struct ScreeningEngine {
    static func analyze(_ snapshots: [HealthSnapshot]) -> ScreeningResult? {
        let ordered = snapshots.sorted { $0.timestamp > $1.timestamp }
        guard let latest = ordered.first, ordered.count >= 2 else { return nil }

        let history = Array(ordered.dropFirst()).prefix(30)
        let baseline = average(history)

        var deviations: [(String, Double)] = []
        if let h = latest.restingHeartRate, let b = baseline.restingHeartRate, b > 0 { deviations.append(("Resting heart rate", relativeDeviation(h, b))) }
        if let h = latest.hrv, let b = baseline.hrv, b > 0 { deviations.append(("Heart-rate variability", relativeDeviation(h, b))) }
        if let r = latest.respiratoryRate, let b = baseline.respiratoryRate, b > 0 { deviations.append(("Respiratory rate", relativeDeviation(r, b))) }
        if let t = latest.temperature, let b = baseline.temperature, b != 0 { deviations.append(("Wrist temperature", abs(t - b) / max(abs(b), 1) * 100)) }
        if let s = latest.sleepHours, let b = baseline.sleepHours, b > 0 { deviations.append(("Sleep duration", relativeDeviation(s, b))) }
        if let a = latest.activityMinutes, let b = baseline.activityMinutes, b > 0 { deviations.append(("Exercise time", relativeDeviation(a, b))) }

        let changed = deviations.filter { $0.1 >= 10 }
        let score = min(100, Int(changed.reduce(0) { $0 + min($1.1, 25) } * 1.5))
        let observed = deviations.count
        let quality = min(100, 20 + observed * 11 + min(history.count, 14) * 2)
        let persistentDays = ordered.filter { $0.timestamp >= Date().addingTimeInterval(-7 * 86400) }.reduce(into: Set<String>()) { days, snapshot in
            let day = Calendar.current.startOfDay(for: snapshot.timestamp)
            days.insert(ISO8601DateFormatter().string(from: day))
        }.count

        let state: ScreeningState = changed.count >= 3 ? .earlySignal : changed.count >= 1 ? .watch : .low
        let summary: String
        switch state {
        case .low:
            summary = "Your available measurements are close to your personal baseline. Keep collecting data so the baseline becomes more reliable."
        case .watch:
            summary = "At least one measured signal is meaningfully different from your personal baseline. The useful next step is to watch whether the change persists."
        case .earlySignal:
            summary = "Several measured signals differ from your personal baseline. This is a pattern-change flag, not a cancer diagnosis. Persistent or concerning changes should be reviewed with a clinician."
        }

        let contributors = deviations.sorted { $0.1 > $1.1 }.prefix(8).map { item in
            let status = item.1 >= 10 ? "Changed \(Int(item.1.rounded()))%" : "Within baseline"
            return "\(item.0) · \(status)"
        }

        return ScreeningResult(
            state: state,
            signal: score,
            persistenceDays: persistentDays,
            dataQuality: quality,
            summary: summary,
            contributors: Array(contributors),
            generatedAt: .now
        )
    }

    private static func relativeDeviation(_ value: Double, _ baseline: Double) -> Double {
        abs(value - baseline) / abs(baseline) * 100
    }

    private static func average(_ snapshots: ArraySlice<HealthSnapshot>) -> HealthSnapshot {
        func mean(_ values: [Double?]) -> Double? {
            let valid = values.compactMap { $0 }
            guard !valid.isEmpty else { return nil }
            return valid.reduce(0, +) / Double(valid.count)
        }
        return HealthSnapshot(
            timestamp: .now,
            source: HealthSnapshotSource.healthKit.rawValue,
            restingHeartRate: mean(snapshots.map(\.restingHeartRate)),
            heartRate: mean(snapshots.map(\.heartRate)),
            hrv: mean(snapshots.map(\.hrv)),
            respiratoryRate: mean(snapshots.map(\.respiratoryRate)),
            temperature: mean(snapshots.map(\.temperature)),
            sleepHours: mean(snapshots.map(\.sleepHours)),
            activityMinutes: mean(snapshots.map(\.activityMinutes)),
            steps: mean(snapshots.map(\.steps)),
            activeEnergy: mean(snapshots.map(\.activeEnergy)),
            weightKg: mean(snapshots.map(\.weightKg))
        )
    }
}
