import Foundation

struct ProfileRowModel: Codable {
    let id: UUID
    let username: String
    let created_at: Date
}

struct ProfileInsert: Codable {
    let id: UUID
    let username: String
}

