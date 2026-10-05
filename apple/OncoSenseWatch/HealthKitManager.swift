import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    let store = HKHealthStore()

    @Published private(set) var authorizationReady = false

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let identifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .heartRateVariabilitySDNN,
            .respiratoryRate,
            .stepCount,
            .activeEnergyBurned,
            .appleExerciseTime
        ]
        for identifier in identifiers {
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if #available(watchOS 9.0, iOS 16.0, *) {
            if let temperature = HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature) {
                types.insert(temperature)
            }
        }
        return types
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes)
        authorizationReady = true
    }

    func fetchQuantitySamples(
        identifier: HKQuantityTypeIdentifier,
        from start: Date,
        to end: Date = .now
    ) async throws -> [HKQuantitySample] {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
            }
            store.execute(query)
        }
    }
}