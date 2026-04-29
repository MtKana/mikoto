import SwiftUI

struct ResultView: View {
    let photo: GeneratedPhoto
    let style: PhotoStyle

    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false
    @State private var savedToggle = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                resultImage
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                titleBlock
                    .padding(.horizontal, 22)
                    .padding(.top, 22)

                actionRow
                    .padding(.horizontal, 22)
                    .padding(.top, 22)

                tip
                    .padding(.horizontal, 22)
                    .padding(.top, 22)
                    .padding(.bottom, 40)
            }
        }
        .background(Theme.bone.ignoresSafeArea())
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Eyebrow(text: "完成しました", color: Theme.mint)
            }
        }
        .toolbarBackground(Theme.bone, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showShare) {
            if let img = photo.uiImage {
                ShareSheet(items: [img])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var resultImage: some View {
        Group {
            if let img = photo.uiImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white, lineWidth: 4)
                    )
                    .shadow(color: Theme.coral.opacity(0.20), radius: 24, y: 12)
            } else {
                Color.clear.frame(height: 300)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: style.mood, color: Theme.coral)
                .fixedSize()
            Text(style.nameJP)
                .font(.mikotoDisplay(30, weight: .black))
                .foregroundStyle(Theme.ink)
            Text(style.tagline)
                .font(.mikotoSans(14, weight: .heavy))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            ActionButton(
                icon: savedToggle ? "checkmark" : "square.and.arrow.down.fill",
                label: savedToggle ? "保存済み" : "保存する",
                primary: true
            ) {
                if let img = photo.uiImage {
                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                    withAnimation(.spring) { savedToggle = true }
                }
            }
            .sensoryFeedback(.success, trigger: savedToggle)

            ActionButton(
                icon: "square.and.arrow.up.fill",
                label: "シェア",
                primary: false
            ) {
                showShare = true
            }
        }
    }

    private var tip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11, weight: .heavy))
                Text("プロフィールのコツ")
                    .font(.mikotoSans(12, weight: .heavy))
            }
            .foregroundStyle(Theme.coral)

            Text("この一枚に、自然な笑顔の写真と全身写真を組み合わせて。\n10枚並べるより、3枚の厳選写真の方が好印象です。")
                .font(.mikotoSans(13, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.pink.opacity(0.18))
        )
    }
}

private struct ActionButton: View {
    let icon: String
    let label: String
    let primary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .heavy))
                Text(label)
                    .font(.mikotoSans(15, weight: .heavy))
            }
            .foregroundStyle(primary ? .white : Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(primary ? AnyShapeStyle(Theme.popGradient) : AnyShapeStyle(Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(primary ? Color.clear : Theme.ink.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: primary ? Theme.coral.opacity(0.35) : .black.opacity(0.05), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
