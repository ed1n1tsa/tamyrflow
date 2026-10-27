import Foundation
import HealthKit

/// HealthKit helpers for wellness metrics (sleep, heart rate; SpO₂/temp later).
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

    /// Request heart-rate read (+ optional write) access. Does not block the rest of the app if denied.
    @discardableResult
    static func ensureHeartRateReadAccess(alsoWrite: Bool = false) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return false }
        do {
            let share: Set<HKSampleType> = alsoWrite ? [hrType] : []
            try await store.requestAuthorization(toShare: share, read: [hrType])
            return true
        } catch {
            return false
        }
    }

    /// Persist a user-initiated HR reading into Apple Health (App Store–friendly path).
    @discardableResult
    static func saveHeartRateSample(bpm: Double, at date: Date = Date()) async -> Bool {
        guard bpm >= 30, bpm <= 250 else { return false }
        guard await ensureHeartRateReadAccess(alsoWrite: true) else { return false }
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return false }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let quantity = HKQuantity(unit: unit, doubleValue: bpm)
        let sample = HKQuantitySample(type: hrType, quantity: quantity, start: date, end: date)
        do {
            try await store.save(sample)
            return true
        } catch {
            print("[PulseSync] HealthKit save failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Heart-rate samples in `[start, end)` local range. Values in bpm.
    /// Hard-capped so Pulse sync overlay cannot hang on Health authorization/query.
    static func fetchHeartRateSamples(start: Date, end: Date, timeoutSeconds: Double = 8) async -> [(date: Date, bpm: Double)] {
        await withTaskGroup(of: [(date: Date, bpm: Double)].self) { group in
            group.addTask {
                await Self.fetchHeartRateSamplesUnbounded(start: start, end: end)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                return []
            }
            let first = await group.next() ?? []
            group.cancelAll()
            return first
        }
    }

    private static func fetchHeartRateSamplesUnbounded(start: Date, end: Date) async -> [(date: Date, bpm: Double)] {
        guard await ensureHeartRateReadAccess() else { return [] }
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate])
        let unit = HKUnit.count().unitDivided(by: .minute())

        return await withCheckedContinuation { cont in
            var resumed = false
            let finish: ([(Date, Double)]) -> Void = { value in
                guard !resumed else { return }
                resumed = true
                cont.resume(returning: value)
            }
            let query = HKSampleQuery(
                sampleType: hrType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                guard let samples = samples as? [HKQuantitySample] else {
                    finish([])
                    return
                }
                let mapped: [(Date, Double)] = samples.compactMap { sample in
                    let bpm = sample.quantity.doubleValue(for: unit)
                    guard bpm >= 30, bpm <= 250 else { return nil }
                    return (sample.startDate, bpm)
                }
                finish(mapped)
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
