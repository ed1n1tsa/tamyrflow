import Combine
import Foundation
import Supabase

@MainActor
final class AuthService: ObservableObject {
    let client: SupabaseClient

    @Published private(set) var isBusy = false
    @Published private(set) var isBootstrapping = true
    @Published private(set) var session: Session?
    @Published private(set) var profile: UserProfile?
    @Published var lastError: String?

    private var authListener: Task<Void, Never>?

    var isAuthenticated: Bool { session != nil }

    var needsProfileSetup: Bool {
        guard session != nil else { return false }
        guard let profile else { return true }
        return !profile.profileCompleted
    }

    init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
        authListener = Task { [weak self] in
            await self?.observeAuth()
        }
        Task { await bootstrap() }
    }

    deinit {
        authListener?.cancel()
    }

    private func bootstrap() async {
        isBootstrapping = true
        defer { isBootstrapping = false }
        do {
            session = try await client.auth.session
            await refreshProfile()
        } catch {
            session = nil
            profile = nil
        }
    }

    private func observeAuth() async {
        for await change in client.auth.authStateChanges {
            guard !Task.isCancelled else { return }
            switch change.event {
            case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                self.session = change.session
                if change.session != nil {
                    await refreshProfile()
                } else {
                    self.profile = nil
                }
            case .signedOut:
                self.session = nil
                self.profile = nil
            default:
                break
            }
        }
    }

    // MARK: - Auth

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

        if let session = response.session {
            self.session = session
            try? await client.from("profiles")
                .update(["locale": locale])
                .eq("id", value: session.user.id.uuidString)
                .execute()
            await refreshProfile()
            return true
        }
        return false
    }

    func signIn(email: String, password: String) async throws {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        let session = try await client.auth.signIn(email: email, password: password)
        self.session = session
        await refreshProfile()
    }

    func sendPasswordRecovery(email: String) async throws {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        try await client.auth.resetPasswordForEmail(email)
    }

    func verifyRecoveryOTP(email: String, token: String) async throws {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        let response = try await client.auth.verifyOTP(
            email: email,
            token: token,
            type: .recovery
        )
        if let session = response.session {
            self.session = session
        }
    }

    func updatePassword(_ password: String) async throws {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        _ = try await client.auth.update(user: UserAttributes(password: password))
    }

    func signOut() async {
        try? await client.auth.signOut()
        session = nil
        profile = nil
    }

    /// Deletes own data + auth user via security-definer RPC.
    func deleteAccount() async throws {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        try await client.rpc("delete_own_account").execute()
        session = nil
        profile = nil
        try? await client.auth.signOut()
    }

    // MARK: - Profile

    func refreshProfile() async {
        guard let uid = session?.user.id else {
            profile = nil
            return
        }
        do {
            let response: PostgrestResponse<UserProfile> = try await client.from("profiles")
                .select()
                .eq("id", value: uid.uuidString)
                .single()
                .execute()
            profile = response.value
        } catch {
            // Columns may not be migrated yet — keep nil so setup can still prompt.
            profile = nil
            lastError = error.localizedDescription
        }
    }

    func completeProfileSetup(_ draft: ProfileSetupDraft, locale: String) async throws {
        guard let uid = session?.user.id else {
            throw AuthServiceError.notAuthenticated
        }
        isBusy = true
        lastError = nil
        defer { isBusy = false }

        struct Payload: Encodable {
            let display_name: String
            let gender: String
            let age: Int
            let height_cm: Int
            let weight_kg: Double
            let locale: String
            let profile_completed: Bool
            let profile_completed_at: String
        }

        let gender = draft.gender ?? .unspecified
        let payload = Payload(
            display_name: draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: gender.rawValue,
            age: draft.age,
            height_cm: draft.heightCm,
            weight_kg: Double(draft.weightKg),
            locale: locale,
            profile_completed: true,
            profile_completed_at: ISO8601DateFormatter().string(from: Date())
        )

        try await client.from("profiles")
            .update(payload)
            .eq("id", value: uid.uuidString)
            .execute()

        await refreshProfile()
    }
}

enum AuthServiceError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated"
        }
    }
}
