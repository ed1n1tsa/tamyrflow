import Foundation

// Должен существовать в проекте ТОЛЬКО ОДИН РАЗ
struct WatchHealthInsert: Encodable {
    let user_id: UUID
    let username: String
    let watch_id: String
    let x_location: Double?
    let y_location: Double?
    let pulse: Int?
    let blood_pressure: String?
}
