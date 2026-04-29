import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.colorScheme) private var colorScheme

    @State private var mode: Mode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @FocusState private var focused: Field?

    enum Mode { case signIn, signUp }
    enum Field { case name, email, password }

    var body: some View {
        @Bindable var auth = auth

        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 48)
                    logoBlock
                    Spacer().frame(height: 22)
                    headlineBlock.padding(.horizontal, 28)
                    Spacer().frame(height: 22)
                    socialButtons.padding(.horizontal, 24)
                    dividerBlock.padding(.horizontal, 24).padding(.vertical, 18)
                    modeToggle.padding(.horizontal, 24)
                    Spacer().frame(height: 14)
                    formBlock.padding(.horizontal, 24)
                    Spacer().frame(height: 14)
                    submitButton.padding(.horizontal, 24)
                    legalBlock
                        .padding(.horizontal, 32)
                        .padding(.top, 18)
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("お知らせ", isPresented: $auth.showError) {
            Button("OK") { }
        } message: {
            Text(auth.errorMessage)
        }
        .alert("ご確認ください", isPresented: $auth.showInfo) {
            Button("OK") { }
        } message: {
            Text(auth.infoMessage)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { auth.pendingVerificationEmail != nil },
                set: { if !$0 { auth.cancelPendingVerification() } }
            )
        ) {
            if let pendingEmail = auth.pendingVerificationEmail {
                OTPVerificationView(email: pendingEmail)
                    .environment(auth)
            }
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Theme.bone.ignoresSafeArea()
            Circle()
                .fill(Theme.coral.opacity(0.55))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -120, y: -260)
            Circle()
                .fill(Theme.lavender.opacity(0.5))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 140, y: -100)
            Circle()
                .fill(Theme.sunshine.opacity(0.45))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: -100, y: 240)
        }
        .allowsHitTesting(false)
    }

    private var logoBlock: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.popGradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: Theme.coral.opacity(0.45), radius: 22, y: 10)
                Text("M")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text("ミコト")
                .font(.mikotoDisplay(24, weight: .black))
                .foregroundStyle(Theme.ink)
        }
    }

    private var headlineBlock: some View {
        VStack(spacing: 10) {
            Text(mode == .signIn ? "おかえりなさい" : "はじめまして")
                .font(.mikotoDisplay(28, weight: .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(mode == .signIn
                 ? "アカウントにログインして続けましょう。"
                 : "アカウントを作成して、運命の一枚を作りましょう。")
                .font(.mikotoSans(14, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    private var socialButtons: some View {
        VStack(spacing: 10) {
            SignInWithAppleButton(.continue) { request in
                auth.handleAppleSignInRequest(request)
            } onCompletion: { result in
                auth.handleAppleSignInCompletion(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            .disabled(auth.isSigningIn)

            Button {
                Task { await auth.signInWithGoogle() }
            } label: {
                HStack(spacing: 10) {
                    GoogleGlyph()
                        .frame(width: 20, height: 20)
                    Text("Googleで続ける")
                        .font(.mikotoSans(15, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Theme.ink.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(auth.isSigningIn)
        }
    }

    private var dividerBlock: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Theme.ink.opacity(0.12))
                .frame(height: 1)
            Text("または")
                .font(.mikotoSans(12, weight: .heavy))
                .foregroundStyle(Theme.inkSubtle)
            Rectangle()
                .fill(Theme.ink.opacity(0.12))
                .frame(height: 1)
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            toggleTab("ログイン", active: mode == .signIn) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { mode = .signIn }
            }
            toggleTab("新規登録", active: mode == .signUp) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { mode = .signUp }
            }
        }
        .padding(4)
        .background(
            Capsule().fill(.white.opacity(0.85))
        )
        .overlay(Capsule().strokeBorder(Theme.ink.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }

    private func toggleTab(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.mikotoSans(14, weight: .heavy))
                .foregroundStyle(active ? .white : Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    Capsule().fill(active ? AnyShapeStyle(Theme.popGradient) : AnyShapeStyle(Color.clear))
                )
        }
        .buttonStyle(.plain)
    }

    private var formBlock: some View {
        VStack(spacing: 12) {
            if mode == .signUp {
                fieldRow(icon: "person.fill", placeholder: "お名前 (任意)", text: $name, isSecure: false, field: .name, keyboard: .default, content: .name)
            }
            fieldRow(icon: "envelope.fill", placeholder: "メールアドレス", text: $email, isSecure: false, field: .email, keyboard: .emailAddress, content: .emailAddress)
            fieldRow(icon: "lock.fill", placeholder: mode == .signUp ? "パスワード (6文字以上)" : "パスワード", text: $password, isSecure: true, field: .password, keyboard: .default, content: mode == .signUp ? .newPassword : .password)
        }
    }

    private func fieldRow(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool, field: Field, keyboard: UIKeyboardType, content: UITextContentType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Theme.coral)
                .frame(width: 24)
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(field == .name ? .words : .never)
                        .autocorrectionDisabled(field != .name)
                }
            }
            .font(.mikotoSans(15, weight: .medium))
            .foregroundStyle(Theme.ink)
            .focused($focused, equals: field)
            .textContentType(content)
            .submitLabel(field == .password ? .go : .next)
            .onSubmit {
                switch field {
                case .name: focused = .email
                case .email: focused = .password
                case .password: submit()
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(focused == field ? Theme.coral.opacity(0.6) : Theme.ink.opacity(0.08), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private var submitButton: some View {
        Button(action: submit) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.popGradient)
                    .shadow(color: Theme.coral.opacity(0.45), radius: 16, y: 8)

                if auth.isSigningIn {
                    ProgressView().tint(.white)
                } else {
                    Text(mode == .signIn ? "ログイン" : "アカウントを作成")
                        .font(.mikotoSans(16, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
        .disabled(auth.isSigningIn)
    }

    private func submit() {
        focused = nil
        Task {
            switch mode {
            case .signIn:
                await auth.signIn(email: email, password: password)
            case .signUp:
                await auth.signUp(email: email, password: password, name: name)
            }
        }
    }

    private var legalBlock: some View {
        Text("続行することで、利用規約とプライバシーポリシーに同意したものとみなされます。")
            .font(.mikotoSans(11, weight: .medium))
            .foregroundStyle(Theme.inkSubtle)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }
}

private struct GoogleGlyph: View {
    var body: some View {
        Canvas { context, size in
            let r = size.width / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            func slice(_ start: Double, _ end: Double, color: Color) {
                let path = Path { p in
                    p.move(to: center)
                    p.addArc(center: center, radius: r,
                             startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
                    p.closeSubpath()
                }
                context.fill(path, with: .color(color))
            }

            slice(-90, 0, color: Color(red: 0.92, green: 0.26, blue: 0.21))
            slice(0, 90, color: Color(red: 1.00, green: 0.74, blue: 0.00))
            slice(90, 180, color: Color(red: 0.20, green: 0.66, blue: 0.33))
            slice(180, 270, color: Color(red: 0.26, green: 0.52, blue: 0.96))

            let inner = Path(ellipseIn: CGRect(x: center.x - r * 0.45, y: center.y - r * 0.45,
                                               width: r * 0.9, height: r * 0.9))
            context.fill(inner, with: .color(.white))

            let bar = Path(CGRect(x: center.x, y: center.y - r * 0.16,
                                  width: r * 0.95, height: r * 0.32))
            context.fill(bar, with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)))
        }
    }
}
