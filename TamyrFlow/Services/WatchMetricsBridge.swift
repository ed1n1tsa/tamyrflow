import Foundation
import Supabase

/// Persists Veepoo steps/sleep into Supabase for Activity + Goals (source = device).
@MainActor
enum WatchMetricsBridge {
    /// Upsert today’s device steps (count) and sleep (minutes) into `measurements`,
    /// and refresh matching active `goal_progress` rows (steps / sleep hours).
    static func persistStepsAndSleep(
        auth: AuthService,
        steps: Int?,
        sleepMinutes: Int?,
        day: Date = Date()
    ) async {
        guard let userId = auth.session?.user.id else { return }
        guard (steps ?? 0) > 0 || (sleepMinutes ?? 0) > 0 else { return }

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: day)
        // Stable timestamp inside the local day so re-sync updates the same logical row.
        let recordedAt = cal.date(byAdding: .hour, value: 12, to: dayStart) ?? dayStart
        let dayKey = GoalPeriodMath.dateOnlyString(dayStart)

        if let steps, steps > 0 {
            await upsertDayMeasurement(
                auth: auth,
                userId: userId,
                metric: "steps",
                value: Double(steps),
                unit: "steps",
                recordedAt: recordedAt,
                dayStart: dayStart,
                dayKey: dayKey
            )
            await setGoalProgressAbsolute(
                auth: auth,
                userId: userId,
                category: .steps,
                value: Double(steps),
                day: dayStart
            )
        }

        if let sleepMinutes, sleepMinutes > 0 {
            await upsertDayMeasurement(
                auth: auth,
                userId: userId,
                metric: "sleep",
                value: Double(sleepMinutes),
                unit: "minutes",
                recordedAt: recordedAt,
                dayStart: dayStart,
                dayKey: dayKey
            )
            let hours = Double(sleepMinutes) / 60.0
            await setGoalProgressAbsolute(
                auth: auth,
                userId: userId,
                category: .sleep,
                value: hours,
                day: dayStart
            )
        }
    }

    // MARK: - measurements

    private static func upsertDayMeasurement(
        auth: AuthService,
        userId: UUID,
        metric: String,
        value: Double,
        unit: String,
        recordedAt: Date,
        dayStart: Date,
        dayKey: String
    ) async {
        let cal = Calendar.current
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86_400)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        struct Existing: Decodable {
            let id: UUID
            let value: Double
        }

        if let response: PostgrestResponse<[Existing]> = try? await auth.client
            .from("measurements")
            .select("id,value")
            .eq("user_id", value: userId.uuidString)
            .eq("metric", value: metric)
            .eq("source", value: "device")
            .gte("recorded_at", value: iso.string(from: dayStart))
            .lt("recorded_at", value: iso.string(from: dayEnd))
            .order("recorded_at", ascending: false)
            .limit(1)
            .execute(),
           let row = response.value.first {
            // Keep the higher device reading for the day (band totals only grow during the day).
            let next = max(row.value, value)
            struct Patch: Encodable {
                let value: Double
                let unit: String
                let recorded_at: String
                let meta: [String: String]
            }
            try? await auth.client
                .from("measurements")
                .update(
                    Patch(
                        value: next,
                        unit: unit,
                        recorded_at: iso.string(from: recordedAt),
                        meta: ["bridge": "veepoo", "day": dayKey]
                    )
                )
                .eq("id", value: row.id.uuidString)
                .execute()
            return
        }

        struct Insert: Encodable {
            let user_id: String
            let metric: String
            let value: Double
            let unit: String
            let recorded_at: String
            let source: String
            let meta: [String: String]
        }
        try? await auth.client
            .from("measurements")
            .insert(
                Insert(
                    user_id: userId.uuidString,
                    metric: metric,
                    value: value,
                    unit: unit,
                    recorded_at: iso.string(from: recordedAt),
                    source: "device",
                    meta: ["bridge": "veepoo", "day": dayKey]
                )
            )
            .execute()
    }

    // MARK: - goal_progress

    private static func setGoalProgressAbsolute(
        auth: AuthService,
        userId: UUID,
        category: GoalCategory,
        value: Double,
        day: Date
    ) async {
        guard value > 0 else { return }

        struct GoalRow: Decodable {
            let id: UUID
            let period: GoalPeriod
        }

        guard let goals: PostgrestResponse<[GoalRow]> = try? await auth.client
            .from("goals")
            .select("id,period")
            .eq("user_id", value: userId.uuidString)
            .eq("category", value: category.rawValue)
            .eq("is_active", value: true)
            .limit(1)
            .execute(),
              let goal = goals.value.first
        else { return }

        let periodStart = GoalPeriodMath.periodStart(for: goal.period, now: day)
        let startStr = GoalPeriodMath.dateOnlyString(periodStart)

        struct ProgressRow: Decodable {
            let id: UUID
            let current_value: Double
        }

        if let response: PostgrestResponse<[ProgressRow]> = try? await auth.client
            .from("goal_progress")
            .select("id,current_value")
            .eq("goal_id", value: goal.id.uuidString)
            .eq("period_start", value: startStr)
            .limit(1)
            .execute(),
           let existing = response.value.first {
            let next = max(existing.current_value, value)
            struct Patch: Encodable {
                let current_value: Double
                let source: String
            }
            try? await auth.client
                .from("goal_progress")
                .update(Patch(current_value: next, source: "device"))
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
                        user_id: userId.uuidString,
                        period_start: startStr,
                        current_value: value,
                        source: "device"
                    )
                )
                .execute()
        }
    }
}
