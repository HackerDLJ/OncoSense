import Foundation

struct ScreeningEngine {
    static func analyze(_ snapshots: [HealthSnapshot], baseline: HealthSnapshot?) -> ScreeningResult {
        guard let latest = snapshots.sorted(by: { $0.timestamp > $1.timestamp }).first else { return .demo }
        guard let baseline else {
            return ScreeningResult(state: .low, signal: 0, persistenceDays: 0, dataQuality: 20, summary: "Building your personal baseline.", contributors: ["Collecting heart pattern", "Collecting breathing pattern", "Collecting sleep pattern", "Collecting activity pattern"], generatedAt: .now)
        }

        var deviations: [(String, Double)] = []
        if let h = latest.restingHeartRate, let b = baseline.restingHeartRate, b > 0 { deviations.append(("Heart pattern", abs((h - b) / b) * 100)) }
        if let h = latest.hrv, let b = baseline.hrv, b > 0 { deviations.append(("HRV", abs((h - b) / b) * 100)) }
        if let r = latest.respiratoryRate, let b = baseline.respiratoryRate, b > 0 { deviations.append(("Breathing", abs((r - b) / b) * 100)) }
        if let t = latest.temperature, let b = baseline.temperature { deviations.append(("Temperature", abs(t - b) * 100)) }
        if let s = latest.sleepHours, let b = baseline.sleepHours, b > 0 { deviations.append(("Sleep", abs((s - b) / b) * 100)) }
        if let a = latest.activityMinutes, let b = baseline.activityMinutes, b > 0 { deviations.append(("Activity", abs((a - b) / b) * 100)) }

        let meaningful = deviations.filter { $0.1 >= 10 }
        let score = min(100, Int(meaningful.reduce(0) { $0 + min($1.1, 25) } * 1.5))
        let quality = min(100, 35 + deviations.count * 11)
        let state: ScreeningState = meaningful.count >= 3 ? .earlySignal : meaningful.count >= 1 ? .watch : .low
        let summary: String
        switch state {
        case .low: summary = "Your recent physiological pattern is stable."
        case .watch: summary = "A small physiological change is being watched against your baseline."
        case .earlySignal: summary = "Several physiological signals have changed together. Review the details on your iPhone."
        }
        let contributors = deviations.prefix(4).map { "\($0.0) · \($0.1 >= 10 ? "Changed" : "Stable")" }
        return ScreeningResult(state: state, signal: score, persistenceDays: meaningful.isEmpty ? 0 : 1, dataQuality: quality, summary: summary, contributors: contributors, generatedAt: .now)
    }
}
