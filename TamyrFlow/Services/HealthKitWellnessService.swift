import Foundation
import HealthKit

/// Read-only HealthKit helpers for wellness metrics (sleep first; SpO₂/temp later).
enum HealthKitWellnessService {
    /// Sum of asleep samples over the last ~36h ending around local noon (covers “last night”).
    static func fetchRecentSleepMinutes(now: Date = Date()) async -> Int? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let store = HKHealthStore()
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: now)
        let end = cal.date(byAdding: .hour, value: 12, to: dayStart) ?? now
        let start = cal.date(byAdding: .hour, value: -36, to: end) ?? now.addingTimeInterval(-36 * 3600)

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
        // Legacy
        if value == HKCategoryValueSleepAnalysis.asleep.rawValue { return true }
        // iOS 16+ stages
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
