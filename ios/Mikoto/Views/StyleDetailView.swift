import SwiftUI
import PhotosUI

struct StyleDetailView: View {
    let style: PhotoStyle

    @Environment(PhotoLibraryStore.self) private var library
    @Environment(CreditStore.self) private var credits
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var isGenerating = false
    @State private var generated: GeneratedPhoto?
    @State private var errorMessage: String?
    @State private var showResult = false
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                    .padding(.horizontal, 18)
                    .padding(.top, 4)

                titleBlock
                    .padding(.horizontal, 22)
                    .padding(.top, 22)

                description
                    .padding(.horizontal, 22)
                    .padding(.top, 14)

                photoSection
                    .padding(.horizontal, 22)
                    .padding(.top, 26)

                tipsCard
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 140)
            }
        }
        .background(Theme.bone.ignoresSafeArea())
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Wordmark(size: 14)
            }
            ToolbarItem(placement: .topBarTrailing) {
                CreditPill(balance: credits.balance) {
                    showPaywall = true
                }
            }
        }
        .toolbarBackground(Theme.bone, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            generateBar
        }
        .onChange(of: pickerItem) { _, newItem in
            Task { await loadImage(newItem) }
        }
        .navigationDestination(isPresented: $showResult) {
            if let generated {
                ResultView(photo: generated, style: style)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("エラーが発生しました", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    private var hero: some View {
        Color.clear
            .aspectRatio(0.92, contentMode: .fit)
            .overlay {
                StyleArtwork(style: style)
                    .allowsHitTesting(false)
            }
            .clipShape(.rect(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white, lineWidth: 4)
            )
            .shadow(color: style.swatch.first?.opacity(0.35) ?? .black.opacity(0.1), radius: 20, y: 10)
            .overlay(alignment: .topLeading) {
                HStack {
                    Text("No. \(String(format: "%02d", styleIndex + 1)) / 08")
                        .font(.mikotoDisplay(11, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white))
                    Spacer()
                }
                .padding(16)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: style.symbol)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Theme.ink))
                    .padding(16)
            }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: style.mood, color: Theme.coral)
                .fixedSize()

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(style.nameJP)
                    .font(.mikotoDisplay(40, weight: .black))
                    .foregroundStyle(Theme.ink)
                Text(style.nameRomaji)
                    .font(.mikotoLabel(14, weight: .heavy))
                    .foregroundStyle(Theme.inkSubtle)
            }

            Text(style.tagline)
                .font(.mikotoSans(15, weight: .heavy))
                .foregroundStyle(Theme.coral)
        }
    }

    private var description: some View {
        Text(style.description)
            .font(.mikotoSans(14, weight: .medium))
            .foregroundStyle(Theme.inkSoft)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Theme.coral)
                    .frame(width: 4, height: 18)
                    .clipShape(.rect(cornerRadius: 2))
                Text("あなたの写真")
                    .font(.mikotoDisplay(18, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("5クレジット")
                    .font(.mikotoLabel(11, weight: .heavy))
                    .foregroundStyle(Theme.coral)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.coral.opacity(0.12)))
            }

            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                Group {
                    if let img = sourceImage {
                        selectedPhotoCard(img)
                    } else {
                        emptyPhotoCard
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func selectedPhotoCard(_ img: UIImage) -> some View {
        HStack(spacing: 14) {
            Color.clear
                .frame(width: 64, height: 64)
                .overlay {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("写真を選択しました")
                    .font(.mikotoSans(15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("タップして別の写真を選ぶ")
                    .font(.mikotoSans(12, weight: .medium))
                    .foregroundStyle(Theme.inkSubtle)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Theme.mint))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private var emptyPhotoCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "camera.fill")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Theme.popGradient))

            VStack(alignment: .leading, spacing: 3) {
                Text("写真をアップロード")
                    .font(.mikotoSans(15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("明るい場所で撮ったポートレートが◎")
                    .font(.mikotoSans(12, weight: .medium))
                    .foregroundStyle(Theme.inkSubtle)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Theme.coral)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.coral.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        )
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11, weight: .heavy))
                Text("きれいに仕上げるコツ")
                    .font(.mikotoSans(12, weight: .heavy))
            }
            .foregroundStyle(Theme.tangerine)

            tipRow("窓からの自然光がベスト。直射日光は避けて。")
            tipRow("カメラの少し横を見ると自然な表情に。")
            tipRow("肩まで写ると、バランスがよくなります。")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.sunshine.opacity(0.18))
        )
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(Theme.tangerine).frame(width: 6, height: 6).padding(.top, 6)
            Text(text)
                .font(.mikotoSans(13, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
    }

    private var generateBar: some View {
        VStack(spacing: 0) {
            Button(action: tryGenerate) {
                HStack(spacing: 10) {
                    if isGenerating {
                        ProgressView().tint(.white)
                        Text("作成中…")
                            .font(.mikotoSans(16, weight: .heavy))
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 15, weight: .heavy))
                        Text(buttonLabel)
                            .font(.mikotoSans(16, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(canGenerate ? AnyShapeStyle(Theme.popGradient) : AnyShapeStyle(Theme.inkSubtle.opacity(0.4)))
                )
                .shadow(color: canGenerate ? Theme.coral.opacity(0.4) : .clear, radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!canGenerate || isGenerating)
            .sensoryFeedback(.success, trigger: generated)
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(Theme.bone)
    }

    private var buttonLabel: String {
        if !credits.canGenerate {
            return "プランを見る"
        }
        if sourceImage == nil {
            return "写真を選んでください"
        }
        return "写真を作成する（5クレジット）"
    }

    private var canGenerate: Bool {
        sourceImage != nil
    }

    private var styleIndex: Int {
        PhotoStyle.all.firstIndex(of: style) ?? 0
    }

    private func loadImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let img = UIImage(data: data) {
            sourceImage = img
        }
    }

    private func tryGenerate() {
        guard sourceImage != nil else { return }
        if !credits.canGenerate {
            showPaywall = true
            return
        }
        generate()
    }

    private func generate() {
        guard let img = sourceImage else { return }
        isGenerating = true
        Task {
            do {
                let data = try await PhotoGenerationService.generate(from: img, style: style)
                let photo = GeneratedPhoto(imageData: data, styleID: style.id)
                library.add(photo)
                credits.deduct()
                generated = photo
                isGenerating = false
                showResult = true
            } catch {
                isGenerating = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
