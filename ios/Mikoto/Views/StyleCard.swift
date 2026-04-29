import SwiftUI

struct StyleCard: View {
    let style: PhotoStyle
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color.clear
                .aspectRatio(0.82, contentMode: .fit)
                .overlay {
                    StyleArtwork(style: style)
                        .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white, lineWidth: 3)
                )
                .shadow(color: style.swatch.first?.opacity(0.30) ?? .black.opacity(0.1), radius: 12, y: 6)
                .overlay(alignment: .topLeading) { numberTag }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: style.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.ink))
                        .padding(10)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(style.nameJP)
                    .font(.mikotoDisplay(18, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text(style.mood)
                    .font(.mikotoLabel(11, weight: .semibold))
                    .foregroundStyle(Theme.inkSubtle)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
    }

    private var numberTag: some View {
        Text("0\(index + 1)")
            .font(.mikotoDisplay(13, weight: .black))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(.white))
            .padding(10)
    }
}
