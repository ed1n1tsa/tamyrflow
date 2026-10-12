import Foundation

enum ProfileGender: String, Codable, CaseIterable, Identifiable {
    case male
    case female
    case unspecified

    var id: String { rawValue }
}

struct UserProfile: Codable, Equatable {
    var id: UUID
    var displayName: String?
    var email: String?
    var avatarUrl: String?
    var locale: String?
    var gender: ProfileGender?
    var age: Int?
    var heightCm: Int?
    var weightKg: Double?
    var profileCompleted: Bool
    var profileCompletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case avatarUrl = "avatar_url"
        case locale
        case gender
        case age
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case profileCompleted = "profile_completed"
        case profileCompletedAt = "profile_completed_at"
    }

    var isComplete: Bool { profileCompleted }
}

struct ProfileSetupDraft: Equatable {
    var displayName: String = ""
    var gender: ProfileGender?
    var age: Int = 20
    var heightCm: Int = 170
    var weightKg: Int = 70
}
