import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CreditStore.self) private var credits

    @State private var selectedPlan: CreditStore.Plan = .standard
    @State private var selectedCycle: CreditStore.BillingCycle = .annual
    @State private var showDiscount: Bool = false
    @State private var subscribed: Bool = false

    var body: some View {
        ZStack {
            backdrop

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    closeBar
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    hero
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    trialBanner
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    cycleToggle
                        .padding(.horizontal, 24)
                        .padding(.top, 22)

                    planCards
                        .padding(.horizontal, 24)
                        .padding(.top, 14)

                    benefits
                        .padding(.horizontal, 24)
                        .padding(.top, 22)

                    legal
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 130)
                }
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()
                ctaBar
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(Theme.bone.ignoresSafeArea())
        .fullScreenCover(isPresented: $showDiscount) {
            DiscountPaywallView(onClose: {
                showDiscount = false
                dismiss()
            })
        }
        .sensoryFeedback(.success, trigger: subscribed)
        .onChange(of: subscribed) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    dismiss()
                }
            }
        }
    }

    private var backdrop: some View {
        ZStack {
            Theme.bone.ignoresSafeArea()
            Circle().fill(Theme.coral.opacity(0.25)).frame(width: 360, height: 360).blur(radius: 90).offset(x: -150, y: -300)
            Circle().fill(Theme.lavender.opacity(0.30)).frame(width: 360, height: 360).blur(radius: 90).offset(x: 160, y: 280)
        }
        .allowsHitTesting(false)
    }

    private var closeBar: some View {
        HStack {
            Wordmark(size: 16)
            Spacer()
            Button {
                showDiscount = true
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

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 11, weight: .heavy))
                Text("ミコト プレミアム")
                    .font(.mikotoLabel(11, weight: .heavy))
                    .tracking(0.5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.popGradient))

            Text("運命の出会いまで、\nあと一枚。")
                .font(.mikotoDisplay(30, weight: .black))
                .foregroundStyle(Theme.ink)
                .lineSpacing(2)

            Text("無制限のスタイル、毎月たっぷりのクレジット。\n7日間、無料でお試しいただけます。")
                .font(.mikotoSans(14, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
    }

    private var trialBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(.white).frame(width: 48, height: 48)
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Theme.coral)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("今すぐ請求はされません")
                    .font(.mikotoDisplay(15, weight: .black))
                    .foregroundStyle(.white)
                Text("7日間の無料トライアル後に課金開始")
                    .font(.mikotoSans(12, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.92))
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.popGradient)
        )
        .shadow(color: Theme.coral.opacity(0.4), radius: 14, y: 6)
    }

    private var cycleToggle: some View {
        HStack(spacing: 6) {
            cycleButton(.monthly, label: "月額")
            cycleButton(.annual, label: "年額", badge: "30% OFF")
        }
        .padding(5)
        .background(
            Capsule().fill(.white)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }

    private func cycleButton(_ cycle: CreditStore.BillingCycle, label: String, badge: String? = nil) -> some View {
        Button {
            withAnimation(.spring) { selectedCycle = cycle }
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(.mikotoSans(13, weight: .heavy))
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.coral))
                }
            }
            .foregroundStyle(selectedCycle == cycle ? .white : Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                Capsule().fill(selectedCycle == cycle ? AnyShapeStyle(Theme.popGradient) : AnyShapeStyle(Color.clear))
            )
        }
        .buttonStyle(.plain)
    }

    private var planCards: some View {
        VStack(spacing: 12) {
            planCard(
                plan: .standard,
                tag: "おすすめ",
                title: "スタンダード",
                creditsText: "75クレジット / 月",
                priceMain: priceMain(plan: .standard),
                priceUnit: "/ 月",
                priceFootnote: priceFootnote(plan: .standard),
                tint: Theme.coral
            )
            planCard(
                plan: .professional,
                tag: "プロ向け",
                title: "プロフェッショナル",
                creditsText: "225クレジット / 月",
                priceMain: priceMain(plan: .professional),
                priceUnit: "/ 月",
                priceFootnote: priceFootnote(plan: .professional),
                tint: Theme.lavender
            )
        }
    }

    private func planCard(
        plan: CreditStore.Plan,
        tag: String,
        title: String,
        creditsText: String,
        priceMain: String,
        priceUnit: String,
        priceFootnote: String?,
        tint: Color
    ) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            withAnimation(.spring) { selectedPlan = plan }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : Theme.ink.opacity(0.18), lineWidth: 2)
                    if isSelected {
                        Circle().fill(tint)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 24, height: 24)
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.mikotoDisplay(18, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                        Text(tag)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(tint))
                    }
                    Text(creditsText)
                        .font(.mikotoSans(13, weight: .heavy))
                        .foregroundStyle(tint)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(priceMain)
                            .font(.mikotoDisplay(20, weight: .black))
                            .foregroundStyle(Theme.ink)
                        Text(priceUnit)
                            .font(.mikotoSans(11, weight: .heavy))
                            .foregroundStyle(Theme.inkSubtle)
                    }
                    if let priceFootnote {
                        Text(priceFootnote)
                            .font(.mikotoSans(10, weight: .heavy))
                            .foregroundStyle(tint)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? tint : Theme.ink.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? tint.opacity(0.25) : .black.opacity(0.04), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func priceMain(plan: CreditStore.Plan) -> String {
        switch (plan, selectedCycle) {
        case (.standard, .monthly): return "¥1,343"
        case (.standard, .annual): return "¥940"
        case (.professional, .monthly): return "¥2,954"
        case (.professional, .annual): return "¥1,920"
        default: return ""
        }
    }

    private func priceFootnote(plan: CreditStore.Plan) -> String? {
        switch (plan, selectedCycle) {
        case (.standard, .annual): return "年額 ¥11,281 (30% OFF)"
        case (.professional, .annual): return "年額 ¥23,041 (35% OFF)"
        default: return nil
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefitRow("8つすべてのスタイルが使える")
            benefitRow("毎月たっぷりのクレジット")
            benefitRow("いつでも解約OK")
            benefitRow("写真は安全に処理されます")
        }
    }

    private func benefitRow(_ text: String) -> some View {
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

    private var legal: some View {
        Text("7日間の無料トライアル後、選択したプランで自動更新されます。設定からいつでも解約できます。")
            .font(.mikotoSans(11, weight: .medium))
            .foregroundStyle(Theme.inkSubtle)
            .lineSpacing(2)
    }

    private var ctaBar: some View {
        VStack(spacing: 8) {
            Button {
                credits.subscribe(plan: selectedPlan, cycle: selectedCycle, withTrial: true)
                subscribed = true
            } label: {
                HStack(spacing: 8) {
                    Text("7日間無料で始める")
                        .font(.mikotoSans(16, weight: .heavy))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .heavy))
                }
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

            HStack(spacing: 16) {
                Text("いつでも解約OK")
                    .font(.mikotoLabel(11, weight: .heavy))
                    .foregroundStyle(Theme.inkSubtle)
                Circle().fill(Theme.inkSubtle.opacity(0.4)).frame(width: 3, height: 3)
                Text("購入を復元")
                    .font(.mikotoLabel(11, weight: .heavy))
                    .foregroundStyle(Theme.coral)
                    .onTapGesture {
                        // Restore handled via Settings
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [Theme.bone.opacity(0), Theme.bone, Theme.bone],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
