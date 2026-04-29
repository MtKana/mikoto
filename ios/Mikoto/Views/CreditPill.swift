import SwiftUI

struct CreditPill: View {
    let balance: Int
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .heavy))
                Text("\(balance)")
                    .font(.mikotoDisplay(13, weight: .black))
                Text("クレジット")
                    .font(.mikotoLabel(10, weight: .heavy))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Theme.popGradient))
            .shadow(color: Theme.coral.opacity(0.35), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}
