import SwiftUI

struct PainStep: View {
    let onNext: () -> Void

    @State private var animate: Bool = false

    var body: some View {
        OnboardingScaffold(
            eyebrow: "なぜ大切か",
            title: "プロフィール写真は\nあなたの第一印象。",
            subtitle: "データが示す「写真の力」をご覧ください。",
            content: {
                VStack(spacing: 16) {
                    heroStat
                    statRow
                    dataNote
                }
            },
            footer: {
                OnboardingPrimaryButton(title: "実例を見る", action: onNext)
            }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animate = true
            }
        }
    }

    private var heroStat: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .heavy))
                Text("マッチングの決め手")
                    .font(.mikotoLabel(11, weight: .heavy))
                    .tracking(0.4)
            }
            .foregroundStyle(.white)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(animate ? "94" : "0")
                    .font(.mikotoDisplay(64, weight: .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("%")
                    .font(.mikotoDisplay(32, weight: .black))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Text("のユーザーが、最初の3秒間で\n「写真」だけで判断しています。")
                .font(.mikotoSans(13, weight: .heavy))
                .foregroundStyle(.white.opacity(0.95))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.popGradient)
        )
        .shadow(color: Theme.coral.opacity(0.35), radius: 18, y: 10)
    }

    private var statRow: some View {
        VStack(spacing: 12) {
            statCard(
                icon: "eye.fill",
                color: Theme.tangerine,
                value: "3倍",
                label: "良い写真は閲覧数が3倍になる",
                detail: "Tinder公式調査より"
            )
            statCard(
                icon: "heart.fill",
                color: Theme.coral,
                value: "+78%",
                label: "マッチ率の上昇率",
                detail: "プロ撮影写真使用時"
            )
            statCard(
                icon: "bolt.fill",
                color: Theme.lavender,
                value: "0.1秒",
                label: "第一印象が決まる時間",
                detail: "Princeton大学研究"
            )
        }
    }

    private func statCard(icon: String, color: Color, value: String, label: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Circle().fill(color))
                .shadow(color: color.opacity(0.4), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(value)
                        .font(.mikotoDisplay(22, weight: .black))
                        .foregroundStyle(Theme.ink)
                    Text(label)
                        .font(.mikotoSans(12, weight: .heavy))
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(detail)
                    .font(.mikotoLabel(10, weight: .heavy))
                    .foregroundStyle(Theme.inkSubtle)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private var dataNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Theme.sunshine)
            Text("つまり、写真を変えるだけで\n出会いの未来が大きく変わります。")
                .font(.mikotoSans(13, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .lineSpacing(3)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.sunshine.opacity(0.20)))
    }
}
