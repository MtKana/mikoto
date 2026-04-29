import SwiftUI

// Editorial abstract artworks — refined color blocking, soft shapes,
// no cartoon characters or smiley suns. Each style has its own mature mood.

struct StyleArtwork: View {
    let style: PhotoStyle

    var body: some View {
        ZStack {
            palette.bg
            shapes
            PaperGrain(density: 240)
        }
    }

    struct Palette {
        let bg: Color
        let primary: Color
        let secondary: Color
        let accent: Color
        let ink: Color
    }

    var palette: Palette {
        switch style.id {
        case "seiso":
            return .init(
                bg: Color(red: 0.969, green: 0.949, blue: 0.910),
                primary: Theme.butter,
                secondary: Theme.blush,
                accent: Theme.terracotta,
                ink: Theme.ink
            )
        case "cafe":
            return .init(
                bg: Color(red: 0.741, green: 0.604, blue: 0.471),
                primary: Color(red: 0.412, green: 0.275, blue: 0.180),
                secondary: Color(red: 0.890, green: 0.792, blue: 0.659),
                accent: Theme.butter,
                ink: Color(red: 0.290, green: 0.176, blue: 0.110)
            )
        case "sakura":
            return .init(
                bg: Color(red: 0.965, green: 0.890, blue: 0.875),
                primary: Color(red: 0.918, green: 0.722, blue: 0.722),
                secondary: Theme.blush,
                accent: Theme.terracotta,
                ink: Theme.terracottaDeep
            )
        case "office":
            return .init(
                bg: Color(red: 0.851, green: 0.831, blue: 0.792),
                primary: Color(red: 0.231, green: 0.235, blue: 0.286),
                secondary: Theme.clay,
                accent: Theme.ochre,
                ink: Theme.ink
            )
        case "yuhi":
            return .init(
                bg: Color(red: 0.957, green: 0.722, blue: 0.510),
                primary: Theme.terracotta,
                secondary: Theme.terracottaDeep,
                accent: Theme.butter,
                ink: Color(red: 0.345, green: 0.165, blue: 0.118)
            )
        case "urban":
            return .init(
                bg: Color(red: 0.227, green: 0.180, blue: 0.196),
                primary: Theme.terracotta,
                secondary: Theme.ochre,
                accent: Color(red: 0.961, green: 0.910, blue: 0.831),
                ink: .white.opacity(0.95)
            )
        case "ryokan":
            return .init(
                bg: Color(red: 0.808, green: 0.804, blue: 0.722),
                primary: Theme.sage,
                secondary: Theme.terracotta,
                accent: Theme.butter,
                ink: Theme.ink
            )
        case "minimal":
            return .init(
                bg: Color(red: 0.918, green: 0.886, blue: 0.820),
                primary: Theme.clay,
                secondary: Theme.terracotta,
                accent: Theme.ink,
                ink: Theme.ink
            )
        case "custom":
            let primary = style.swatch.first ?? Theme.coral
            let secondary = style.swatch.dropFirst().first ?? Theme.lavender
            return .init(
                bg: primary.opacity(0.28),
                primary: primary,
                secondary: secondary,
                accent: Theme.sunshine,
                ink: Theme.ink
            )
        default:
            return .init(bg: Theme.bone, primary: Theme.terracotta, secondary: Theme.clay, accent: Theme.ochre, ink: Theme.ink)
        }
    }

    @ViewBuilder
    private var shapes: some View {
        GeometryReader { geo in
            switch style.id {
            case "seiso":   SeisoShape(p: palette, size: geo.size)
            case "cafe":    CafeShape(p: palette, size: geo.size)
            case "sakura":  SakuraShape(p: palette, size: geo.size)
            case "office":  OfficeShape(p: palette, size: geo.size)
            case "yuhi":    YuhiShape(p: palette, size: geo.size)
            case "urban":   UrbanShape(p: palette, size: geo.size)
            case "ryokan":  RyokanShape(p: palette, size: geo.size)
            case "minimal": MinimalShape(p: palette, size: geo.size)
            case "custom":  CustomShape(p: palette, size: geo.size)
            default: EmptyView()
            }
        }
    }
}

// MARK: - Per-style refined compositions

private struct SeisoShape: View {
    let p: StyleArtwork.Palette
    let size: CGSize
    var body: some View {
        ZStack {
            // Soft sun disk, top
            Circle()
                .fill(p.primary)
                .frame(width: size.width * 0.78, height: size.width * 0.78)
                .offset(y: -size.height * 0.18)
                .blur(radius: 0.5)
            // Horizon line
            Rectangle()
                .fill(p.ink.opacity(0.25))
                .frame(width: size.width * 0.55, height: 0.6)
                .offset(y: size.height * 0.30)
            // Small accent dot
            Circle()
                .fill(p.accent)
                .frame(width: 6, height: 6)
                .offset(x: -size.width * 0.30, y: size.height * 0.30)
        }
    }
}

private struct CafeShape: View {
    let p: StyleArtwork.Palette
    let size: CGSize
    var body: some View {
        ZStack {
            // Two layered arches
            Capsule()
                .fill(p.secondary)
                .frame(width: size.width * 0.95, height: size.width * 0.95)
                .offset(y: size.height * 0.42)
            Capsule()
                .fill(p.primary)
                .frame(width: size.width * 0.62, height: size.width * 0.62)
                .offset(y: size.height * 0.32)
            Circle()
                .fill(p.accent)
                .frame(width: 8, height: 8)
                .offset(x: size.width * 0.28, y: -size.height * 0.30)
        }
    }
}

private struct SakuraShape: View {
    let p: StyleArtwork.Palette
    let size: CGSize
    var body: some View {
        ZStack {
            // Soft scattered circles like abstracted petals
            let positions: [(CGFloat, CGFloat, CGFloat)] = [
                (-0.28, -0.22, 0.18),
                (0.18, -0.30, 0.12),
                (-0.10, 0.10, 0.28),
                (0.30, 0.18, 0.16),
                (-0.32, 0.30, 0.10),
                (0.05, 0.36, 0.08)
            ]
            ForEach(0..<positions.count, id: \.self) { i in
                let (x, y, s) = positions[i]
                Circle()
                    .fill(i.isMultiple(of: 2) ? p.primary : p.secondary)
                    .frame(width: size.width * s, height: size.width * s)
                    .offset(x: size.width * x, y: size.height * y)
                    .opacity(0.92)
            }
            Circle()
                .fill(p.accent)
                .frame(width: 5, height: 5)
                .offset(x: size.width * 0.32, y: -size.height * 0.34)
        }
    }
}

private struct OfficeShape: View {
    let p: StyleArtwork.Palette
    let size: CGSize
    var body: some View {
        ZStack {
            // Architectural verticals
            HStack(spacing: size.width * 0.06) {
                Rectangle().fill(p.primary).frame(width: 2)
                Rectangle().fill(p.primary).frame(width: 2)
                Rectangle().fill(p.primary).frame(width: 2)
                Rectangle().fill(p.primary).frame(width: 2)
            }
            .frame(height: size.height * 0.82)
            // Sun behind
            Circle()
                .fill(p.secondary)
                .frame(width: size.width * 0.55, height: size.width * 0.55)
                .offset(x: size.width * 0.18, y: -size.height * 0.10)
                .blendMode(.multiply)
            Circle()
                .fill(p.accent)
                .frame(width: 6, height: 6)
                .offset(x: -size.width * 0.32, y: size.height * 0.34)
        }
    }
}

private struct YuhiShape: View {
    let p: StyleArtwork.Palette
    let size: CGSize
    var body: some View {
        ZStack {
            // Half-disk sun on horizon
            Circle()
                .fill(p.primary)
                .frame(width: size.width * 0.95, height: size.width * 0.95)
                .offset(y: size.height * 0.45)
            // Thin gradient horizon glow
            Rectangle()
                .fill(LinearGradient(
                    colors: [p.secondary.opacity(0), p.secondary.opacity(0.6), p.secondary.opacity(0)],
                    startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .offset(y: -size.height * 0.02)
            Circle()
                .fill(p.accent)
                .frame(width: 5, height: 5)
                .offset(x: -size.width * 0.32, y: -size.height * 0.32)
        }
    }
}

private struct UrbanShape: View {
    let p: StyleArtwork.Palette
    let size: CGSize
    var body: some View {
        ZStack {
            // Skyline silhouette
            HStack(alignment: .bottom, spacing: 4) {
                Rectangle().fill(p.primary).frame(width: 18, height: size.height * 0.45)
                Rectangle().fill(p.secondary).frame(width: 22, height: size.height * 0.30)
                Rectangle().fill(p.primary.opacity(0.85)).frame(width: 14, height: size.height * 0.55)
                Rectangle().fill(p.secondary).frame(width: 20, height: size.height * 0.38)
                Rectangle().fill(p.primary).frame(width: 24, height: size.height * 0.48)
            }
            .offset(y: size.height * 0.22)
            // Single moon disk
            Circle()
                .strokeBorder(p.accent.opacity(0.65), lineWidth: 1)
                .frame(width: size.width * 0.32, height: size.width * 0.32)
                .offset(x: size.width * 0.22, y: -size.height * 0.26)
            Circle()
                .fill(p.accent)
                .frame(width: 4, height: 4)
                .offset(x: -size.width * 0.30, y: -size.height * 0.20)
        }
    }
}

private struct RyokanShape: View {
    let p: StyleArtwork.Palette
    let size: CGSize
    var body: some View {
        ZStack {
            // Layered low hills
            Capsule()
                .fill(p.primary.opacity(0.6))
                .frame(width: size.width * 1.5, height: size.height * 0.7)
                .offset(y: size.height * 0.55)
            Capsule()
                .fill(p.primary)
                .frame(width: size.width * 1.3, height: size.height * 0.55)
                .offset(y: size.height * 0.62)
            // Sun disk
            Circle()
                .fill(p.secondary)
                .frame(width: size.width * 0.36, height: size.width * 0.36)
                .offset(x: size.width * 0.18, y: -size.height * 0.18)
            Circle()
                .fill(p.accent)
                .frame(width: 5, height: 5)
                .offset(x: -size.width * 0.30, y: -size.height * 0.30)
        }
    }
}

private struct CustomShape: View {
    let p: StyleArtwork.Palette
    let size: CGSize
    var body: some View {
        ZStack {
            // Generic dreamy composition for the user's unique style
            Circle()
                .fill(p.primary)
                .frame(width: size.width * 0.72, height: size.width * 0.72)
                .offset(x: -size.width * 0.10, y: -size.height * 0.18)
                .blur(radius: 0.5)
            Circle()
                .fill(p.secondary)
                .frame(width: size.width * 0.50, height: size.width * 0.50)
                .offset(x: size.width * 0.22, y: size.height * 0.20)
                .blur(radius: 0.5)
            Capsule()
                .fill(p.accent.opacity(0.55))
                .frame(width: size.width * 0.55, height: 1.2)
                .offset(y: size.height * 0.32)
            Circle()
                .fill(p.accent)
                .frame(width: 6, height: 6)
                .offset(x: -size.width * 0.30, y: size.height * 0.32)
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(p.ink.opacity(0.5))
                .offset(x: size.width * 0.32, y: -size.height * 0.30)
        }
    }
}

private struct MinimalShape: View {
    let p: StyleArtwork.Palette
    let size: CGSize
    var body: some View {
        ZStack {
            // Single offset circle, single hairline — Aēsop minimal
            Circle()
                .fill(p.primary)
                .frame(width: size.width * 0.42, height: size.width * 0.42)
                .offset(x: size.width * 0.10, y: -size.height * 0.05)
            Rectangle()
                .fill(p.accent.opacity(0.4))
                .frame(width: size.width * 0.55, height: 0.6)
                .offset(x: -size.width * 0.10, y: size.height * 0.20)
            Circle()
                .fill(p.secondary)
                .frame(width: 5, height: 5)
                .offset(x: -size.width * 0.22, y: size.height * 0.30)
        }
    }
}
