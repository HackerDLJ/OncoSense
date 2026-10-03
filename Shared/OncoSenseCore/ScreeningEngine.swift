import Foundation

struct ScreeningEngine {
    static func analyze(_ snapshots: [HealthSnapshot]) -> ScreeningResult? {
        let ordered = snapshots.sorted { $0.timestamp > $1.timestamp }
        guard let latest = ordered.first, ordered.count >= 3 else { return nil }

        let history = Array(ordered.dropFirst().prefix(28))
        guard history.count >= 2 else { return nil }

        let metrics: [(String, Double?, (HealthSnapshot) -> Double?)] = [
            ("Resting heart rate", latest.restingHeartRate, { $0.restingHeartRate }),
            ("Heart-rate variability", latest.hrv, { $0.hrv }),
            ("Respiratory rate", latest.respiratoryRate, { $0.respiratoryRate }),
            ("Wrist temperature", latest.temperature, { $0.temperature }),
            ("Sleep duration", latest.sleepHours, { $0.sleepHours }),
            ("Exercise time", latest.activityMinutes, { $0.activityMinutes })
        ]

        var deviations: [(name: String, percent: Double)] = []
        var observed = 0
        for (name, current, keyPath) in metrics {
            let baselineValues = history.compactMap(keyPath)
            guard let current, baselineValues.count >= 2 else { continue }
            observed += 1
            let baseline = median(baselineValues)
            guard baseline != 0 else { continue }
            let deviation = abs(current - baseline) / abs(baseline) * 100
            deviations.append((name, deviation))
        }

        let changed = deviations.filter { $0.percent >= 10 }
        let strongChanges = deviations.filter { $0.percent >= 20 }
        let score = min(100, Int((changed.reduce(0) { $0 + min($1.percent, 30) } * 1.2).rounded()))
        let quality = min(100, 35 + observed * 8 + min(history.count, 14) * 2)

        let recentDays = Set(ordered.prefix(14).map { Calendar.current.startOfDay(for: $0.timestamp) })
        let persistenceDays = recentDays.count

        let state: ScreeningState
        if strongChanges.count >= 2 && persistenceDays >= 3 {
            state = .earlySignal
        } else if changed.count >= 1 {
            state = .watch
        } else {
            state = .low
        }

        let summary: String
        switch state {
        case .low:
            summary = "Your available measurements are currently close to your personal baseline. Keep collecting data so the baseline becomes more reliable."
        case .watch:
            summary = "One or more measurements differ from your personal baseline. A single change can have many explanations, so watch the trend and add context if you feel different."
        case .earlySignal:
            summary = "Several measurements show a stronger, repeated departure from your personal baseline. This is a physiological pattern-change flag, not a cancer diagnosis. Persistent or concerning changes should be discussed with a clinician."
        }

        let contributors = deviations
            .sorted { $0.percent > $1.percent }
            .prefix(6)
            .map { item in
                "\(item.name) · \(Int(item.percent.rounded()))% from baseline"
            }

        return ScreeningResult(
            state: state,
            signal: score,
            persistenceDays: persistenceDays,
            dataQuality: quality,
            summary: summary,
            contributors: Array(contributors),
            generatedAt: .now
        )
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        if sorted.count % 2 == 0 {
            return (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
        }
        return sorted[sorted.count / 2]
    }
}
