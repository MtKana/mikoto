import SwiftUI
import Foundation
import AuthenticationServices
import CryptoKit

@Observable
class AuthManager: NSObject {
    var user: User?
    var isLoading = true
    var isSigningIn = false
    var showError = false
    var errorMessage = ""
    var showInfo = false
    var infoMessage = ""
    var pendingVerificationEmail: String?
    var pendingVerificationPassword: String?
    var pendingVerificationName: String?
    var isVerifyingOtp = false

    private let supabaseURL: String = {
        let configured = Config.EXPO_PUBLIC_SUPABASE_URL
        return configured.isEmpty ? "https://nmunmpgljrtljithkjic.supabase.co" : configured
    }()
    private let supabaseAnonKey: String = {
        let configured = Config.EXPO_PUBLIC_SUPABASE_ANON_KEY
        return configured.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tdW5tcGdsanJ0bGppdGhramljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczODE1NDgsImV4cCI6MjA5Mjk1NzU0OH0.AeS7jZILVz52tGxhMLJCGB4kYCKeqDRVWCy3u3oLo-I" : configured
    }()
    private let oauthRedirect = "mikoto://auth-callback"

    private var currentNonce: String?
    private var googleSession: ASWebAuthenticationSession?

    nonisolated struct User: Codable, Sendable {
        let id: String
        let email: String
        let name: String?
        let picture: String?
    }

    override init() {
        super.init()
        Task { await checkAuth() }
    }

    @MainActor
    func checkAuth() async {
        defer { isLoading = false }

        if let accessToken = KeychainHelper.get("access_token"),
           let user = userFromToken(accessToken) {
            self.user = user
            return
        }

        if KeychainHelper.get("refresh_token") != nil {
            await refreshToken()
        }
    }

    // MARK: - Email & Password

    @MainActor
    func signIn(email: String, password: String) async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else {
            setError("メールアドレスとパスワードを入力してください")
            return
        }
        isSigningIn = true
        defer { isSigningIn = false }

        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password") else {
            setError("URLが無効です")
            return
        }
        await postAuth(url: url, body: ["email": trimmed, "password": password], isSignUp: false)
    }

    @MainActor
    func signUp(email: String, password: String, name: String?) async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            setError("メールアドレスを入力してください")
            return
        }
        guard password.count >= 6 else {
            setError("パスワードは6文字以上で入力してください")
            return
        }
        isSigningIn = true
        defer { isSigningIn = false }

        guard let url = URL(string: "\(supabaseURL)/auth/v1/signup") else {
            setError("URLが無効です")
            return
        }
        var body: [String: Any] = ["email": trimmed, "password": password]
        if let name, !name.isEmpty {
            body["data"] = ["name": name]
        }
        await postAuth(url: url, body: body, isSignUp: true)
    }

    @MainActor
    private func postAuth(url: URL, body: [String: Any], isSignUp: Bool) async {
        do {
            let (data, http) = try await sendJSON(url: url, body: body)

            if http.statusCode < 200 || http.statusCode >= 300 {
                let err = try? JSONDecoder().decode(SupabaseError.self, from: data)
                let raw = err?.msg ?? err?.error_description ?? err?.error ?? err?.message
                setError(translateError(raw ?? "認証に失敗しました (\(http.statusCode))"))
                return
            }

            let token = try JSONDecoder().decode(SupabaseTokenResponse.self, from: data)

            if let access = token.access_token {
                KeychainHelper.set("access_token", value: access)
                if let refresh = token.refresh_token {
                    KeychainHelper.set("refresh_token", value: refresh)
                }
                user = makeUser(from: token.user, accessToken: access)
            } else if isSignUp {
                if let bodyEmail = body["email"] as? String {
                    pendingVerificationEmail = bodyEmail
                    pendingVerificationPassword = body["password"] as? String
                    if let data = body["data"] as? [String: Any] {
                        pendingVerificationName = data["name"] as? String
                    }
                }
            } else {
                setError("ログインに失敗しました")
            }
        } catch {
            setError("ネットワークエラー: \(error.localizedDescription)")
        }
    }

    // MARK: - Deep link handling (email confirmation, magic link, OAuth fallback)

    @MainActor
    func handleDeepLink(_ url: URL) async {
        guard let host = url.host?.lowercased(), host == "auth-callback" || host == "login-callback" else {
            return
        }

        var params: [String: String] = [:]

        if let fragment = url.fragment, !fragment.isEmpty {
            for pair in fragment.split(separator: "&") {
                let parts = pair.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let key = String(parts[0])
                let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
                params[key] = value
            }
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let items = components.queryItems {
            for item in items {
                params[item.name] = item.value
            }
        }

        if let errorDescription = params["error_description"] ?? params["error"] {
            setError(translateError(errorDescription.replacingOccurrences(of: "+", with: " ")))
            return
        }

        if let access = params["access_token"] {
            KeychainHelper.set("access_token", value: access)
            if let refresh = params["refresh_token"] {
                KeychainHelper.set("refresh_token", value: refresh)
            }
            if let supaUser = await fetchUser(accessToken: access) {
                user = makeUser(from: supaUser, accessToken: access)
            } else {
                user = userFromToken(access)
            }
            setInfo("メールアドレスが確認されました。ようこそ！")
            return
        }

        if let token = params["token"] ?? params["token_hash"] {
            let type = params["type"] ?? "signup"
            await verifyEmailToken(token: token, type: type)
            return
        }
    }

    @MainActor
    private func verifyEmailToken(token: String, type: String) async {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/verify") else { return }
        do {
            let (data, http) = try await sendJSON(url: url, body: [
                "type": type,
                "token": token
            ])
            if http.statusCode < 200 || http.statusCode >= 300 {
                let err = try? JSONDecoder().decode(SupabaseError.self, from: data)
                let raw = err?.msg ?? err?.error_description ?? err?.error ?? err?.message
                setError(translateError(raw ?? "確認リンクが無効か期限切れです"))
                return
            }
            let response = try JSONDecoder().decode(SupabaseTokenResponse.self, from: data)
            if let access = response.access_token {
                KeychainHelper.set("access_token", value: access)
                if let refresh = response.refresh_token {
                    KeychainHelper.set("refresh_token", value: refresh)
                }
                user = makeUser(from: response.user, accessToken: access)
                setInfo("メールアドレスが確認されました。ようこそ！")
            } else {
                setInfo("メールアドレスが確認されました。ログインしてください。")
            }
        } catch {
            setError("ネットワークエラー: \(error.localizedDescription)")
        }
    }

    // MARK: - Email OTP verification (signup)

    @MainActor
    func verifySignupOtp(code: String) async {
        guard let email = pendingVerificationEmail else {
            setError("確認するメールアドレスがありません")
            return
        }
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            setError("認証コードを入力してください")
            return
        }

        isVerifyingOtp = true
        defer { isVerifyingOtp = false }

        guard let url = URL(string: "\(supabaseURL)/auth/v1/verify") else {
            setError("URLが無効です")
            return
        }
        do {
            let (data, http) = try await sendJSON(url: url, body: [
                "type": "signup",
                "email": email,
                "token": trimmedCode
            ])
            if http.statusCode < 200 || http.statusCode >= 300 {
                let err = try? JSONDecoder().decode(SupabaseError.self, from: data)
                let raw = err?.msg ?? err?.error_description ?? err?.error ?? err?.message
                setError(translateError(raw ?? "認証コードが無効か期限切れです"))
                return
            }
            let response = try JSONDecoder().decode(SupabaseTokenResponse.self, from: data)
            if let access = response.access_token {
                KeychainHelper.set("access_token", value: access)
                if let refresh = response.refresh_token {
                    KeychainHelper.set("refresh_token", value: refresh)
                }
                user = makeUser(from: response.user, accessToken: access, fallbackName: pendingVerificationName)
                clearPendingVerification()
            } else if let password = pendingVerificationPassword {
                await signIn(email: email, password: password)
                if user != nil { clearPendingVerification() }
            } else {
                setInfo("メールアドレスが確認されました。ログインしてください。")
                clearPendingVerification()
            }
        } catch {
            setError("ネットワークエラー: \(error.localizedDescription)")
        }
    }

    @MainActor
    func resendSignupOtp() async {
        guard let email = pendingVerificationEmail else { return }
        guard let url = URL(string: "\(supabaseURL)/auth/v1/resend") else { return }
        do {
            let (data, http) = try await sendJSON(url: url, body: [
                "type": "signup",
                "email": email
            ])
            if http.statusCode < 200 || http.statusCode >= 300 {
                let err = try? JSONDecoder().decode(SupabaseError.self, from: data)
                let raw = err?.msg ?? err?.error_description ?? err?.error ?? err?.message
                setError(translateError(raw ?? "再送信に失敗しました"))
                return
            }
            setInfo("認証コードを再送信しました。メールをご確認ください。")
        } catch {
            setError("ネットワークエラー: \(error.localizedDescription)")
        }
    }

    @MainActor
    func cancelPendingVerification() {
        clearPendingVerification()
    }

    @MainActor
    private func clearPendingVerification() {
        pendingVerificationEmail = nil
        pendingVerificationPassword = nil
        pendingVerificationName = nil
    }

    // MARK: - Sign in with Apple

    @MainActor
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    @MainActor
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                setError("Appleログインに失敗しました")
                return
            }

            var fullName: String? = nil
            if let nameComponents = credential.fullName {
                let formatted = PersonNameComponentsFormatter().string(from: nameComponents)
                if !formatted.isEmpty { fullName = formatted }
            }

            Task { await exchangeIdToken(provider: "apple", idToken: idToken, nonce: nonce, displayName: fullName) }
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            setError("Appleログインに失敗しました: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func exchangeIdToken(provider: String, idToken: String, nonce: String, displayName: String?) async {
        isSigningIn = true
        defer { isSigningIn = false }

        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=id_token") else {
            setError("URLが無効です")
            return
        }

        var body: [String: Any] = [
            "provider": provider,
            "id_token": idToken,
            "nonce": nonce
        ]
        if let displayName {
            body["data"] = ["name": displayName]
        }

        do {
            let (data, http) = try await sendJSON(url: url, body: body)
            if http.statusCode < 200 || http.statusCode >= 300 {
                let err = try? JSONDecoder().decode(SupabaseError.self, from: data)
                let raw = err?.msg ?? err?.error_description ?? err?.error ?? err?.message ?? "Appleログインに失敗しました"
                setError(translateError(raw))
                return
            }
            let token = try JSONDecoder().decode(SupabaseTokenResponse.self, from: data)
            if let access = token.access_token {
                KeychainHelper.set("access_token", value: access)
                if let refresh = token.refresh_token {
                    KeychainHelper.set("refresh_token", value: refresh)
                }
                user = makeUser(from: token.user, accessToken: access, fallbackName: displayName)
            } else {
                setError("Appleログインに失敗しました")
            }
        } catch {
            setError("ネットワークエラー: \(error.localizedDescription)")
        }
    }

    // MARK: - Sign in with Google (OAuth via ASWebAuthenticationSession)

    @MainActor
    func signInWithGoogle() async {
        isSigningIn = true
        defer { isSigningIn = false }

        guard var components = URLComponents(string: "\(supabaseURL)/auth/v1/authorize") else {
            setError("URLが無効です")
            return
        }
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: oauthRedirect)
        ]
        guard let url = components.url else {
            setError("URLが無効です")
            return
        }

        do {
            let callback = try await runWebAuth(url: url, scheme: "mikoto")
            try await handleOAuthCallback(callback)
        } catch let error as WebAuthCancelled {
            _ = error
            return
        } catch {
            setError("Googleログインに失敗しました: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func runWebAuth(url: URL, scheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { callback, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: WebAuthCancelled())
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callback else {
                    continuation.resume(throwing: WebAuthCancelled())
                    return
                }
                continuation.resume(returning: callback)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.googleSession = session
            session.start()
        }
    }

    @MainActor
    private func handleOAuthCallback(_ url: URL) async throws {
        var fragment = url.fragment ?? ""
        if fragment.isEmpty, let query = url.query { fragment = query }

        var params: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0])
            let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
            params[key] = value
        }

        if let errorDescription = params["error_description"] ?? params["error"] {
            setError(translateError(errorDescription.replacingOccurrences(of: "+", with: " ")))
            return
        }

        guard let access = params["access_token"] else {
            setError("Googleログインに失敗しました")
            return
        }

        KeychainHelper.set("access_token", value: access)
        if let refresh = params["refresh_token"] {
            KeychainHelper.set("refresh_token", value: refresh)
        }

        if let supaUser = await fetchUser(accessToken: access) {
            user = makeUser(from: supaUser, accessToken: access)
        } else {
            user = userFromToken(access)
        }
    }

    @MainActor
    private func fetchUser(accessToken: String) async -> SupabaseUser? {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/user") else { return nil }
        var request = URLRequest(url: url)
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try JSONDecoder().decode(SupabaseUser.self, from: data)
        } catch {
            return nil
        }
    }

    // MARK: - Refresh & sign out

    @MainActor
    private func refreshToken() async {
        guard let storedRefresh = KeychainHelper.get("refresh_token"),
              let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=refresh_token") else {
            user = nil
            return
        }

        do {
            let (data, http) = try await sendJSON(url: url, body: ["refresh_token": storedRefresh])
            guard http.statusCode == 200 else {
                await signOut()
                return
            }
            let token = try JSONDecoder().decode(SupabaseTokenResponse.self, from: data)
            if let access = token.access_token {
                KeychainHelper.set("access_token", value: access)
                if let refresh = token.refresh_token {
                    KeychainHelper.set("refresh_token", value: refresh)
                }
                user = makeUser(from: token.user, accessToken: access)
            } else {
                await signOut()
            }
        } catch {
            await signOut()
        }
    }

    @MainActor
    func signOut() async {
        KeychainHelper.delete("access_token")
        KeychainHelper.delete("refresh_token")
        user = nil
    }

    // MARK: - Helpers

    private func sendJSON(url: URL, body: [String: Any]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, http)
    }

    private func makeUser(from supaUser: SupabaseUser?, accessToken: String, fallbackName: String? = nil) -> User? {
        if let supaUser {
            let name = supaUser.user_metadata?["name"]?.stringValue
                ?? supaUser.user_metadata?["full_name"]?.stringValue
                ?? fallbackName
            let picture = supaUser.user_metadata?["picture"]?.stringValue
                ?? supaUser.user_metadata?["avatar_url"]?.stringValue
            return User(id: supaUser.id, email: supaUser.email ?? "", name: name, picture: picture)
        }
        if var fallback = userFromToken(accessToken) {
            if fallback.name == nil, let fallbackName {
                fallback = User(id: fallback.id, email: fallback.email, name: fallbackName, picture: fallback.picture)
            }
            return fallback
        }
        return nil
    }

    private func userFromToken(_ token: String) -> User? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let data = Data(base64Encoded: base64) else { return nil }

        struct JWTPayload: Codable {
            let sub: String
            let email: String?
            let exp: TimeInterval?
        }
        guard let payload = try? JSONDecoder().decode(JWTPayload.self, from: data) else { return nil }
        if let exp = payload.exp, Date(timeIntervalSince1970: exp) < Date() {
            return nil
        }
        return User(id: payload.sub, email: payload.email ?? "", name: nil, picture: nil)
    }

    private func translateError(_ message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("invalid login") || lower.contains("invalid_grant") || lower.contains("invalid credentials") {
            return "メールアドレスまたはパスワードが正しくありません"
        }
        if lower.contains("already registered") || lower.contains("user already") {
            return "このメールアドレスは既に登録されています。ログインしてください。"
        }
        if lower.contains("email not confirmed") {
            return "メールアドレスが未確認です。確認メールのコードを入力してからログインしてください。"
        }
        if lower.contains("token has expired") || lower.contains("otp") && lower.contains("expired") {
            return "認証コードの有効期限が切れています。再送信してください。"
        }
        if lower.contains("invalid token") || lower.contains("token is invalid") || (lower.contains("otp") && lower.contains("invalid")) {
            return "認証コードが正しくありません"
        }
        if lower.contains("password") && (lower.contains("6") || lower.contains("short") || lower.contains("weak")) {
            return "パスワードは6文字以上で入力してください"
        }
        if lower.contains("rate limit") || lower.contains("too many") {
            return "リクエストが多すぎます。しばらくしてからもう一度お試しください。"
        }
        if lower.contains("email address") && lower.contains("invalid") {
            return "メールアドレスの形式が正しくありません"
        }
        if lower.contains("signups not allowed") || lower.contains("signup is disabled") {
            return "現在新規登録は無効です。しばらくしてからもう一度お試しください。"
        }
        return message
    }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func setInfo(_ message: String) {
        infoMessage = message
        showInfo = true
    }

    // MARK: - Apple nonce

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            for random in randoms {
                if remaining == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
                ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            return scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first ?? ASPresentationAnchor()
        }
    }
}

private struct WebAuthCancelled: Error {}

nonisolated private struct SupabaseTokenResponse: Codable, Sendable {
    let access_token: String?
    let refresh_token: String?
    let user: SupabaseUser?
}

nonisolated private struct SupabaseUser: Codable, Sendable {
    let id: String
    let email: String?
    let user_metadata: [String: AnyJSON]?
}

nonisolated private struct SupabaseError: Codable, Sendable {
    let error: String?
    let error_description: String?
    let msg: String?
    let message: String?
}

nonisolated enum AnyJSON: Codable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case object([String: AnyJSON])
    case array([AnyJSON])

    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let v = try? c.decode(Bool.self) { self = .bool(v); return }
        if let v = try? c.decode(Double.self) { self = .number(v); return }
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode([String: AnyJSON].self) { self = .object(v); return }
        if let v = try? c.decode([AnyJSON].self) { self = .array(v); return }
        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .null: try c.encodeNil()
        case .object(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        }
    }
}
