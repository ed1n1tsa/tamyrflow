import Combine
import Foundation
import Supabase

@MainActor
final class ActivityService: ObservableObject {
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @Published private(set) var entries: [ActivityEntry] = []
    @Published private(set) var dayEntries: [ActivityEntry] = []
    @Published private(set) var metrics = DayMetricSnapshot()
    @Published private(set) var hourly: [HourlyBar] = (0..<24).map { HourlyBar(hour: $0, value: 0) }
    @Published private(set) var achievementDefs: [AchievementDef] = []
    @Published private(set) var unlockedIds: Set<String> = []
    @Published private(set) var activeGoals: [Goal] = []
    @Published private(set) var isLoading = false
    @Published var lastError: String?

    private let auth: AuthService

    init(auth: AuthService) {
        self.auth = auth
    }

    var isEmptyDay: Bool {
        dayEntries.isEmpty
            && metrics.steps <= 0
            && metrics.calories <= 0
            && metrics.waterLiters <= 0
            && metrics.sleepHours <= 0
    }

    // MARK: - Load

    func refresh() async {
        guard let uid = auth.session?.user.id else {
            clear()
            return
        }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            try await loadEntries(userId: uid)
            try await loadGoals(userId: uid)
            await loadDayMetrics(userId: uid)
            rebuildHourly()
            try await loadAchievements(userId: uid)
            await evaluateAchievements(userId: uid)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func selectDate(_ date: Date) async {
        selectedDate = Calendar.current.startOfDay(for: date)
        filterDayEntries()
        await loadDayMetrics(userId: auth.session?.user.id)
        rebuildHourly()
    }

    // MARK: - Create

    func create(from draft: ActivityDraft) async throws {
        guard let uid = auth.session?.user.id else {
            throw AuthServiceError.notAuthenticated
        }

        struct Insert: Encodable {
            let user_id: String
            let category: String
            let activity_type: String
            let title: String
            let duration_min: Int
            let started_at: String
            let intensity: String
            let notes: String
            let source: String
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let payload = Insert(
            user_id: uid.uuidString,
            category: draft.category.rawValue,
            activity_type: draft.type.rawValue,
            title: L10n.Activity.typeTitle(draft.type),
            duration_min: draft.durationMin,
            started_at: formatter.string(from: draft.startedAt),
            intensity: draft.intensity.rawValue,
            notes: String(draft.notes.prefix(200)),
            source: "manual"
        )

        try await auth.client.from("activity_entries").insert(payload).execute()

        // Rough kcal estimate feeds daily calories metric + goals progress.
        let kcal = estimatedCalories(durationMin: draft.durationMin, intensity: draft.intensity)
        if kcal > 0 {
            await bumpMetric(userId: uid, metric: "calories", unit: "kcal", delta: kcal)
            await bumpGoalProgress(category: .activity, delta: kcal)
        }

        await refresh()
    }

    func deleteEntry(_ entry: ActivityEntry) async {
        do {
            try await auth.client
                .from("activity_entries")
                .delete()
                .eq("id", value: entry.id.uuidString)
                .execute()
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Manual metric quick adds (water / kcal)

    func addWater(liters: Double = 0.25) async {
        guard let uid = auth.session?.user.id else { return }
        await bumpMetric(userId: uid, metric: "water", unit: "liters", delta: liters)
        await bumpGoalProgress(category: .water, delta: liters)
        await refresh()
    }

    func addCalories(_ kcal: Double = 50) async {
        guard let uid = auth.session?.user.id else { return }
        await bumpMetric(userId: uid, metric: "calories", unit: "kcal", delta: kcal)
        await bumpGoalProgress(category: .activity, delta: kcal)
        await refresh()
    }

    // MARK: - Private loaders

    private func clear() {
        entries = []
        dayEntries = []
        metrics = DayMetricSnapshot()
        hourly = (0..<24).map { HourlyBar(hour: $0, value: 0) }
        unlockedIds = []
        activeGoals = []
    }

    private func loadEntries(userId: UUID) async throws {
        let response: PostgrestResponse<[ActivityEntry]> = try await auth.client
            .from("activity_entries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("started_at", ascending: false)
            .limit(200)
            .execute()
        entries = response.value
        filterDayEntries()
    }

    private func filterDayEntries() {
        let cal = Calendar.current
        dayEntries = entries.filter { cal.isDate($0.startedAt, inSameDayAs: selectedDate) }
    }

    private func loadGoals(userId: UUID) async throws {
        let response: PostgrestResponse<[Goal]> = try await auth.client
            .from("goals")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_active", value: true)
            .order("sort_order", ascending: true)
            .execute()
        activeGoals = response.value

        for goal in activeGoals {
            switch goal.category {
            case .steps: metrics.stepsTarget = goal.targetValue
            case .activity: metrics.caloriesTarget = goal.targetValue
            case .sleep: metrics.sleepTarget = goal.targetValue
            case .water: metrics.waterTarget = goal.targetValue
            case .weight: metrics.weightTarget = goal.targetValue
            }
        }
    }

    private func loadDayMetrics(userId: UUID?) async {
        guard let userId else { return }
        let cal = Calendar.current
        let start = cal.startOfDay(for: selectedDate)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        // Reset dynamic values but keep targets from goals.
        let targets = metrics
        metrics = DayMetricSnapshot(
            stepsTarget: targets.stepsTarget,
            caloriesTarget: targets.caloriesTarget,
            sleepTarget: targets.sleepTarget,
            waterTarget: targets.waterTarget,
            weightTarget: targets.weightTarget
        )

        // Goal progress for the period covering selected day.
        for goal in activeGoals {
            let periodStart = GoalPeriodMath.periodStart(for: goal.period, now: selectedDate)
            let startStr = GoalPeriodMath.dateOnlyString(periodStart)
            if let response: PostgrestResponse<[GoalProgress]> = try? await auth.client
                .from("goal_progress")
                .select()
                .eq("goal_id", value: goal.id.uuidString)
                .eq("period_start", value: startStr)
                .limit(1)
                .execute(),
               let row = response.value.first {
                switch goal.category {
                case .steps: metrics.steps = max(metrics.steps, row.currentValue)
                case .activity: metrics.calories = max(metrics.calories, row.currentValue)
                case .sleep: metrics.sleepHours = max(metrics.sleepHours, row.currentValue)
                case .water: metrics.waterLiters = max(metrics.waterLiters, row.currentValue)
                case .weight: metrics.weightKg = row.currentValue > 0 ? row.currentValue : metrics.weightKg
                }
            }
        }

        // Measurements for the day (device/manual).
        struct MeasurementRow: Decodable {
            let metric: String
            let value: Double
        }

        if let response: PostgrestResponse<[MeasurementRow]> = try? await auth.client
            .from("measurements")
            .select("metric,value")
            .eq("user_id", value: userId.uuidString)
            .gte("recorded_at", value: iso.string(from: start))
            .lt("recorded_at", value: iso.string(from: end))
            .execute() {
            var steps: Double = 0
            var sleepMin: Double = 0
            var water: Double = 0
            var kcal: Double = 0
            var weight: Double = 0
            for r in response.value {
                switch r.metric {
                case "steps": steps += r.value
                case "sleep": sleepMin += r.value
                case "water": water += r.value
                case "calories": kcal += r.value
                case "weight": weight = r.value
                default: break
                }
            }
            if steps > 0 { metrics.steps = max(metrics.steps, steps) }
            if sleepMin > 0 { metrics.sleepHours = max(metrics.sleepHours, sleepMin / 60) }
            if water > 0 { metrics.waterLiters = max(metrics.waterLiters, water) }
            if kcal > 0 { metrics.calories = max(metrics.calories, kcal) }
            if weight > 0 { metrics.weightKg = weight }
        }

        // Profile weight fallback.
        if metrics.weightKg <= 0, let w = auth.profile?.weightKg {
            metrics.weightKg = w
        }

        // Workout-derived calories for the day if no metric yet.
        if metrics.calories <= 0 {
            let fromWorkouts = dayEntries.reduce(0.0) {
                $0 + estimatedCalories(durationMin: $1.durationMin, intensity: $1.intensity)
            }
            metrics.calories = fromWorkouts
        }
    }

    private func rebuildHourly() {
        var buckets = Array(repeating: 0.0, count: 24)
        let cal = Calendar.current
        for e in dayEntries {
            let h = cal.component(.hour, from: e.startedAt)
            buckets[h] += Double(e.durationMin)
        }
        // Soft steps distribution placeholder when only steps exist.
        if dayEntries.isEmpty, metrics.steps > 0 {
            let per = metrics.steps / 12
            for h in 8..<20 { buckets[h] = per }
        }
        hourly = buckets.enumerated().map { HourlyBar(hour: $0.offset, value: $0.element) }
    }

    private func loadAchievements(userId: UUID) async throws {
        let defs: PostgrestResponse<[AchievementDef]> = try await auth.client
            .from("achievement_defs")
            .select()
            .order("sort_order", ascending: true)
            .execute()
        achievementDefs = defs.value

        struct Row: Decodable { let achievement_id: String }
        let unlocked: PostgrestResponse<[Row]> = try await auth.client
            .from("user_achievements")
            .select("achievement_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
        unlockedIds = Set(unlocked.value.map(\.achievement_id))
    }

    private func evaluateAchievements(userId: UUID) async {
        var newly: [String] = []
        for def in achievementDefs {
            if unlockedIds.contains(def.id) { continue }
            let ok: Bool
            switch def.kind {
            case "steps": ok = metrics.steps >= def.threshold
            case "calories": ok = metrics.calories >= def.threshold
            case "water": ok = metrics.waterLiters >= def.threshold
            case "sleep": ok = metrics.sleepHours >= def.threshold
            case "weight":
                ok = metrics.weightTarget > 0
                    && metrics.weightKg > 0
                    && abs(metrics.weightKg - metrics.weightTarget) <= 1
            case "workout": ok = !dayEntries.isEmpty || entries.count >= Int(def.threshold)
            default: ok = false
            }
            if ok { newly.append(def.id) }
        }
        for id in newly {
            struct Insert: Encodable {
                let user_id: String
                let achievement_id: String
            }
            try? await auth.client
                .from("user_achievements")
                .insert(Insert(user_id: userId.uuidString, achievement_id: id))
                .execute()
            unlockedIds.insert(id)
        }
    }

    private func bumpMetric(userId: UUID, metric: String, unit: String, delta: Double) async {
        let cal = Calendar.current
        let start = cal.startOfDay(for: selectedDate)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        struct Insert: Encodable {
            let user_id: String
            let metric: String
            let value: Double
            let unit: String
            let recorded_at: String
            let source: String
        }
        try? await auth.client
            .from("measurements")
            .insert(
                Insert(
                    user_id: userId.uuidString,
                    metric: metric,
                    value: delta,
                    unit: unit,
                    recorded_at: iso.string(from: Date()),
                    source: "manual"
                )
            )
            .execute()
        _ = start
    }

    private func bumpGoalProgress(category: GoalCategory, delta: Double) async {
        guard let goal = activeGoals.first(where: { $0.category == category }),
              let uid = auth.session?.user.id else { return }
        let periodStart = GoalPeriodMath.periodStart(for: goal.period, now: selectedDate)
        let startStr = GoalPeriodMath.dateOnlyString(periodStart)

        struct Row: Decodable {
            let id: UUID
            let current_value: Double
        }

        if let response: PostgrestResponse<[Row]> = try? await auth.client
            .from("goal_progress")
            .select("id,current_value")
            .eq("goal_id", value: goal.id.uuidString)
            .eq("period_start", value: startStr)
            .limit(1)
            .execute(),
           let existing = response.value.first {
            struct Patch: Encodable {
                let current_value: Double
                let source: String
            }
            try? await auth.client
                .from("goal_progress")
                .update(Patch(current_value: existing.current_value + delta, source: "manual"))
                .eq("id", value: existing.id.uuidString)
                .execute()
        } else {
            struct Insert: Encodable {
                let goal_id: String
                let user_id: String
                let period_start: String
                let current_value: Double
                let source: String
            }
            try? await auth.client
                .from("goal_progress")
                .insert(
                    Insert(
                        goal_id: goal.id.uuidString,
                        user_id: uid.uuidString,
                        period_start: startStr,
                        current_value: delta,
                        source: "manual"
                    )
                )
                .execute()
        }
    }

    private func estimatedCalories(durationMin: Int, intensity: ActivityIntensity) -> Double {
        let factor: Double
        switch intensity {
        case .light: factor = 4
        case .medium: factor = 7
        case .high: factor = 10
        }
        return Double(durationMin) * factor
    }
}
