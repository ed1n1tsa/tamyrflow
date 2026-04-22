import Foundation
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var session: Session? = nil
    @Published var loading: Bool = false
    @Published var errorText: String? = nil

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""

    @Published var username: String = ""
    @Published var profileUsername: String? = nil

    private var auth: AuthClient { SupabaseManager.client.auth }
    private var db: SupabaseClient { SupabaseManager.client }

    init() {
        Task { await restoreSession() }
    }

    func restoreSession() async {
        do {
            session = try await auth.session
            if let session { await loadProfile(session: session) }
        } catch {
            session = nil
            profileUsername = nil
        }
    }

    func signIn() async {
        errorText = nil
        loading = true
        defer { loading = false }

        guard !email.isEmpty, !password.isEmpty else {
            errorText = "Заполни email и пароль"
            return
        }

        do {
            let s = try await auth.signIn(email: email, password: password)
            session = s
            await loadProfile(session: s)
            confirmPassword = ""
            username = ""
        } catch {
            errorText = "Неверный email или пароль"
        }
    }

    func signUp() async {
        errorText = nil
        loading = true
        defer { loading = false }

        guard !email.isEmpty, !password.isEmpty else {
            errorText = "Заполни email и пароль"
            return
        }
        guard password.count >= 6 else {
            errorText = "Пароль минимум 6 символов"
            return
        }
        guard confirmPassword == password else {
            errorText = "Пароли не совпадают"
            return
        }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUsername.isEmpty else {
            errorText = "Введи username"
            return
        }

        do {
            _ = try await auth.signUp(email: email, password: password)

            do {
                let s = try await auth.signIn(email: email, password: password)
                session = s
                try await createProfile(session: s, username: cleanUsername)
                await loadProfile(session: s)
                confirmPassword = ""
            } catch {
                errorText = "Аккаунт создан. Подтверди email и войди."
            }
        } catch {
            errorText = "Не получилось зарегистрироваться"
        }
    }

    private func createProfile(session: Session, username: String) async throws {
        let payload = ProfileInsert(id: session.user.id, username: username)

        _ = try await db
            .from("profiles")
            .insert(payload)
            .execute()
    }

    func loadProfile(session: Session) async {
        do {
            let rows: [ProfileRowModel] = try await db
                .from("profiles")
                .select("id,username,created_at")
                .eq("id", value: session.user.id.uuidString)
                .limit(1)
                .execute()
                .value

            profileUsername = rows.first?.username
        } catch {
            profileUsername = nil
        }
    }

    func signOut() async {
        errorText = nil
        loading = true
        defer { loading = false }

        do {
            try await auth.signOut()
            session = nil
            profileUsername = nil

            email = ""
            password = ""
            confirmPassword = ""
            username = ""
        } catch {
            errorText = "Не получилось выйти"
        }
    }

    // ✅ Удаление аккаунта (Edge Function delete-account должна быть задеплоена)
    func deleteAccount() async {
        errorText = nil
        loading = true
        defer { loading = false }

        do {
            // Берём самую свежую сессию и токен
            let s = try await auth.session

            // В разных версиях SDK поле может называться по-разному.
            // Если у тебя compile ругнётся — скажи, я подстрою под твою версию.
            let token = s.accessToken

            try await db.functions.invoke(
                "delete-account",
                options: FunctionInvokeOptions(
                    headers: [
                        "Authorization": "Bearer \(token)",
                        "Content-Type": "application/json"
                    ]
                )
            )

            // Успех
            self.session = nil
            self.profileUsername = nil
            self.email = ""
            self.password = ""
            self.confirmPassword = ""
            self.username = ""

        } catch {
            errorText = "Не получилось удалить аккаунт: \(error.localizedDescription)"
        }
    }



}
