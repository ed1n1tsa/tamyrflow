import Combine
import Foundation
import Supabase

@MainActor
final class GoalsService: ObservableObject {
    @Published private(set) var goals: [Goal] = []
    @Published private(set) var progressByGoalId: [UUID: GoalProgress] = [:]
    @Published private(set) var isLoading = false
    @Published var lastError: String?

    private let auth: AuthService

    init(auth: AuthService) {
        self.auth = auth
    }

    var completedCount: Int {
        goals.filter { progressRatio(for: $0) >= 1 }.count
    }

    func progressRatio(for goal: Goal) -> Double {
        let current = progressByGoalId[goal.id]?.currentValue ?? 0
        guard goal.targetValue > 0 else { return 0 }
        return min(1, max(0, current / goal.targetValue))
    }

    func currentValue(for goal: Goal) -> Double {
        progressByGoalId[goal.id]?.currentValue ?? 0
    }

    func hasCategory(_ category: GoalCategory) -> Bool {
        goals.contains { $0.category == category && $0.isActive }
    }

    // MARK: - Load

    func refresh() async {
        guard let uid = auth.session?.user.id else {
            goals = []
            progressByGoalId = [:]
            return
        }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let response: PostgrestResponse<[Goal]> = try await auth.client
                .from("goals")
                .select()
                .eq("user_id", value: uid.uuidString)
                .eq("is_active", value: true)
                .order("sort_order", ascending: true)
                .execute()
            goals = response.value

            var map: [UUID: GoalProgress] = [:]
            for goal in goals {
                if let row = try await fetchOrCreateProgress(for: goal, userId: uid) {
                    map[goal.id] = row
                }
            }
            progressByGoalId = map
            await rescheduleNotifications()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Create / Update / Delete

    func create(from draft: GoalDraft) async throws {
        guard let uid = auth.session?.user.id else {
            throw AuthServiceError.notAuthenticated
        }
        if hasCategory(draft.category) {
            throw GoalsServiceError.categoryTaken
        }

        struct Insert: Encodable {
            let user_id: String
            let category: String
            let title: String
            let target_value: Double
            let unit: String
            let period: String
            let reminders_enabled: Bool
            let reminder_time: String?
            let reminder_days: [Int]
            let is_active: Bool
            let sort_order: Int
        }

        let payload = Insert(
            user_id: uid.uuidString,
            category: draft.category.rawValue,
            title: L10n.Goals.title(for: draft.category),
            target_value: draft.targetValue,
            unit: draft.category.defaultUnit,
            period: draft.period.rawValue,
            reminders_enabled: draft.remindersEnabled,
            reminder_time: draft.remindersEnabled ? draft.reminderTimeString : nil,
            reminder_days: draft.remindersEnabled ? draft.reminderDays.sorted() : [],
            is_active: true,
            sort_order: goals.count
        )

        try await auth.client.from("goals").insert(payload).execute()
        await refresh()
    }

    func update(_ goal: Goal, draft: GoalDraft) async throws {
        guard auth.session?.user.id != nil else {
            throw AuthServiceError.notAuthenticated
        }

        struct Patch: Encodable {
            let title: String
            let target_value: Double
            let unit: String
            let period: String
            let reminders_enabled: Bool
            let reminder_time: String?
            let reminder_days: [Int]
        }

        let patch = Patch(
            title: L10n.Goals.title(for: draft.category),
            target_value: draft.targetValue,
            unit: draft.category.defaultUnit,
            period: draft.period.rawValue,
            reminders_enabled: draft.remindersEnabled,
            reminder_time: draft.remindersEnabled ? draft.reminderTimeString : nil,
            reminder_days: draft.remindersEnabled ? draft.reminderDays.sorted() : []
        )

        try await auth.client
            .from("goals")
            .update(patch)
            .eq("id", value: goal.id.uuidString)
            .execute()
        await refresh()
    }

    func delete(_ goal: Goal) async throws {
        try await auth.client
            .from("goals")
            .delete()
            .eq("id", value: goal.id.uuidString)
            .execute()
        await refresh()
    }

    /// Soft-deactivate alternative if hard delete fails — kept for completeness.
    func deactivate(_ goal: Goal) async throws {
        struct Patch: Encodable { let is_active: Bool }
        try await auth.client
            .from("goals")
            .update(Patch(is_active: false))
            .eq("id", value: goal.id.uuidString)
            .execute()
        await refresh()
    }

    // MARK: - Progress

    func quickAdd(to goal: Goal) async {
        guard let delta = goal.category.quickAddAmount else { return }
        await addProgress(to: goal, amount: delta)
    }

    func addProgress(to goal: Goal, amount: Double) async {
        guard let uid = auth.session?.user.id else { return }
        lastError = nil
        do {
            let start = GoalPeriodMath.periodStart(for: goal.period)
            let startStr = GoalPeriodMath.dateOnlyString(start)
            let current = progressByGoalId[goal.id]?.currentValue ?? 0
            let next = max(0, current + amount)

            if let existing = progressByGoalId[goal.id] {
                struct Patch: Encodable {
                    let current_value: Double
                    let source: String
                }
                try await auth.client
                    .from("goal_progress")
                    .update(Patch(current_value: next, source: "manual"))
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
                try await auth.client
                    .from("goal_progress")
                    .insert(
                        Insert(
                            goal_id: goal.id.uuidString,
                            user_id: uid.uuidString,
                            period_start: startStr,
                            current_value: next,
                            source: "manual"
                        )
                    )
                    .execute()
            }
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Private

    private func fetchOrCreateProgress(for goal: Goal, userId: UUID) async throws -> GoalProgress? {
        let start = GoalPeriodMath.periodStart(for: goal.period)
        let startStr = GoalPeriodMath.dateOnlyString(start)

        let existing: PostgrestResponse<[GoalProgress]> = try await auth.client
            .from("goal_progress")
            .select()
            .eq("goal_id", value: goal.id.uuidString)
            .eq("period_start", value: startStr)
            .limit(1)
            .execute()

        if let row = existing.value.first {
            return row
        }

        struct Insert: Encodable {
            let goal_id: String
            let user_id: String
            let period_start: String
            let current_value: Double
            let source: String
        }

        let inserted: PostgrestResponse<[GoalProgress]> = try await auth.client
            .from("goal_progress")
            .insert(
                Insert(
                    goal_id: goal.id.uuidString,
                    user_id: userId.uuidString,
                    period_start: startStr,
                    current_value: 0,
                    source: "manual"
                )
            )
            .select()
            .execute()
        return inserted.value.first
    }

    private func rescheduleNotifications() async {
        await GoalNotificationService.rescheduleAll(
            goals: goals,
            completedCount: completedCount,
            totalCount: goals.count
        )
    }
}

enum GoalsServiceError: LocalizedError {
    case categoryTaken

    var errorDescription: String? {
        switch self {
        case .categoryTaken: return L10n.Goals.categoryTaken
        }
    }
}
