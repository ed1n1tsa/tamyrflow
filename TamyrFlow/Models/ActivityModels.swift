import Foundation

enum ActivityCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case workouts
    case walkRun = "walk_run"
    case adaptive
    case sport
    case everyday

    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .workouts: return "ActCatWorkouts"
        case .walkRun: return "ActCatWalkRun"
        case .adaptive: return "ActCatAdaptive"
        case .sport: return "ActCatSport"
        case .everyday: return "ActCatEveryday"
        }
    }
}

enum ActivityTypeKey: String, Codable, CaseIterable, Identifiable, Hashable {
    case strength
    case cardio
    case run
    case bike
    case swim
    case yoga
    case other

    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .strength: return "ActTypeStrength"
        case .cardio: return "ActTypeCardio"
        case .run: return "ActTypeRun"
        case .bike: return "ActTypeBike"
        case .swim: return "ActTypeSwim"
        case .yoga: return "ActTypeYoga"
        case .other: return "ActTypeOther"
        }
    }

    var filterGroup: String {
        switch self {
        case .strength: return "strength"
        case .cardio, .run, .bike, .swim: return "cardio"
        case .yoga: return "sport"
        case .other: return "all"
        }
    }
}

enum ActivityIntensity: String, Codable, CaseIterable, Identifiable, Hashable {
    case light
    case medium
    case high

    var id: String { rawValue }
}

struct ActivityEntry: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var userId: UUID
    var category: ActivityCategory
    var activityType: String
    var title: String
    var durationMin: Int
    var startedAt: Date
    var intensity: ActivityIntensity
    var notes: String
    var distanceKm: Double?
    var caloriesEst: Double?
    var source: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case activityType = "activity_type"
        case title
        case durationMin = "duration_min"
        case startedAt = "started_at"
        case intensity
        case notes
        case distanceKm = "distance_km"
        case caloriesEst = "calories_est"
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var typeKey: ActivityTypeKey {
        ActivityTypeKey(rawValue: activityType) ?? .other
    }
}

struct ActivityDraft: Equatable {
    var category: ActivityCategory = .workouts
    var type: ActivityTypeKey = .strength
    var durationMin: Int = 45
    var startedAt: Date = Date()
    var intensity: ActivityIntensity = .medium
    var notes: String = ""
}

struct AchievementDef: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var kind: String
    var threshold: Double
    var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, kind, threshold
        case sortOrder = "sort_order"
    }
}

struct UserAchievement: Codable, Equatable, Hashable {
    var userId: UUID
    var achievementId: String
    var unlockedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case achievementId = "achievement_id"
        case unlockedAt = "unlocked_at"
    }
}

struct DayMetricSnapshot: Equatable {
    var steps: Double = 0
    var stepsTarget: Double = 10_000
    var calories: Double = 0
    var caloriesTarget: Double = 300
    var sleepHours: Double = 0
    var sleepTarget: Double = 8
    var waterLiters: Double = 0
    var waterTarget: Double = 2
    var weightKg: Double = 0
    var weightTarget: Double = 65
}

struct HourlyBar: Identifiable, Equatable {
    var id: Int { hour }
    var hour: Int
    var value: Double
}
