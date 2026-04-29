import SwiftUI

struct DiscountPaywallView: View {
    let onClose: () -> Void
    @Environment(CreditStore.self) private var credits
    @State private var subscribed: Bool = false

    var body: some View {
        ZStack {
            Theme.bone.ignoresSafeArea()
            backdrop

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    closeBar
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    badge
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    headline
                        .padding(.horizontal, 24)
                        .padding(.top, 14)

                    priceCard
                        .padding(.horizontal, 24)
                        .padding(.top, 22)

                    bullets
                        .padding(.horizontal, 24)
                        .padding(.top, 22)

                    Spacer().frame(height: 130)
                }
            }

            VStack {
                Spacer()
                cta
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sensoryFeedback(.success, trigger: subscribed)
        .onChange(of: subscribed) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onClose() }
            }
        }
    }

    private var backdrop: some View {
        ZStack {
            Circle().fill(Theme.coral.opacity(0.30)).frame(width: 380, height: 380).blur(radius: 100).offset(x: -140, y: -280)
            Circle().fill(Theme.sunshine.opacity(0.35)).frame(width: 320, height: 320).blur(radius: 100).offset(x: 150, y: 280)
        }
        .allowsHitTesting(false)
    }

    private var closeBar: some View {
        HStack {
            Spacer()
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(.white))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    private var badge: some View {
        HStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.system(size: 12, weight: .heavy))
            Text("特別オファー")
                .font(.mikotoLabel(12, weight: .heavy))
                .tracking(0.6)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Theme.popGradient))
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("お別れの前に、\nひとつだけ。")
                .font(.mikotoDisplay(30, weight: .black))
                .foregroundStyle(Theme.ink)
                .lineSpacing(2)
            Text("最初の3ヶ月、特別価格でご利用いただけます。")
                .font(.mikotoSans(15, weight: .heavy))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("36% OFF")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.25)))
                Text("最初の3ヶ月")
                    .font(.mikotoLabel(11, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.95))
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("¥858")
                    .font(.mikotoDisplay(56, weight: .black))
                    .foregroundStyle(.white)
                Text("/ 月")
                    .font(.mikotoSans(15, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("¥1,343")
                    .font(.mikotoSans(14, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.7))
                    .strikethrough()
            }

            Text("4ヶ月目以降は通常価格 ¥1,343/月。\nスタンダードプランの全機能を利用できます。")
                .font(.mikotoSans(12, weight: .heavy))
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(
                    colors: [Theme.coral, Theme.magenta, Theme.lavender],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .shadow(color: Theme.coral.opacity(0.4), radius: 18, y: 10)
    }

    private var bullets: some View {
        VStack(alignment: .leading, spacing: 12) {
            row("スタンダードプランの全機能")
            row("8つすべてのスタイル")
            row("いつでも解約OK")
        }
    }

    private func row(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Theme.coral)
            Text(text)
                .font(.mikotoSans(14, weight: .heavy))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }

    private var cta: some View {
        VStack(spacing: 10) {
            Button {
                credits.subscribe(plan: .standard, cycle: .monthly, withTrial: false)
                subscribed = true
            } label: {
                Text("特別オファーを受け取る")
                    .font(.mikotoSans(16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Theme.popGradient)
                    )
                    .shadow(color: Theme.coral.opacity(0.45), radius: 16, y: 8)
            }
            .buttonStyle(.plain)

            Button {
                onClose()
            } label: {
                Text("いいえ、結構です")
                    .font(.mikotoLabel(12, weight: .heavy))
                    .foregroundStyle(Theme.inkSubtle)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [Theme.bone.opacity(0), Theme.bone, Theme.bone],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
