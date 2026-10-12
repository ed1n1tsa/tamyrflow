import Combine
import Foundation
import Supabase

@MainActor
final class AuthService: ObservableObject {
    let client: SupabaseClient

    @Published private(set) var isBusy = false
    @Published var lastError: String?

    init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    /// Returns `true` if a session exists immediately; `false` if email confirmation is required.
    @discardableResult
    func signUp(email: String, password: String, locale: String) async throws -> Bool {
        isBusy = true
        lastError = nil
        defer { isBusy = false }

        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "locale": .string(locale),
                "display_name": .string(email.split(separator: "@").first.map(String.init) ?? email)
            ]
        )

        // `profiles` row is created by DB trigger `on_auth_user_created`.
        if let session = response.session {
            try? await client.from("profiles")
                .update(["locale": locale])
                .eq("id", value: session.user.id.uuidString)
                .execute()
            return true
        }
        return false
    }

    func signIn(email: String, password: String) async throws {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        _ = try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async {
        try? await client.auth.signOut()
    }
}
