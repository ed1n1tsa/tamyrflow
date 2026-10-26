import Foundation
import HealthKit

/// Read-only HealthKit helpers for wellness metrics (sleep, heart rate; SpO₂/temp later).
enum HealthKitWellnessService {
    private static let store = HKHealthStore()

    /// Request sleep read access (no-op if already determined). Returns false if HealthKit unavailable.
    @discardableResult
    static func ensureSleepReadAccess() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
            return true
        } catch {
            return false
        }
    }

    /// Request heart-rate read access. Does not block the rest of the app if denied.
    @discardableResult
    static func ensureHeartRateReadAccess() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [hrType])
            return true
        } catch {
            return false
        }
    }

    /// Heart-rate samples in `[start, end)` local range. Values in bpm.
    static func fetchHeartRateSamples(start: Date, end: Date) async -> [(date: Date, bpm: Double)] {
        guard await ensureHeartRateReadAccess() else { return [] }
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate])
        let unit = HKUnit.count().unitDivided(by: .minute())

        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(
                sampleType: hrType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                guard let samples = samples as? [HKQuantitySample] else {
                    cont.resume(returning: [])
                    return
                }
                let mapped: [(Date, Double)] = samples.compactMap { sample in
                    let bpm = sample.quantity.doubleValue(for: unit)
                    guard bpm >= 30, bpm <= 250 else { return nil }
                    return (sample.startDate, bpm)
                }
                cont.resume(returning: mapped)
            }
            store.execute(query)
        }
    }

    /// Sum of asleep samples for “last night”: previous day 18:00 → today 14:00 local.
    static func fetchRecentSleepMinutes(now: Date = Date()) async -> Int? {
        guard await ensureSleepReadAccess() else { return nil }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: now)
        // Yesterday 18:00 → today 14:00 covers a typical night even if the user opens the app late.
        let start = cal.date(byAdding: .hour, value: -6, to: dayStart) // previous day 18:00
            ?? now.addingTimeInterval(-30 * 3600)
        let end = cal.date(byAdding: .hour, value: 14, to: dayStart) ?? now

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])

        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    cont.resume(returning: nil)
                    return
                }
                var total: TimeInterval = 0
                for sample in samples where Self.isAsleep(sample) {
                    total += sample.endDate.timeIntervalSince(sample.startDate)
                }
                let minutes = Int((total / 60.0).rounded())
                cont.resume(returning: minutes > 0 ? min(minutes, 24 * 60) : nil)
            }
            store.execute(query)
        }
    }

    private static func isAsleep(_ sample: HKCategorySample) -> Bool {
        let value = sample.value
        if value == HKCategoryValueSleepAnalysis.asleep.rawValue { return true }
        if #available(iOS 16.0, *) {
            switch value {
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                 HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                 HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                return true
            default:
                return false
            }
        }
        return false
    }
}
