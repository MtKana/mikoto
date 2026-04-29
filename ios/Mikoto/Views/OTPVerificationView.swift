import SwiftUI

struct OTPVerificationView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    let email: String

    @State private var code: String = ""
    @State private var resendCooldown: Int = 0
    @FocusState private var isFocused: Bool

    private let codeLength = 6

    var body: some View {
        @Bindable var auth = auth

        ZStack {
            background

            VStack(spacing: 0) {
                header
                Spacer().frame(height: 28)
                title
                Spacer().frame(height: 24)
                codeField
                Spacer().frame(height: 18)
                submitButton
                Spacer().frame(height: 16)
                resendBlock
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .onAppear { isFocused = true }
        .task { await startResendCooldown() }
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
    }

    private var background: some View {
        ZStack {
            Theme.bone.ignoresSafeArea()
            Circle()
                .fill(Theme.coral.opacity(0.5))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -120, y: -260)
            Circle()
                .fill(Theme.lavender.opacity(0.45))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 140, y: -100)
        }
        .allowsHitTesting(false)
    }

    private var header: some View {
        HStack {
            Button {
                auth.cancelPendingVerification()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .heavy))
                    Text("戻る")
                        .font(.mikotoSans(14, weight: .heavy))
                }
                .foregroundStyle(Theme.ink)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var title: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.popGradient)
                    .frame(width: 76, height: 76)
                    .shadow(color: Theme.coral.opacity(0.45), radius: 18, y: 8)
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
            }

            Text("認証コードを入力")
                .font(.mikotoDisplay(26, weight: .black))
                .foregroundStyle(Theme.ink)

            VStack(spacing: 4) {
                Text("\(email) に送信した")
                Text("6桁のコードを入力してください。")
            }
            .font(.mikotoSans(13, weight: .medium))
            .foregroundStyle(Theme.inkSoft)
            .multilineTextAlignment(.center)
        }
    }

    private var codeField: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0.001)
                .frame(height: 1)
                .onChange(of: code) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    let trimmed = String(digits.prefix(codeLength))
                    if trimmed != code { code = trimmed }
                    if trimmed.count == codeLength { submit() }
                }

            HStack(spacing: 10) {
                ForEach(0..<codeLength, id: \.self) { index in
                    digitBox(at: index)
                }
            }
            .onTapGesture { isFocused = true }
        }
    }

    private func digitBox(at index: Int) -> some View {
        let chars = Array(code)
        let char: String = index < chars.count ? String(chars[index]) : ""
        let isActive = index == chars.count && isFocused
        let isFilled = !char.isEmpty

        return Text(char.isEmpty ? " " : char)
            .font(.system(size: 26, weight: .black, design: .rounded))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isActive ? Theme.coral : (isFilled ? Theme.coral.opacity(0.4) : Theme.ink.opacity(0.1)),
                        lineWidth: isActive ? 2 : 1.5
                    )
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private var submitButton: some View {
        Button(action: submit) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.popGradient)
                    .shadow(color: Theme.coral.opacity(0.45), radius: 16, y: 8)

                if auth.isVerifyingOtp {
                    ProgressView().tint(.white)
                } else {
                    Text("認証する")
                        .font(.mikotoSans(16, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
        .disabled(auth.isVerifyingOtp || code.count < codeLength)
        .opacity(code.count < codeLength ? 0.6 : 1)
    }

    private var resendBlock: some View {
        VStack(spacing: 6) {
            Text("コードが届かない場合")
                .font(.mikotoSans(12, weight: .medium))
                .foregroundStyle(Theme.inkSubtle)

            Button {
                Task {
                    await auth.resendSignupOtp()
                    await startResendCooldown()
                }
            } label: {
                Text(resendCooldown > 0 ? "再送信 (\(resendCooldown)秒)" : "コードを再送信")
                    .font(.mikotoSans(14, weight: .heavy))
                    .foregroundStyle(resendCooldown > 0 ? Theme.inkSubtle : Theme.coral)
            }
            .buttonStyle(.plain)
            .disabled(resendCooldown > 0)
        }
    }

    private func submit() {
        isFocused = false
        Task { await auth.verifySignupOtp(code: code) }
    }

    private func startResendCooldown() async {
        resendCooldown = 60
        while resendCooldown > 0 {
            try? await Task.sleep(for: .seconds(1))
            resendCooldown -= 1
        }
    }
}
