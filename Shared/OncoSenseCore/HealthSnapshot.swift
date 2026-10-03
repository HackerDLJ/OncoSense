import Foundation

struct HealthSnapshot: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let source: String
    let restingHeartRate: Double?
    let heartRate: Double?
    let hrv: Double?
    let respiratoryRate: Double?
    let temperature: Double?
    let sleepHours: Double?
    let activityMinutes: Double?
    let steps: Double?
    let activeEnergy: Double?
    let weightKg: Double?

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        source: String = HealthSnapshotSource.healthKit.rawValue,
        restingHeartRate: Double? = nil,
        heartRate: Double? = nil,
        hrv: Double? = nil,
        respiratoryRate: Double? = nil,
        temperature: Double? = nil,
        sleepHours: Double? = nil,
        activityMinutes: Double? = nil,
        steps: Double? = nil,
        activeEnergy: Double? = nil,
        weightKg: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.restingHeartRate = restingHeartRate
        self.heartRate = heartRate
        self.hrv = hrv
        self.respiratoryRate = respiratoryRate
        self.temperature = temperature
        self.sleepHours = sleepHours
        self.activityMinutes = activityMinutes
        self.steps = steps
        self.activeEnergy = activeEnergy
        self.weightKg = weightKg
    }
}

enum HealthSnapshotSource: String, Codable {
    case healthKit = "HealthKit"
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
}
