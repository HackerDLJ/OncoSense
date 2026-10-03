import Foundation

struct HealthSnapshot: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let restingHeartRate: Double?
    let hrv: Double?
    let respiratoryRate: Double?
    let temperature: Double?
    let sleepHours: Double?
    let activityMinutes: Double?

    init(id: UUID = UUID(), timestamp: Date = .now, restingHeartRate: Double? = nil, hrv: Double? = nil, respiratoryRate: Double? = nil, temperature: Double? = nil, sleepHours: Double? = nil, activityMinutes: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.restingHeartRate = restingHeartRate
        self.hrv = hrv
        self.respiratoryRate = respiratoryRate
        self.temperature = temperature
        self.sleepHours = sleepHours
        self.activityMinutes = activityMinutes
    }
}

enum ScreeningState: String, Codable {
    case low = "LOW"
    case watch = "WATCH"
    case earlySignal = "EARLY SIGNAL"

    var title: String { rawValue }
}

struct ScreeningResult: Codable, Equatable {
    let state: ScreeningState
    let signal: Int
    let persistenceDays: Int
    let dataQuality: Int
    let summary: String
    let contributors: [String]
    let generatedAt: Date

    static let demo = ScreeningResult(
        state: .low,
        signal: 12,
        persistenceDays: 0,
        dataQuality: 92,
        summary: "Your recent physiological pattern is stable.",
        contributors: ["Heart pattern · Stable", "Breathing · Stable", "Sleep · Stable", "Activity · Stable"],
        generatedAt: .now
    )
}
