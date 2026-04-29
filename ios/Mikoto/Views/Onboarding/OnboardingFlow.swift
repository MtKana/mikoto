import SwiftUI

struct OnboardingFlow: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CreditStore.self) private var credits

    @State private var step: Int = 0
    private let totalSteps = 7

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                ZStack {
                    Group {
                        switch step {
                        case 0: SymptomsStep(onNext: next)
                        case 1: PainStep(onNext: next)
                        case 2: BeforeAfterStep(onNext: next)
                        case 3: FeaturesStep(onNext: next)
                        case 4: ReviewsStep(onNext: next)
                        case 5: CustomPlanStep(onNext: next)
                        case 6: WelcomeGiftStep(onFinish: finish)
                        default: EmptyView()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(step)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
            }
        }
    }

    private var backdrop: some View {
        ZStack {
            Theme.bone.ignoresSafeArea()
            Circle().fill(Theme.coral.opacity(0.25)).frame(width: 380, height: 380).blur(radius: 90).offset(x: -150, y: -300)
            Circle().fill(Theme.lavender.opacity(0.30)).frame(width: 360, height: 360).blur(radius: 90).offset(x: 160, y: 280)
            Circle().fill(Theme.sunshine.opacity(0.20)).frame(width: 280, height: 280).blur(radius: 80).offset(x: 180, y: -200)
        }
        .allowsHitTesting(false)
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.coral : Theme.ink.opacity(0.10))
                    .frame(height: 5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: step)
            }
        }
    }

    private func next() {
        if step < totalSteps - 1 {
            step += 1
        } else {
            finish()
        }
    }

    private func finish() {
        credits.grantWelcomeBonus()
        state.complete()
    }
}

// MARK: - Shared chrome

struct OnboardingScaffold<Content: View, Footer: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    EyebrowText(text: eyebrow, color: Theme.coral, size: 11)
                        .padding(.top, 18)
                    Text(title)
                        .font(.mikotoDisplay(28, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(.mikotoSans(15, weight: .medium))
                            .foregroundStyle(Theme.inkSoft)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    content()
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            footer()
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
                .padding(.top, 8)
        }
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.mikotoSans(16, weight: .heavy))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .heavy))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(enabled ? AnyShapeStyle(Theme.popGradient) : AnyShapeStyle(Theme.inkSubtle.opacity(0.4)))
            )
            .shadow(color: enabled ? Theme.coral.opacity(0.4) : .clear, radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
