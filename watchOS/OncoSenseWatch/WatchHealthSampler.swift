import Foundation
import HealthKit

final class WatchHealthSampler: ObservableObject {
    private let healthStore = HKHealthStore()
    private let transport = WatchTransport.shared

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let identifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .heartRateVariabilitySDNN,
            .respiratoryRate,
            .appleSleepingWristTemperature,
            .activeEnergyBurned
        ]
        let types = Set(identifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
        try await healthStore.requestAuthorization(toShare: [], read: types)
    }

    func sendDemoSnapshot() {
        let payload = WatchHealthPayload(
            heartRate: 68,
            hrv: 54,
            respiratoryRate: 15.2,
            temperature: 0.0,
            sleepDuration: 7.4,
            activity: 420
        )
        transport.send(payload)
    }
}
