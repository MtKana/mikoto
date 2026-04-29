import SwiftUI

struct FeaturesStep: View {
    let onNext: () -> Void

    @State private var page: Int = 0
    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Group {
                    switch page {
                    case 0: introPage
                    case 1: stylesPage
                    default: customPage
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(page)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: page)

            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Theme.coral : Theme.ink.opacity(0.15))
                        .frame(width: i == page ? 22 : 6, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: page)
                }
            }
            .padding(.bottom, 6)

            OnboardingPrimaryButton(title: page < totalPages - 1 ? "次へ" : "始めよう") {
                if page < totalPages - 1 {
                    page += 1
                } else {
                    onNext()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
    }

    // MARK: - Page 1: App intro

    private var introPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                EyebrowText(text: "Mikoto とは", color: Theme.coral, size: 11)
                    .padding(.top, 18)

                Text("AIが、あなたの\n最高の一枚を作る。")
                    .font(.mikotoDisplay(30, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("マッチングアプリ専用に設計された、AIプロフィール写真ジェネレーター。一枚のセルフィーから、まるでプロが撮影したような高品質な一枚を生成します。")
                    .font(.mikotoSans(15, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                heroIllustration
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 12) {
                    pillarRow(
                        icon: "wand.and.stars",
                        color: Theme.coral,
                        title: "セルフィー1枚でOK",
                        subtitle: "撮影スタジオも、プロのカメラマンも不要。"
                    )
                    pillarRow(
                        icon: "bolt.heart.fill",
                        color: Theme.tangerine,
                        title: "マッチングアプリに最適化",
                        subtitle: "Tinder、Pairs、Bumbleで「いいね」が増える写真。"
                    )
                    pillarRow(
                        icon: "lock.shield.fill",
                        color: Theme.mint,
                        title: "数秒で完成・安全に処理",
                        subtitle: "あなたの写真は暗号化され、第三者と共有されません。"
                    )
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var heroIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.popGradient)

            Circle().fill(.white.opacity(0.18)).frame(width: 220, height: 220).offset(x: -100, y: -60)
            Circle().fill(.white.opacity(0.10)).frame(width: 160, height: 160).offset(x: 110, y: 70)

            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    miniPortrait(symbol: "person.fill", tint: .white.opacity(0.35), label: "BEFORE")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                    miniPortrait(symbol: "sparkles", tint: .white, label: "AFTER")
                }
                Text("AIによる写真変換")
                    .font(.mikotoLabel(11, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(height: 220)
    }

    private func miniPortrait(symbol: String, tint: Color, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(tint == .white ? Theme.coral : .white)
                .frame(width: 76, height: 76)
                .background(Circle().fill(tint))
            Text(label)
                .font(.mikotoLabel(9, weight: .black))
                .tracking(1.0)
                .foregroundStyle(.white)
        }
    }

    private func pillarRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.mikotoSans(14, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.mikotoSans(12, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Page 2: 8 styles

    private var stylesPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                EyebrowText(text: "8つのスタイル", color: Theme.coral, size: 11)
                    .padding(.top, 18)

                Text("選べる、\n8つの世界観。")
                    .font(.mikotoDisplay(28, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("清楚、カフェ、夕日、ネオン、京都…。気分やマッチしたい相手に合わせて、雰囲気を自在に切り替えできます。")
                    .font(.mikotoSans(14, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Theme.coral)
                        .frame(width: 4, height: 16)
                        .clipShape(.rect(cornerRadius: 2))
                    Text("プリセット・スタイル一覧")
                        .font(.mikotoDisplay(15, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.inkSubtle)
                }
                Text("流れるカードは、すべてアプリで実際に選べるスタイルです。")
                    .font(.mikotoSans(11, weight: .medium))
                    .foregroundStyle(Theme.inkSubtle)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            InfiniteStyleMarquee()
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 10) {
                smallRow(icon: "rectangle.stack.fill", color: Theme.lavender, text: "8つの厳選スタイル")
                smallRow(icon: "sparkles", color: Theme.coral, text: "毎月、新しいスタイルが追加")
                smallRow(icon: "photo.on.rectangle.angled", color: Theme.tangerine, text: "1スタイルごとに何枚でも生成可能")
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func smallRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(color))
            Text(text)
                .font(.mikotoSans(13, weight: .heavy))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }

    // MARK: - Page 3: Custom style

    private var customPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                EyebrowText(text: "あなた専用のスタイル", color: Theme.coral, size: 11)
                    .padding(.top, 18)

                Text("そして、世界に一つの\nあなただけの一枚。")
                    .font(.mikotoDisplay(30, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("AIがあなたの性格・ライフスタイル・好みを分析し、8つの定番とは別に、あなた専用のオリジナルスタイルを設計します。")
                    .font(.mikotoSans(15, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                customCard

                VStack(alignment: .leading, spacing: 12) {
                    pillarRow(
                        icon: "person.crop.circle.badge.checkmark",
                        color: Theme.coral,
                        title: "あなたの個性を分析",
                        subtitle: "数問の質問から、あなたに最も似合う雰囲気を導き出します。"
                    )
                    pillarRow(
                        icon: "wand.and.rays",
                        color: Theme.lavender,
                        title: "オリジナルの世界観を設計",
                        subtitle: "名前・色・撮影シーンまで、あなただけのスタイルが誕生します。"
                    )
                    pillarRow(
                        icon: "infinity",
                        color: Theme.mint,
                        title: "ホームに常設・何度でも生成",
                        subtitle: "8つの定番スタイルと一緒に、いつでも使えます。"
                    )
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var customCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text("ONLY FOR YOU")
                        .font(.mikotoLabel(10, weight: .black))
                        .tracking(1.0)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.popGradient))
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Theme.coral)
                }

                Color.clear
                    .frame(height: 130)
                    .overlay {
                        ZStack {
                            LinearGradient(
                                colors: [Theme.coral.opacity(0.85), Theme.lavender.opacity(0.85)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            VStack(spacing: 6) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36, weight: .heavy))
                                    .foregroundStyle(.white)
                                Text("YOUR ORIGINAL")
                                    .font(.mikotoLabel(10, weight: .black))
                                    .tracking(1.4)
                                    .foregroundStyle(.white.opacity(0.95))
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("あなただけの名前と世界観")
                        .font(.mikotoDisplay(16, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("「夕暮れの優しさ」「東京リフレクション」など、あなたの回答から生まれる固有のスタイル。")
                        .font(.mikotoSans(12, weight: .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
        }
        .shadow(color: Theme.coral.opacity(0.18), radius: 18, y: 10)
    }
}

private struct InfiniteStyleMarquee: View {
    private let cardWidth: CGFloat = 130
    private let spacing: CGFloat = 12
    private let cardHeight: CGFloat = 160

    private var styles: [PhotoStyle] { PhotoStyle.all }

    private var setWidth: CGFloat {
        CGFloat(styles.count) * (cardWidth + spacing)
    }

    var body: some View {
        Color.clear
            .frame(height: cardHeight + 52)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let speed: Double = 75
                    let raw = t * speed
                    let offset = -CGFloat(raw.truncatingRemainder(dividingBy: Double(setWidth)))

                    HStack(spacing: spacing) {
                        ForEach(0..<3, id: \.self) { loop in
                            ForEach(Array(styles.enumerated()), id: \.offset) { idx, style in
                                card(for: style, idx: idx)
                                    .id("\(loop)-\(style.id)")
                            }
                        }
                    }
                    .offset(x: offset)
                    .fixedSize(horizontal: true, vertical: false)
                }
                .allowsHitTesting(false)
            }
            .clipped()
    }

    private func card(for style: PhotoStyle, idx: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .frame(width: cardWidth, height: cardHeight)
                .overlay {
                    StyleArtwork(style: style)
                        .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white, lineWidth: 3)
                )
                .overlay(alignment: .topLeading) {
                    Text(String(format: "%02d", idx + 1))
                        .font(.mikotoDisplay(11, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white))
                        .padding(8)
                }
            Text(style.nameJP)
                .font(.mikotoDisplay(15, weight: .heavy))
                .foregroundStyle(Theme.ink)
            Text(style.mood)
                .font(.mikotoLabel(10, weight: .heavy))
                .foregroundStyle(Theme.inkSubtle)
        }
        .frame(width: cardWidth, alignment: .leading)
    }
}
