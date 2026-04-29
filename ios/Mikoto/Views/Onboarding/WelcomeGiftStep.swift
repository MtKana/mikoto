import SwiftUI

struct WelcomeGiftStep: View {
    let onFinish: () -> Void

    @State private var pop: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    Spacer().frame(height: 24)

                    ZStack {
                        ForEach(0..<14, id: \.self) { i in
                            Circle()
                                .fill([Theme.coral, Theme.lavender, Theme.sunshine, Theme.mint, Theme.tangerine].randomElement() ?? Theme.coral)
                                .frame(width: CGFloat.random(in: 6...14), height: CGFloat.random(in: 6...14))
                                .offset(
                                    x: pop ? CGFloat.random(in: -160...160) : 0,
                                    y: pop ? CGFloat.random(in: -200...60) : 0
                                )
                                .opacity(pop ? 0.2 : 1)
                                .animation(.easeOut(duration: 1.4).delay(Double(i) * 0.04), value: pop)
                        }

                        ZStack {
                            Circle()
                                .fill(Theme.popGradient)
                                .frame(width: 160, height: 160)
                                .shadow(color: Theme.coral.opacity(0.5), radius: 30, y: 12)
                            Image(systemName: "gift.fill")
                                .font(.system(size: 64, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(pop ? 1.0 : 0.6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1), value: pop)
                    }
                    .frame(height: 220)

                    VStack(spacing: 12) {
                        EyebrowText(text: "🎉 ようこそ", color: Theme.coral, size: 12)
                        Text("15クレジットを\nプレゼント！")
                            .font(.mikotoDisplay(32, weight: .black))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                        Text("（3枚分の写真を無料で作成できます）")
                            .font(.mikotoSans(14, weight: .heavy))
                            .foregroundStyle(Theme.coral)
                    }

                    HStack(spacing: 12) {
                        bulletCard(icon: "sparkles", text: "8つのスタイル")
                        bulletCard(icon: "bolt.fill", text: "数秒で完成")
                        bulletCard(icon: "heart.fill", text: "自然な仕上がり")
                    }
                    .padding(.top, 6)

                    Spacer().frame(height: 12)
                }
                .padding(.horizontal, 24)
            }

            OnboardingPrimaryButton(title: "始める", action: onFinish)
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
                .padding(.top, 8)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { pop = true }
        }
        .sensoryFeedback(.success, trigger: pop)
    }

    private func bulletCard(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.coral))
            Text(text)
                .font(.mikotoSans(11, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
