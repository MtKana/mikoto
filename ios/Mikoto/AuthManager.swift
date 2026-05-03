import SwiftUI
import Foundation
import AuthenticationServices
import CryptoKit
import Supabase

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
    var inlineAuthError: String?

    private var currentNonce: String?
    private var googleSession: ASWebAuthenticationSession?
    private let oauthRedirect = "mikoto://auth-callback"
    private var emailRedirectURL: URL? { URL(string: oauthRedirect) }

    nonisolated struct User: Codable, Sendable {
        let id: String
        let email: String
        let name: String?
        let picture: String?
    }

    override init() {
        super.init()
        Task { await observeAuthState() }
    }

    // MARK: - Auth State Observation

    @MainActor
    private func observeAuthState() async {
        for await (event, session) in supabase.auth.authStateChanges {
            switch event {
            case .initialSession:
                user = session.map { mapUser($0) }
                isLoading = false
            case .signedIn:
                user = session.map { mapUser($0) }
            case .signedOut:
                user = nil
            default:
                break
            }
        }
    }

    private func mapUser(_ session: Session) -> User {
        let u = session.user
        return User(
            id: u.id.uuidString,
            email: u.email ?? "",
            name: u.userMetadata["name"]?.stringValue
                ?? u.userMetadata["full_name"]?.stringValue,
            picture: u.userMetadata["picture"]?.stringValue
                ?? u.userMetadata["avatar_url"]?.stringValue
        )
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
        inlineAuthError = nil
        defer { isSigningIn = false }

        do {
            try await supabase.auth.signIn(email: trimmed, password: password)
        } catch {
            // If email is not confirmed, route the user into the OTP screen
            // so they can finish verification with the code we just sent.
            let lower = error.localizedDescription.lowercased()
            if lower.contains("email not confirmed") || lower.contains("not confirmed") {
                pendingVerificationEmail = trimmed
                pendingVerificationPassword = password
                pendingVerificationName = nil
                // Trigger a fresh OTP email so the user has a current code.
                try? await supabase.auth.resend(
                    email: trimmed,
                    type: .signup,
                    emailRedirectTo: emailRedirectURL
                )
                setInfo("認証コードをメールで送信しました。コードを入力してログインを完了してください。")
                return
            }
            handleAuthError(error)
        }
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
        inlineAuthError = nil
        defer { isSigningIn = false }

        do {
            var userData: [String: AnyJSON] = [:]
            if let name, !name.isEmpty {
                userData["name"] = .string(name)
            }
            let response = try await supabase.auth.signUp(
                email: trimmed,
                password: password,
                data: userData.isEmpty ? nil : userData,
                redirectTo: emailRedirectURL
            )

            // Detect "user already registered" — Supabase returns a fake user
            // with an empty identities array when confirm-email is on.
            let identitiesEmpty = (response.user.identities?.isEmpty ?? false)
            if response.session == nil && identitiesEmpty {
                setError("このメールアドレスは既に登録されています。ログインしてください。")
                return
            }

            if response.session == nil {
                pendingVerificationEmail = trimmed
                pendingVerificationPassword = password
                pendingVerificationName = name
                setInfo("認証コードをメールで送信しました。受信箱をご確認ください。")
            }
        } catch {
            handleAuthError(error)
        }
    }

    // MARK: - Deep link handling

    @MainActor
    func handleDeepLink(_ url: URL) async {
        guard let host = url.host?.lowercased(),
              host == "auth-callback" || host == "login-callback" else {
            return
        }
        do {
            try await supabase.auth.session(from: url)
            setInfo("メールアドレスが確認されました。ようこそ！")
        } catch {
            handleAuthError(error)
        }
    }

    // MARK: - Email OTP verification

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

        do {
            try await supabase.auth.verifyOTP(
                email: email,
                token: trimmedCode,
                type: .signup
            )
            clearPendingVerification()
        } catch {
            if let password = pendingVerificationPassword {
                do {
                    try await supabase.auth.signIn(email: email, password: password)
                    clearPendingVerification()
                } catch {
                    handleAuthError(error)
                }
            } else {
                handleAuthError(error)
            }
        }
    }

    @MainActor
    func resendSignupOtp() async {
        guard let email = pendingVerificationEmail else { return }
        do {
            try await supabase.auth.resend(
                email: email,
                type: .signup,
                emailRedirectTo: emailRedirectURL
            )
            setInfo("認証コードを再送信しました。メールをご確認ください。")
        } catch {
            handleAuthError(error)
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

            Task { await exchangeAppleToken(idToken: idToken, nonce: nonce, displayName: fullName) }
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            setError("Appleログインに失敗しました: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func exchangeAppleToken(idToken: String, nonce: String, displayName: String?) async {
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            if let displayName {
                try? await supabase.auth.update(user: UserAttributes(data: ["name": .string(displayName)]))
            }
        } catch {
            handleAuthError(error)
        }
    }

    // MARK: - Sign in with Google

    @MainActor
    func signInWithGoogle() async {
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            let url = try supabase.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: URL(string: oauthRedirect)!
            )
            let callback = try await runWebAuth(url: url, scheme: "mikoto")
            try await supabase.auth.session(from: callback)
        } catch is WebAuthCancelled {
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

    // MARK: - Sign out

    @MainActor
    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            NSLog("[Auth] sign out error: %@", error.localizedDescription)
        }
        user = nil
    }

    // MARK: - Helpers

    private func handleAuthError(_ error: Error) {
        let raw = error.localizedDescription
        let translated = translateError(raw)
        inlineAuthError = translated
        errorMessage = translated
        showError = true
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
