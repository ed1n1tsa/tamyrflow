import Foundation
import Supabase

@MainActor
final class HealthDataService {

    static let shared = HealthDataService()
    private init() {}

    private var db: SupabaseClient {
        SupabaseManager.client
    }

    func insertMeasurement(
        session: Session,
        username: String,
        watchId: String,
        x: Double? = nil,
        y: Double? = nil,
        pulse: Int? = nil,
        bloodPressure: String? = nil,
        ecgData: String? = nil
    ) async throws {

        let payload = WatchHealthInsert(
            user_id: session.user.id,
            username: username,
            watch_id: watchId,
            x_location: x,
            y_location: y,
            pulse: pulse,
            blood_pressure: bloodPressure
        )

        try await db
            .from("watch_health_data")
            .insert(payload)
            .execute()
    }
}
