import Foundation
import Combine
import HealthKit

@MainActor
final class HealthDataManager: ObservableObject {
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let quantityIDs: [HKQuantityTypeIdentifier] = [
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .respiratoryRate,
            .appleExerciseTime,
            .appleSleepingWristTemperature
        ]
        for id in quantityIDs {
            if let type = HKObjectType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "OncoSense.Health", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data is unavailable on this device."])
        }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchLatestSnapshot() async throws -> HealthSnapshot {
        async let heart = latest(.restingHeartRate, unit: .count().unitDivided(by: .minute()))
        async let hrv = latest(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let respiratory = latest(.respiratoryRate, unit: .count().unitDivided(by: .minute()))
        async let temperature = latest(.appleSleepingWristTemperature, unit: .degreeCelsius())
        async let activity = total(.appleExerciseTime, unit: .minute(), since: Date().addingTimeInterval(-86400))
        async let sleep = sleepHours(since: Date().addingTimeInterval(-86400))

        return HealthSnapshot(
            timestamp: .now,
            source: HealthSnapshotSource.healthKit.rawValue,
            restingHeartRate: try await heart,
            hrv: try await hrv,
            respiratoryRate: try await respiratory,
            temperature: try await temperature,
            sleepHours: try await sleep,
            activityMinutes: try await activity
        )
    }

    private func latest(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { return nil }
        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func total(_ id: HKQuantityTypeIdentifier, unit: HKUnit, since: Date) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: since, end: .now, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func sleepHours(since: Date) async throws -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: since, end: .now, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let totalSeconds = (samples as? [HKCategorySample] ?? []).reduce(0.0) { partial, sample in
                    let value = sample.value
                    let asleep = value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                        || value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                        || value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                        || value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    return asleep ? partial + sample.endDate.timeIntervalSince(sample.startDate) : partial
                }
                continuation.resume(returning: totalSeconds > 0 ? totalSeconds / 3600.0 : nil)
            }
            store.execute(query)
        }
    }
}
