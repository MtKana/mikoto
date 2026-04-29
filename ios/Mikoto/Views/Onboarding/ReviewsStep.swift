import SwiftUI

struct ReviewsStep: View {
    let onNext: () -> Void

    private let reviews: [(String, Int, String, String)] = [
        ("マッチが3倍に！", 5, "ミコトを使い始めて2週間でマッチ数が一気に増えました。「写真変えた？」って友達に言われるくらい印象が変わって、自分でも驚いてます。", "あや · 27歳"),
        ("プロ撮影より気軽", 5, "スタジオ予約も化粧直しも要らず、家でサクッと作れるのが本当に便利。8つのスタイルから選べるので、いろんな雰囲気を試せました。", "けんた · 31歳"),
        ("自然な仕上がり", 5, "AIだとバレない自然さがすごい。ちゃんと自分の顔のまま、雰囲気だけ綺麗になってる感じで、嬉しい誤算でした。", "ゆうか · 24歳"),
        ("出会えました", 5, "気軽に始めたのに、3ヶ月で素敵な人に出会えました。最初の印象って本当に大事だと実感しています。", "りょう · 33歳")
    ]

    var body: some View {
        OnboardingScaffold(
            eyebrow: "ご利用者の声",
            title: "98%が満足したと\n答えています。",
            subtitle: "実際にミコトを使った方々の声です。",
            content: {
                VStack(spacing: 14) {
                    ForEach(0..<reviews.count, id: \.self) { i in
                        let r = reviews[i]
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 3) {
                                ForEach(0..<r.1, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(Theme.sunshine)
                                }
                            }
                            Text(r.0)
                                .font(.mikotoDisplay(16, weight: .heavy))
                                .foregroundStyle(Theme.ink)
                            Text(r.2)
                                .font(.mikotoSans(13, weight: .medium))
                                .foregroundStyle(Theme.inkSoft)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack {
                                Circle()
                                    .fill(Theme.popGradient)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Text(String(r.3.prefix(1)))
                                            .font(.system(size: 11, weight: .black, design: .rounded))
                                            .foregroundStyle(.white)
                                    )
                                Text(r.3)
                                    .font(.mikotoLabel(11, weight: .heavy))
                                    .foregroundStyle(Theme.inkSubtle)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.white)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                    }
                }
            },
            footer: {
                OnboardingPrimaryButton(title: "私も始める", action: onNext)
            }
        )
    }
}
