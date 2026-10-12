import Foundation

enum GoalCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case steps
    case activity
    case sleep
    case water
    case weight

    var id: String { rawValue }

    var defaultUnit: String {
        switch self {
        case .steps: return "steps"
        case .activity: return "kcal"
        case .sleep: return "hours"
        case .water: return "liters"
        case .weight: return "kg"
        }
    }

    var defaultTarget: Double {
        switch self {
        case .steps: return 8_000
        case .activity: return 300
        case .sleep: return 8
        case .water: return 2
        case .weight: return 70
        }
    }

    var assetName: String {
        switch self {
        case .steps: return "GoalIconSteps"
        case .activity: return "GoalIconActivity"
        case .sleep: return "GoalIconSleep"
        case .water: return "GoalIconWater"
        case .weight: return "GoalIconWeight"
        }
    }

    /// Manual quick-add delta for list “+”. Nil = device-driven (no + yet).
    var quickAddAmount: Double? {
        switch self {
        case .water: return 0.25
        case .activity: return 50
        case .steps, .sleep, .weight: return nil
        }
    }

    var isDeviceBacked: Bool {
        switch self {
        case .steps, .sleep: return true
        case .activity, .water, .weight: return false
        }
    }
}

enum GoalPeriod: String, Codable, CaseIterable, Identifiable, Hashable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }
}

struct Goal: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var userId: UUID
    var category: GoalCategory
    var title: String
    var targetValue: Double
    var unit: String
    var period: GoalPeriod
    var remindersEnabled: Bool
    var reminderTime: String?
    var reminderDays: [Int]
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case title
        case targetValue = "target_value"
        case unit
        case period
        case remindersEnabled = "reminders_enabled"
        case reminderTime = "reminder_time"
        case reminderDays = "reminder_days"
        case isActive = "is_active"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct GoalProgress: Codable, Identifiable, Equatable {
    var id: UUID
    var goalId: UUID
    var userId: UUID
    /// Postgres `date` as `yyyy-MM-dd`.
    var periodStart: String
    var currentValue: Double
    var source: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case userId = "user_id"
        case periodStart = "period_start"
        case currentValue = "current_value"
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct GoalDraft: Equatable {
    var category: GoalCategory = .steps
    var targetValue: Double = GoalCategory.steps.defaultTarget
    var period: GoalPeriod = .daily
    var remindersEnabled: Bool = false
    var reminderHour: Int = 9
    var reminderMinute: Int = 0
    var reminderDays: Set<Int> = [1, 2, 3, 4, 5] // Mon–Fri

    var reminderTimeString: String {
        String(format: "%02d:%02d:00", reminderHour, reminderMinute)
    }

    mutating func applyCategoryDefaults() {
        targetValue = category.defaultTarget
    }
}

enum GoalPeriodMath {
    /// Start of the current period bucket in the user's local calendar (date-only).
    static func periodStart(for period: GoalPeriod, now: Date = Date(), calendar: Calendar = .current) -> Date {
        let day = calendar.startOfDay(for: now)
        switch period {
        case .daily:
            return day
        case .weekly:
            let weekday = calendar.component(.weekday, from: day) // 1=Sun
            // ISO week: Monday start
            let isoWeekday = weekday == 1 ? 7 : weekday - 1
            return calendar.date(byAdding: .day, value: -(isoWeekday - 1), to: day) ?? day
        case .monthly:
            let comps = calendar.dateComponents([.year, .month], from: day)
            return calendar.date(from: comps) ?? day
        }
    }

    static func dateOnlyString(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
