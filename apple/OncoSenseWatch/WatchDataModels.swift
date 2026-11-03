import Foundation

struct WearableSnapshot: Codable, Sendable {
    let timestamp: Date
    let restingHeartRate: Double?
    let hrvSDNN: Double?
    let respiratoryRate: Double?
    let activeEnergy: Double?
    let exerciseMinutes: Double?
    let sleepHours: Double?
    let wristTemperatureDelta: Double?
}

struct ChangeSignature: Codable, Sendable {
    let windowDays: Int
    let anomalyScore: Double
    let persistenceScore: Double
    let status: Status
    let contributors: [Contributor]

    enum Status: String, Codable, Sendable {
        case baseline
        case watch
        case persistentChange
    }

    struct Contributor: Codable, Sendable, Identifiable {
        let id: String
        let metric: String
        let baseline: Double
        let current: Double
        let percentChange: Double
        let zScore: Double
        let direction: String
    }
}