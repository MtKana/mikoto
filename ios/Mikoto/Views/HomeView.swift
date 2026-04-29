import SwiftUI

struct HomeView: View {
    @State private var path = NavigationPath()
    @State private var showPaywall = false
    @Environment(AuthManager.self) private var auth
    @Environment(CreditStore.self) private var credits
    @Environment(UserStyleStore.self) private var userStyle

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    masthead
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    heroBanner
                        .padding(.horizontal, 20)
                        .padding(.top, 18)

                    if let custom = userStyle.style {
                        customStyleSection(custom)
                            .padding(.horizontal, 20)
                            .padding(.top, 26)
                    }

                    headline
                        .padding(.horizontal, 20)
                        .padding(.top, 26)

                    grid
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                        .padding(.bottom, 24)

                    colophon
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.bone.ignoresSafeArea())
            .navigationDestination(for: PhotoStyle.self) { style in
                StyleDetailView(style: style)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var masthead: some View {
        HStack(alignment: .center) {
            Wordmark(size: 18)
            Spacer()
            CreditPill(balance: credits.balance) {
                showPaywall = true
            }
        }
    }

    private var heroBanner: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.popGradient)
                .frame(height: 168)
                .overlay(
                    ZStack {
                        Circle()
                            .fill(Theme.sunshine.opacity(0.85))
                            .frame(width: 130, height: 130)
                            .offset(x: 110, y: -30)
                            .blur(radius: 0.5)
                        Circle()
                            .fill(Theme.mint.opacity(0.6))
                            .frame(width: 80, height: 80)
                            .offset(x: 80, y: 70)
                    }
                    .mask(RoundedRectangle(cornerRadius: 28, style: .continuous))
                )
                .shadow(color: Theme.coral.opacity(0.25), radius: 20, y: 10)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .heavy))
                    Text("ナンバーワン恋活アプリ")
                        .font(.mikotoLabel(10, weight: .heavy))
                        .tracking(0.6)
                }
                .foregroundStyle(Theme.coral)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.white))

                Text("運命の一枚を、\nAIで。")
                    .font(.mikotoDisplay(28, weight: .black))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
            }
            .padding(20)
        }
    }

    private func customStyleSection(_ style: PhotoStyle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Theme.popGradient))
                Text("あなただけのスタイル")
                    .font(.mikotoDisplay(20, weight: .black))
                    .foregroundStyle(Theme.ink)
            }
            NavigationLink(value: style) {
                HStack(spacing: 14) {
                    Color.clear
                        .frame(width: 92, height: 116)
                        .overlay {
                            StyleArtwork(style: style)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white, lineWidth: 3)
                        )
                        .shadow(color: style.swatch.first?.opacity(0.3) ?? .black.opacity(0.1), radius: 10, y: 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("ONLY FOR YOU")
                            .font(.mikotoLabel(9, weight: .black))
                            .tracking(0.6)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Theme.popGradient))
                        Text(style.nameJP)
                            .font(.mikotoDisplay(22, weight: .black))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Text(style.tagline)
                            .font(.mikotoSans(12, weight: .heavy))
                            .foregroundStyle(Theme.coral)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Theme.inkSubtle)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white)
                )
                .shadow(color: .black.opacity(0.06), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
        }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Theme.coral)
                    .frame(width: 4, height: 22)
                    .clipShape(.rect(cornerRadius: 2))
                Text("定番の8スタイル")
                    .font(.mikotoDisplay(22, weight: .black))
                    .foregroundStyle(Theme.ink)
            }
            Text("好きな雰囲気を選んで、写真をアップ。\nたった数秒で、最高の一枚に。")
                .font(.mikotoSans(14, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ], spacing: 22) {
            ForEach(Array(PhotoStyle.all.enumerated()), id: \.element.id) { idx, style in
                NavigationLink(value: style) {
                    StyleCard(style: style, index: idx)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var colophon: some View {
        VStack(alignment: .leading, spacing: 12) {
            Hairline()
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.mint)
                VStack(alignment: .leading, spacing: 3) {
                    Text("写真は安全に処理されます")
                        .font(.mikotoSans(12, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("あなたの許可なく、外部に共有されることはありません。")
                        .font(.mikotoSans(11))
                        .foregroundStyle(Theme.inkSubtle)
                        .lineSpacing(2)
                }
                Spacer()
            }
        }
    }
}
