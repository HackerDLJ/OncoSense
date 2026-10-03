import Foundation
import Combine
import HealthKit

/// Reads user-authorized longitudinal health signals from Apple Health.
final class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()

    private let quantityTypes: [HKQuantityTypeIdentifier] = [
        .restingHeartRate,
        .heartRateVariabilitySDNN,
        .respiratoryRate,
        .appleExerciseTime,
        .appleStandTime,
        .appleSleepingWristTemperature,
        .oxygenSaturation
    ]

    func requestAuthorization(completion: @escaping (Result<Void, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(NSError(domain: "OncoSense", code: 2, userInfo: [NSLocalizedDescriptionKey: "Health data is unavailable on this device."])))
            return
        }
        let readTypes = Set(quantityTypes.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(error)); return }
                if success { completion(.success(())) }
                else { completion(.failure(NSError(domain: "OncoSense", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health access was not granted."]))) }
            }
        }
    }
}
