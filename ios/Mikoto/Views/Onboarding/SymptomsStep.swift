import SwiftUI

struct SymptomsStep: View {
    let onNext: () -> Void
    @Environment(OnboardingState.self) private var state

    @State private var page: Int = 0

    private let concerns: [(String, String)] = [
        ("camera.metering.spot", "顔がぼやけて見える"),
        ("face.dashed", "表情が硬い・不自然"),
        ("figure.stand", "姿勢や角度が悪い"),
        ("photo.stack", "背景がごちゃついている"),
        ("tshirt.fill", "服装に自信がない"),
        ("sun.max.fill", "光が暗い・逆光"),
        ("hand.thumbsdown.fill", "古い写真しかない"),
        ("eye.slash.fill", "そもそも自分の写真が嫌い")
    ]

    var body: some View {
        ZStack {
            Group {
                switch page {
                case 0: appsQuestion
                case 1: confidenceQuestion
                default: concernsQuestion
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(page)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: page)
    }

    // MARK: - Q1: dating apps

    private var appsQuestion: some View {
        OnboardingScaffold(
            eyebrow: "質問 1 / 3",
            title: "マッチングアプリを\n使っていますか？",
            subtitle: "あなたに合った提案をするため、教えてください。",
            content: {
                VStack(spacing: 12) {
                    ForEach(["はい、使っている", "登録予定・検討中", "使っていない"], id: \.self) { opt in
                        ChoiceRow(text: opt, selected: state.usesDatingApps == opt) {
                            state.usesDatingApps = opt
                            advance()
                        }
                    }
                }
            },
            footer: { EmptyView() }
        )
    }

    // MARK: - Q2: confidence

    private var confidenceQuestion: some View {
        OnboardingScaffold(
            eyebrow: "質問 2 / 3",
            title: "今のプロフィール写真に\n自信はありますか？",
            subtitle: "正直な気持ちで大丈夫です。",
            content: {
                VStack(spacing: 12) {
                    ForEach(confidenceOptions, id: \.0) { row in
                        ConfidenceRow(emoji: row.1, text: row.0, selected: state.iconConfidence == row.0) {
                            state.iconConfidence = row.0
                            advance()
                        }
                    }
                }
            },
            footer: { EmptyView() }
        )
    }

    private var confidenceOptions: [(String, String)] {
        [
            ("とても自信がある", "😎"),
            ("まあまあ自信がある", "🙂"),
            ("あまり自信がない", "😅"),
            ("全く自信がない", "😞")
        ]
    }

    // MARK: - Q3: concerns

    private var concernsQuestion: some View {
        OnboardingScaffold(
            eyebrow: "質問 3 / 3",
            title: "プロフィール写真の\n悩みは何ですか？",
            subtitle: "当てはまるものをすべて選んでください。複数選択OK。",
            content: {
                VStack(spacing: 10) {
                    ForEach(0..<concerns.count, id: \.self) { i in
                        let item = concerns[i]
                        ConcernRow(
                            icon: item.0,
                            text: item.1,
                            selected: state.iconConcerns.contains(item.1)
                        ) {
                            if state.iconConcerns.contains(item.1) {
                                state.iconConcerns.remove(item.1)
                            } else {
                                state.iconConcerns.insert(item.1)
                            }
                        }
                    }
                }
            },
            footer: {
                OnboardingPrimaryButton(
                    title: "次へ進む",
                    enabled: !state.iconConcerns.isEmpty,
                    action: onNext
                )
            }
        )
    }

    private func advance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                if page == 0 && state.usesDatingApps == "使っていない" {
                    // skip the confidence question if they don't use dating apps yet
                    page = 2
                } else if page < 2 {
                    page += 1
                }
            }
        }
    }
}

// MARK: - Rows

private struct ChoiceRow: View {
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
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
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

private struct ConfidenceRow: View {
    let emoji: String
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(selected ? Theme.coral.opacity(0.18) : Theme.bone))
                Text(text)
                    .font(.mikotoSans(15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(selected ? Theme.coral : Theme.ink.opacity(0.2))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
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

private struct ConcernRow: View {
    let icon: String
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(selected ? Theme.coral : Theme.inkSubtle.opacity(0.3)))
                Text(text)
                    .font(.mikotoSans(14, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(selected ? Theme.coral : Theme.ink.opacity(0.2))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? Theme.coral.opacity(0.6) : Theme.ink.opacity(0.06), lineWidth: selected ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }
}
