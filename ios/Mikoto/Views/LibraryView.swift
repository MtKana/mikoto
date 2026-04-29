import SwiftUI

struct LibraryView: View {
    @Environment(PhotoLibraryStore.self) private var library
    @Environment(CreditStore.self) private var credits
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    masthead
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 22)

                    if library.photos.isEmpty {
                        emptyState
                            .padding(.top, 60)
                    } else {
                        grid
                            .padding(.horizontal, 16)
                            .padding(.top, 22)
                            .padding(.bottom, 40)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.bone.ignoresSafeArea())
            .navigationDestination(for: GeneratedPhoto.self) { photo in
                if let style = photo.style {
                    ResultView(photo: photo, style: style)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var masthead: some View {
        HStack {
            Wordmark(size: 18)
            Spacer()
            CreditPill(balance: credits.balance) {
                showPaywall = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Theme.lavender)
                    .frame(width: 4, height: 22)
                    .clipShape(.rect(cornerRadius: 2))
                Text("マイライブラリ")
                    .font(.mikotoDisplay(22, weight: .black))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(library.photos.count) 枚")
                    .font(.mikotoLabel(11, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.lavender))
            }
            Text("これまで作成した写真がすべてここに。")
                .font(.mikotoSans(13, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ], spacing: 18) {
            ForEach(Array(library.photos.enumerated()), id: \.element.id) { _, photo in
                NavigationLink(value: photo) {
                    photoCard(photo)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if let img = photo.uiImage {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                        } label: {
                            Label("写真に保存", systemImage: "square.and.arrow.down")
                        }
                    }
                    Button(role: .destructive) {
                        library.remove(photo)
                    } label: {
                        Label("削除する", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func photoCard(_ photo: GeneratedPhoto) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Theme.linen
                .aspectRatio(0.82, contentMode: .fit)
                .overlay {
                    if let img = photo.uiImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(.rect(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.12), radius: 10, y: 5)

            if let style = photo.style {
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.nameJP)
                        .font(.mikotoDisplay(15, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(style.mood)
                        .font(.mikotoLabel(10, weight: .semibold))
                        .foregroundStyle(Theme.inkSubtle)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Theme.popGradient)
                    .frame(width: 92, height: 92)
                    .shadow(color: Theme.coral.opacity(0.4), radius: 20, y: 8)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("まだ写真はありません")
                    .font(.mikotoDisplay(20, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("ホームからスタイルを選んで、\n最初の一枚を作成しましょう。")
                    .font(.mikotoSans(13, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
