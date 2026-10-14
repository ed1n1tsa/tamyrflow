import Foundation
import HealthKit

/// Read-only HealthKit helpers for wellness metrics (sleep first; SpO₂/temp later).
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
