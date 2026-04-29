import SwiftUI

struct CustomPlanStep: View {
    let onNext: () -> Void

    @Environment(OnboardingState.self) private var state
    @Environment(UserStyleStore.self) private var styleStore

    @State private var page: Int = -1
    @State private var progress: CGFloat = 0
    @State private var currentTip: Int = 0
    @State private var generated: UserStyleData?
    @State private var errorText: String?
    @State private var isLoading: Bool = false

    private let questions: [PersonalityQuestion] = [
        .init(
            tag: "ライフスタイル 1 / 4",
            title: "理想の休日の過ごし方は？",
            field: \.weekend,
            options: ["カフェでゆったり読書", "アウトドアで体を動かす", "家でゆっくり映画", "友達と賑やかに外出"]
        ),
        .init(
            tag: "ライフスタイル 2 / 4",
            title: "心惹かれる雰囲気は？",
            field: \.atmosphere,
            options: ["ナチュラル・素朴", "都会的・洗練", "ロマンティック・夢のある", "ミニマル・上品"]
        ),
        .init(
            tag: "ライフスタイル 3 / 4",
            title: "あなたを一言で表すと？",
            field: \.selfWord,
            options: ["優しい・穏やか", "情熱的・エネルギッシュ", "思慮深い・知的", "冒険好き・好奇心旺盛"]
        ),
        .init(
            tag: "ライフスタイル 4 / 4",
            title: "服装の好みは？",
            field: \.outfit,
            options: ["ベーシック・きれいめ", "個性的・トレンド感", "エレガント・クラシック", "カジュアル・リラックス"]
        )
    ]

    private let tips: [String] = [
        "あなたの回答を分析しています…",
        "感性とライフスタイルを読み解いています…",
        "世界に一つのスタイルを描いています…",
        "あなた専用のスタイルが完成しました ✦"
    ]

    var body: some View {
        ZStack {
            Group {
                if page < 0 {
                    introPage
                } else if page < questions.count {
                    questionPage(index: page)
                } else if generated == nil {
                    loadingPage
                } else {
                    revealPage
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(page)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: page)
        .alert("もう一度お試しください", isPresented: .constant(errorText != nil), actions: {
            Button("再試行") {
                errorText = nil
                Task { await runGeneration() }
            }
        }, message: {
            Text(errorText ?? "")
        })
    }

    // MARK: - Intro

    private var introPage: some View {
        OnboardingScaffold(
            eyebrow: "あなた専用のスタイル",
            title: "これから、あなた専用の\n写真スタイルを作ります。",
            subtitle: "より似合う一枚を描くため、これからいくつか質問をしていきます。直感で答えてください。",
            content: {
                VStack(spacing: 14) {
                    introCard(
                        number: "01",
                        icon: "text.bubble.fill",
                        color: Theme.coral,
                        title: "4つのかんたんな質問",
                        subtitle: "ライフスタイルや好みについて、選ぶだけ。所要時間は約30秒です。"
                    )
                    introCard(
                        number: "02",
                        icon: "sparkles",
                        color: Theme.lavender,
                        title: "AIがあなたを分析",
                        subtitle: "回答からあなたに最も似合う雰囲気・色・シーンを導き出します。"
                    )
                    introCard(
                        number: "03",
                        icon: "wand.and.stars",
                        color: Theme.tangerine,
                        title: "世界に一つのスタイルが完成",
                        subtitle: "名前付きのオリジナルスタイルが、ホームに永続的に追加されます。"
                    )
                }
            },
            footer: {
                OnboardingPrimaryButton(title: "質問を始める") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        page = 0
                    }
                }
            }
        )
    }

    private func introCard(number: String, icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(color)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(number)
                        .font(.mikotoLabel(10, weight: .black))
                        .tracking(1.0)
                        .foregroundStyle(color)
                    Text(title)
                        .font(.mikotoSans(14, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                }
                Text(subtitle)
                    .font(.mikotoSans(12, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }

    // MARK: - Question pages

    private func questionPage(index: Int) -> some View {
        let q = questions[index]
        return OnboardingScaffold(
            eyebrow: q.tag,
            title: q.title,
            subtitle: "あなただけのスタイルを描くため、もう少し教えてください。",
            content: {
                VStack(spacing: 12) {
                    ForEach(q.options, id: \.self) { option in
                        OptionRow(
                            text: option,
                            selected: state[keyPath: q.field] == option
                        ) {
                            select(option, for: q)
                        }
                    }
                }
            },
            footer: {
                EmptyView()
            }
        )
    }

    private func select(_ option: String, for q: PersonalityQuestion) {
        state[keyPath: q.field] = option
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if page < questions.count - 1 {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    page += 1
                }
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    page += 1
                }
                Task { await runGeneration() }
            }
        }
    }

    // MARK: - Loading

    private var loadingPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    EyebrowText(text: "あなた専用のプラン", color: Theme.coral, size: 11)
                        .padding(.top, 18)
                    Text("世界に一つだけの\nスタイルを描いています…")
                        .font(.mikotoDisplay(28, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(2)

                    ZStack {
                        Circle()
                            .strokeBorder(Theme.ink.opacity(0.06), lineWidth: 14)
                            .frame(width: 220, height: 220)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Theme.popGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(Int(progress * 100))")
                                .font(.mikotoDisplay(56, weight: .black))
                                .foregroundStyle(Theme.ink)
                                .contentTransition(.numericText())
                            Text("%")
                                .font(.mikotoLabel(13, weight: .heavy))
                                .foregroundStyle(Theme.inkSubtle)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(Theme.coral)
                        Text(tips[min(currentTip, tips.count - 1)])
                            .font(.mikotoSans(14, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.opacity)
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            OnboardingPrimaryButton(title: "作成中…", enabled: false) { }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
        }
        .onAppear {
            startLoadingAnimation()
        }
    }

    private func startLoadingAnimation() {
        progress = 0
        currentTip = 0
        withAnimation(.easeInOut(duration: 4.0)) {
            progress = 0.92
        }
        for (i, _) in tips.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 * Double(i)) {
                withAnimation { currentTip = min(i, tips.count - 1) }
            }
        }
    }

    private func runGeneration() async {
        isLoading = true
        do {
            let answers = state.answers()
            let result = try await UserStyleService.generate(answers: answers)
            await MainActor.run {
                styleStore.save(result)
                withAnimation(.easeOut(duration: 0.4)) {
                    progress = 1.0
                    currentTip = tips.count - 1
                }
                generated = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorText = (error as? LocalizedError)?.errorDescription ?? "通信エラーが発生しました。"
            }
        }
    }

    // MARK: - Reveal

    private var revealPage: some View {
        guard let data = generated else { return AnyView(EmptyView()) }
        let style = data.toStyle()

        return AnyView(
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        EyebrowText(text: "あなた専用のスタイル", color: Theme.coral, size: 11)
                            .padding(.top, 18)

                        Text("これが、あなただけの\n一枚の世界。")
                            .font(.mikotoDisplay(28, weight: .black))
                            .foregroundStyle(Theme.ink)
                            .lineSpacing(2)

                        Color.clear
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay {
                                StyleArtwork(style: style)
                                    .allowsHitTesting(false)
                            }
                            .clipShape(.rect(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(.white, lineWidth: 4)
                            )
                            .shadow(color: style.swatch.first?.opacity(0.35) ?? .black.opacity(0.1), radius: 18, y: 10)
                            .overlay(alignment: .topLeading) {
                                Text("ONLY FOR YOU")
                                    .font(.mikotoLabel(10, weight: .black))
                                    .tracking(0.8)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(Theme.popGradient))
                                    .padding(14)
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: style.symbol)
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .frame(width: 54, height: 54)
                                    .background(Circle().fill(Theme.ink))
                                    .padding(14)
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(data.nameJP)
                                    .font(.mikotoDisplay(38, weight: .black))
                                    .foregroundStyle(Theme.ink)
                                Text(data.nameRomaji)
                                    .font(.mikotoLabel(13, weight: .heavy))
                                    .foregroundStyle(Theme.inkSubtle)
                            }
                            Text(data.tagline)
                                .font(.mikotoSans(15, weight: .heavy))
                                .foregroundStyle(Theme.coral)
                            Text(data.mood)
                                .font(.mikotoLabel(11, weight: .heavy))
                                .tracking(0.4)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Theme.popGradient))
                                .padding(.top, 4)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(Theme.coral)
                                    .frame(width: 4, height: 18)
                                    .clipShape(.rect(cornerRadius: 2))
                                Text("なぜあなたに合うのか")
                                    .font(.mikotoDisplay(16, weight: .heavy))
                                    .foregroundStyle(Theme.ink)
                            }
                            Text(data.explanation)
                                .font(.mikotoSans(14, weight: .medium))
                                .foregroundStyle(Theme.inkSoft)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.white)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(Theme.coral)
                                Text("撮影シーン")
                                    .font(.mikotoSans(12, weight: .heavy))
                                    .foregroundStyle(Theme.coral)
                            }
                            Text(data.description)
                                .font(.mikotoSans(13, weight: .medium))
                                .foregroundStyle(Theme.inkSoft)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.sunshine.opacity(0.18))
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                OnboardingPrimaryButton(title: "このスタイルで始める", action: onNext)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                    .padding(.top, 8)
            }
        )
    }
}

private struct PersonalityQuestion {
    let tag: String
    let title: String
    let field: ReferenceWritableKeyPath<OnboardingState, String>
    let options: [String]
}

private struct OptionRow: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? Color.clear : Theme.ink.opacity(0.2), lineWidth: 2)
                    if selected {
                        Circle().fill(Theme.popGradient)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 26, height: 26)

                Text(text)
                    .font(.mikotoSans(15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selected ? Theme.coral : Theme.ink.opacity(0.08), lineWidth: selected ? 2 : 1)
            )
            .shadow(color: selected ? Theme.coral.opacity(0.20) : .black.opacity(0.04), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }
}
