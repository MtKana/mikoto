import SwiftUI

// MARK: - Vibrant Japanese Pop palette
// City Pop × ネオン × 昭和レトロ — bold, bright, playful but mature.
enum Theme {
    // Surfaces
    static let cream = Color(red: 1.000, green: 0.976, blue: 0.937)       // FFF9EF
    static let bone = Color(red: 1.000, green: 0.961, blue: 0.910)        // FFF5E8
    static let card = Color.white
    static let paper = Color(red: 1.000, green: 0.984, blue: 0.961)

    // Ink
    static let ink = Color(red: 0.110, green: 0.090, blue: 0.180)         // 1C1730
    static let inkSoft = Color(red: 0.231, green: 0.196, blue: 0.314)
    static let inkSubtle = Color(red: 0.443, green: 0.412, blue: 0.529)

    // Pop accents — vibrant, dating-app energy
    static let coral = Color(red: 1.000, green: 0.388, blue: 0.439)       // FF6370 ホットピンク
    static let pink = Color(red: 1.000, green: 0.557, blue: 0.722)        // FF8EB8
    static let tangerine = Color(red: 1.000, green: 0.522, blue: 0.227)   // FF853A 鮮やかオレンジ
    static let sunshine = Color(red: 1.000, green: 0.812, blue: 0.231)    // FFCF3B イエロー
    static let mint = Color(red: 0.439, green: 0.871, blue: 0.667)        // 70DEAA
    static let sky = Color(red: 0.298, green: 0.671, blue: 1.000)         // 4CABFF
    static let lavender = Color(red: 0.624, green: 0.518, blue: 1.000)    // 9F84FF
    static let magenta = Color(red: 0.945, green: 0.275, blue: 0.643)     // F146A4

    // Aliases for compatibility
    static let terracotta = coral
    static let terracottaDeep = magenta
    static let clay = tangerine
    static let ochre = sunshine
    static let butter = Color(red: 1.000, green: 0.918, blue: 0.620)
    static let blush = pink
    static let sage = mint
    static let ivory = cream
    static let linen = Color(red: 1.000, green: 0.941, blue: 0.894)

    // Lines
    static let line = Color(red: 0.110, green: 0.090, blue: 0.180).opacity(0.18)
    static let hairline = Color(red: 0.110, green: 0.090, blue: 0.180).opacity(0.08)

    // Signature gradient
    static let popGradient = LinearGradient(
        colors: [coral, magenta, lavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let sunsetGradient = LinearGradient(
        colors: [sunshine, tangerine, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
extension Font {
    static func mikotoSerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mikotoSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mikotoLabel(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mikotoDisplay(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Wordmark (logo)
struct Wordmark: View {
    var size: CGFloat = 14
    var color: Color? = nil

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.popGradient)
                .frame(width: size * 0.95, height: size * 0.95)
                .overlay(
                    Text("M")
                        .font(.system(size: size * 0.62, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                )
            Text("ミコト")
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .tracking(size * 0.05)
                .foregroundStyle(color ?? Theme.ink)
        }
    }
}

// MARK: - Hairline
struct Hairline: View {
    var color: Color = Theme.line
    var body: some View {
        Rectangle().fill(color).frame(height: 1)
    }
}

// MARK: - Eyebrow label (small caps tag)
struct Eyebrow: View {
    let text: String
    var color: Color = Theme.coral
    var size: CGFloat = 11

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .tracking(size * 0.10)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(color)
            )
    }
}

// MARK: - Plain eyebrow (no pill)
struct EyebrowText: View {
    let text: String
    var color: Color = Theme.coral
    var size: CGFloat = 11

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .tracking(size * 0.12)
            .foregroundStyle(color)
    }
}

// MARK: - Subtle paper grain
struct PaperGrain: View {
    var density: Int = 220
    var body: some View {
        Canvas { ctx, size in
            for _ in 0..<density {
                let x = Double.random(in: 0...size.width)
                let y = Double.random(in: 0...size.height)
                let r = Double.random(in: 0.4...1.0)
                let a = Double.random(in: 0.02...0.05)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(.black.opacity(a))
                )
            }
        }
        .blendMode(.multiply)
        .allowsHitTesting(false)
    }
}
