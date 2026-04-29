import SwiftUI

struct BeforeAfterStep: View {
    let onNext: () -> Void

    @State private var revealProgress: CGFloat = 0
    @State private var showAfter: Bool = false
    @State private var pulse: Bool = false
    @State private var sliderX: CGFloat = 0.5
    @State private var phase: Int = 0

    private static let beforeURL = URL(string: "https://r2-pub.rork.com/generated-images/aec1d234-371a-4aaa-9ad2-f37471e5cda5.png")!
    private static let afterURL = URL(string: "https://r2-pub.rork.com/generated-images/f6b946c0-5e75-49ed-93ea-1dd91b534ffa.png")!

    var body: some View {
        OnboardingScaffold(
            eyebrow: "ビフォー & アフター",
            title: "同じ人でも、\nここまで変わります。",
            subtitle: "実際の変身例。スワイプで比較してみてください。",
            content: {
                VStack(spacing: 18) {
                    comparisonCard
                    statsBadges
                    insightCard
                }
            },
            footer: {
                OnboardingPrimaryButton(title: "次へ", action: onNext)
            }
        )
        .onAppear {
            startSequence()
        }
    }

    // MARK: - Comparison

    private var comparisonCard: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Bottom: AFTER
                photoLayer(url: Self.afterURL, isAfter: true)
                    .frame(width: w, height: h)

                // Top: BEFORE — clipped to slider position
                photoLayer(url: Self.beforeURL, isAfter: false)
                    .frame(width: w, height: h)
                    .mask(
                        Rectangle()
                            .frame(width: w * sliderX, height: h)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )

                // Divider line
                Rectangle()
                    .fill(.white)
                    .frame(width: 3, height: h)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .position(x: w * sliderX, y: h / 2)

                // Drag handle
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .black))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundStyle(Theme.ink)
                }
                .position(x: w * sliderX, y: h / 2)

                // Labels
                Text("BEFORE")
                    .font(.mikotoLabel(10, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                    .position(x: 50, y: 24)

                Text("AFTER")
                    .font(.mikotoLabel(10, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.coral))
                    .position(x: w - 46, y: 24)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = max(0.05, min(0.95, value.location.x / w))
                        sliderX = x
                    }
            )
        }
        .frame(height: 360)
        .clipShape(.rect(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white, lineWidth: 4)
        )
        .shadow(color: Theme.coral.opacity(0.25), radius: 18, y: 10)
    }

    private var statsBadges: some View {
        HStack(spacing: 10) {
            statBadge(value: "+312%", label: "好感度", color: Theme.coral)
            statBadge(value: "+5x", label: "閲覧数", color: Theme.lavender)
            statBadge(value: "+78%", label: "マッチ率", color: Theme.tangerine)
        }
    }

    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.mikotoDisplay(18, weight: .black))
                .foregroundStyle(color)
            Text(label)
                .font(.mikotoLabel(10, weight: .heavy))
                .foregroundStyle(Theme.inkSubtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(color.opacity(0.4), lineWidth: 1.5)
        )
    }

    private var insightCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.popGradient))
            VStack(alignment: .leading, spacing: 4) {
                Text("同じあなたを、最高の見せ方で。")
                    .font(.mikotoSans(13, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("AIが顔・表情・光・背景を整え、あなたらしさを保ったまま自然に魅力を引き出します。")
                    .font(.mikotoSans(12, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    @ViewBuilder
    private func photoLayer(url: URL, isAfter: Bool) -> some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.4))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(isAfter && pulse ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulse)
            case .empty:
                ZStack {
                    LinearGradient(
                        colors: isAfter
                            ? [Color(red: 1.00, green: 0.84, blue: 0.78), Color(red: 0.98, green: 0.70, blue: 0.72)]
                            : [Color(red: 0.30, green: 0.32, blue: 0.28), Color(red: 0.20, green: 0.18, blue: 0.18)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
            case .failure:
                LinearGradient(
                    colors: isAfter
                        ? [Color(red: 1.00, green: 0.84, blue: 0.78), Color(red: 0.98, green: 0.70, blue: 0.72)]
                        : [Color(red: 0.30, green: 0.32, blue: 0.28), Color(red: 0.20, green: 0.18, blue: 0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            @unknown default:
                Color.gray
            }
        }
    }

    // MARK: - Animation sequence

    private func startSequence() {
        // Cycle through "bad photo" phases
        Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                phase = (phase + 1) % 4
            }
        }

        // Auto-reveal animation
        withAnimation(.easeInOut(duration: 1.4).delay(0.4)) {
            sliderX = 0.18
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 1.4)) {
                sliderX = 0.82
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                sliderX = 0.5
            }
        }

        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }
}

// MARK: - BEFORE portrait (intentionally bad)

private struct BeforePortrait: View {
    let phase: Int

    var body: some View {
        ZStack {
            // Messy background — clutter colors
            LinearGradient(
                colors: [
                    Color(red: 0.30, green: 0.32, blue: 0.28),
                    Color(red: 0.45, green: 0.40, blue: 0.34),
                    Color(red: 0.25, green: 0.22, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Background clutter
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.25))
                        .frame(
                            width: CGFloat([20, 35, 45, 28, 50, 22, 38, 30][i]),
                            height: CGFloat([60, 80, 50, 90, 40, 70, 55, 65][i])
                        )
                        .rotationEffect(.degrees([8, -12, 4, 15, -8, 6, -3, 10][i]))
                        .offset(
                            x: CGFloat([-130, -90, 110, 130, -100, 100, -140, 130][i]),
                            y: CGFloat([-80, -100, -90, 60, 80, -70, 50, 80][i])
                        )
                }
            }
            .blur(radius: 1)

            // Bad portrait
            badPortrait
                .blur(radius: phase == 0 ? 6 : (phase == 1 ? 0.5 : (phase == 2 ? 2 : 1)))
                .scaleEffect(phase == 2 ? 1.08 : 1.0)
                .rotationEffect(.degrees(phase == 3 ? -8 : 0))
                .offset(x: phase == 3 ? 12 : 0, y: phase == 1 ? 8 : 0)

            // Underexposure overlay
            Color.black.opacity(0.15)

            // Yellow tint (bad lighting)
            Color(red: 0.95, green: 0.85, blue: 0.4).opacity(0.10)
                .blendMode(.multiply)
        }
    }

    @ViewBuilder
    private var badPortrait: some View {
        let skin = Color(red: 0.78, green: 0.62, blue: 0.55)

        ZStack {
            // Body / shoulders — slouched
            Path { p in
                p.move(to: CGPoint(x: 60, y: 360))
                p.addQuadCurve(to: CGPoint(x: 280, y: 360), control: CGPoint(x: 170, y: 280))
                p.addLine(to: CGPoint(x: 280, y: 400))
                p.addLine(to: CGPoint(x: 60, y: 400))
                p.closeSubpath()
            }
            .fill(Color(red: 0.40, green: 0.35, blue: 0.30))
            .offset(x: -10, y: 10)

            // Neck
            RoundedRectangle(cornerRadius: 6)
                .fill(skin.opacity(0.85))
                .frame(width: 38, height: 40)
                .offset(x: -4, y: 100)

            // Head — slightly tilted/off-center
            Ellipse()
                .fill(skin)
                .frame(width: 130, height: 160)
                .offset(x: -8, y: 30)
                .rotationEffect(.degrees(phase == 3 ? -6 : -3))

            // Messy hair
            Path { p in
                p.move(to: CGPoint(x: -20, y: 0))
                p.addQuadCurve(to: CGPoint(x: 100, y: -20), control: CGPoint(x: 40, y: -50))
                p.addQuadCurve(to: CGPoint(x: 90, y: 80), control: CGPoint(x: 130, y: 30))
                p.addQuadCurve(to: CGPoint(x: -20, y: 60), control: CGPoint(x: -40, y: 40))
                p.closeSubpath()
            }
            .fill(Color(red: 0.18, green: 0.12, blue: 0.10))
            .offset(x: -40, y: -30)

            // Eyes — squinted / closed
            HStack(spacing: 24) {
                Capsule()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 14, height: phase == 1 ? 1.5 : 3)
                Capsule()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 14, height: phase == 1 ? 1.5 : 3)
            }
            .offset(x: -8, y: 14)

            // Awkward mouth
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                if phase == 0 {
                    p.addQuadCurve(to: CGPoint(x: 30, y: 0), control: CGPoint(x: 15, y: 8))
                } else if phase == 2 {
                    p.addLine(to: CGPoint(x: 30, y: 0))
                } else {
                    p.addQuadCurve(to: CGPoint(x: 30, y: 4), control: CGPoint(x: 15, y: -4))
                }
            }
            .stroke(Color(red: 0.55, green: 0.20, blue: 0.20), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .offset(x: -20, y: 60)
        }
        .frame(width: 200, height: 280)
    }
}

// MARK: - AFTER portrait (clean & polished)

private struct AfterPortrait: View {
    let pulse: Bool

    var body: some View {
        ZStack {
            // Clean studio gradient background
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.84, blue: 0.78),
                    Color(red: 0.98, green: 0.70, blue: 0.72),
                    Color(red: 0.85, green: 0.60, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft glow halo
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .scaleEffect(pulse ? 1.05 : 0.95)

            // Clean portrait
            cleanPortrait

            // Bokeh sparkles
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: CGFloat([8, 5, 10, 6, 7, 9][i]))
                    .blur(radius: 1)
                    .offset(
                        x: CGFloat([-110, 120, -90, 100, -130, 130][i]),
                        y: CGFloat([-110, -80, 120, 100, 60, -130][i])
                    )
            }

            // Top highlight glow
            LinearGradient(
                colors: [Color.white.opacity(0.25), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    @ViewBuilder
    private var cleanPortrait: some View {
        let skin = Color(red: 0.95, green: 0.82, blue: 0.74)

        ZStack {
            // Confident shoulders
            Path { p in
                p.move(to: CGPoint(x: 30, y: 340))
                p.addQuadCurve(to: CGPoint(x: 310, y: 340), control: CGPoint(x: 170, y: 250))
                p.addLine(to: CGPoint(x: 310, y: 400))
                p.addLine(to: CGPoint(x: 30, y: 400))
                p.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.18, green: 0.16, blue: 0.22), Color(red: 0.10, green: 0.08, blue: 0.14)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .offset(y: 10)

            // Neck
            RoundedRectangle(cornerRadius: 8)
                .fill(skin)
                .frame(width: 44, height: 44)
                .offset(y: 100)

            // Head — centered, well-lit
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [skin, Color(red: 0.88, green: 0.74, blue: 0.66)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 170)
                .offset(y: 30)

            // Highlight on cheek
            Ellipse()
                .fill(Color.white.opacity(0.3))
                .frame(width: 50, height: 70)
                .blur(radius: 14)
                .offset(x: -28, y: 30)

            // Styled hair
            Path { p in
                p.move(to: CGPoint(x: 0, y: 30))
                p.addQuadCurve(to: CGPoint(x: 130, y: 0), control: CGPoint(x: 65, y: -40))
                p.addQuadCurve(to: CGPoint(x: 140, y: 90), control: CGPoint(x: 170, y: 40))
                p.addQuadCurve(to: CGPoint(x: 100, y: 60), control: CGPoint(x: 120, y: 50))
                p.addQuadCurve(to: CGPoint(x: 30, y: 60), control: CGPoint(x: 65, y: 35))
                p.addQuadCurve(to: CGPoint(x: 0, y: 90), control: CGPoint(x: -10, y: 70))
                p.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.22, green: 0.14, blue: 0.10), Color(red: 0.14, green: 0.08, blue: 0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .offset(x: -30, y: -30)

            // Confident eyes
            HStack(spacing: 26) {
                ZStack {
                    Ellipse().fill(Color.white).frame(width: 14, height: 8)
                    Circle().fill(Color(red: 0.25, green: 0.18, blue: 0.12)).frame(width: 7, height: 7)
                }
                ZStack {
                    Ellipse().fill(Color.white).frame(width: 14, height: 8)
                    Circle().fill(Color(red: 0.25, green: 0.18, blue: 0.12)).frame(width: 7, height: 7)
                }
            }
            .offset(y: 12)

            // Eyebrows
            HStack(spacing: 30) {
                Capsule().fill(Color(red: 0.18, green: 0.12, blue: 0.08)).frame(width: 18, height: 3)
                Capsule().fill(Color(red: 0.18, green: 0.12, blue: 0.08)).frame(width: 18, height: 3)
            }
            .offset(y: -6)

            // Warm smile
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(to: CGPoint(x: 36, y: 0), control: CGPoint(x: 18, y: 10))
            }
            .stroke(Color(red: 0.60, green: 0.25, blue: 0.30), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .offset(x: -18, y: 60)

            // Subtle blush
            HStack(spacing: 50) {
                Circle().fill(Color(red: 1.0, green: 0.55, blue: 0.55).opacity(0.35)).frame(width: 22, height: 22).blur(radius: 6)
                Circle().fill(Color(red: 1.0, green: 0.55, blue: 0.55).opacity(0.35)).frame(width: 22, height: 22).blur(radius: 6)
            }
            .offset(y: 40)
        }
        .frame(width: 220, height: 300)
    }
}
