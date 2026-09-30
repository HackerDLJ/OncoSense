import Foundation
import HealthKit

/// Reads user-authorized longitudinal health signals from Apple Health.
/// The app never treats these measurements as a cancer diagnosis.
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
