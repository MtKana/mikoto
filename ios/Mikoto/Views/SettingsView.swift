import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(PhotoLibraryStore.self) private var library
    @Environment(CreditStore.self) private var credits
    @Environment(AppPreferences.self) private var prefs
    @Environment(OnboardingState.self) private var onboarding

    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var showPaywall = false
    @State private var showCancelConfirm = false
    @State private var showEditName = false
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            @Bindable var prefs = prefs

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    masthead
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    profileCard
                        .padding(.horizontal, 20)
                        .padding(.top, 22)

                    planCard
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    statsRow
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    sectionHeader("アカウント")
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    accountSection
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    sectionHeader("アプリ")
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    appSection(prefs: prefs)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    sectionHeader("サポート")
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    supportSection
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    sectionHeader("法的情報")
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    legalSection
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    signOutButton
                        .padding(.horizontal, 20)
                        .padding(.top, 28)

                    deleteAccountButton
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    versionFooter
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 36)
                }
            }
            .background(Theme.bone.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("お名前を編集", isPresented: $showEditName) {
                TextField("表示名", text: $draftName)
                Button("保存") {
                    prefs.displayName = draftName.trimmingCharacters(in: .whitespaces)
                }
                Button("キャンセル", role: .cancel) { }
            }
            .confirmationDialog("ログアウトしますか？", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("ログアウト", role: .destructive) {
                    Task { await auth.signOut() }
                }
                Button("キャンセル", role: .cancel) { }
            }
            .confirmationDialog("写真をすべて削除しますか？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("すべて削除", role: .destructive) {
                    library.removeAll()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("この操作は取り消せません。")
            }
            .confirmationDialog("サブスクリプションを解約しますか？", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                Button("解約する", role: .destructive) {
                    credits.cancelSubscription()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("現在の請求期間の終了まで利用できます。")
            }
            .confirmationDialog("アカウントを削除しますか？", isPresented: $showDeleteAccountConfirm, titleVisibility: .visible) {
                Button("削除する", role: .destructive) {
                    library.removeAll()
                    credits.reset()
                    onboarding.reset()
                    Task { await auth.signOut() }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("すべてのデータが削除され、元に戻せません。")
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

    private var profileCard: some View {
        HStack(spacing: 16) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(displayedName)
                    .font(.mikotoDisplay(20, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let email = auth.user?.email, !email.isEmpty {
                    Text(email)
                        .font(.mikotoSans(12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 9, weight: .heavy))
                    Text("ログイン中")
                        .font(.mikotoLabel(10, weight: .heavy))
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(.white))
                .padding(.top, 2)
            }
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.popGradient)
        )
        .shadow(color: Theme.coral.opacity(0.3), radius: 18, y: 8)
    }

    private var displayedName: String {
        if !prefs.displayName.isEmpty { return prefs.displayName }
        return auth.user?.name ?? "ゲスト"
    }

    private var avatar: some View {
        Group {
            if let urlString = auth.user?.picture, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        initialsAvatar
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
            } else {
                initialsAvatar
            }
        }
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle().fill(.white)
            Text(initial)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Theme.coral)
        }
        .frame(width: 64, height: 64)
        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
    }

    private var initial: String {
        if let first = displayedName.first {
            return String(first).uppercased()
        }
        return "M"
    }

    // MARK: Plan

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: credits.isSubscribed ? "crown.fill" : "sparkles")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(credits.isSubscribed ? Theme.coral : Theme.lavender))
                VStack(alignment: .leading, spacing: 2) {
                    Text(credits.planNameJP)
                        .font(.mikotoDisplay(16, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(credits.trialActive ? "トライアル期間中" : (credits.isSubscribed ? "アクティブ" : "無料"))
                        .font(.mikotoLabel(10, weight: .heavy))
                        .foregroundStyle(Theme.inkSubtle)
                }
                Spacer()
                Text("\(credits.balance) / \(credits.monthlyAllowance)")
                    .font(.mikotoDisplay(15, weight: .black))
                    .foregroundStyle(Theme.coral)
            }

            ProgressView(value: Double(credits.balance), total: Double(max(credits.monthlyAllowance, 1)))
                .tint(Theme.coral)

            HStack(spacing: 4) {
                Text("次回更新")
                    .font(.mikotoLabel(10, weight: .heavy))
                    .foregroundStyle(Theme.inkSubtle)
                Text(credits.renewalDate, style: .date)
                    .font(.mikotoLabel(10, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            HStack(spacing: 10) {
                if credits.isSubscribed {
                    Button {
                        showPaywall = true
                    } label: {
                        Text("プラン変更")
                            .font(.mikotoSans(13, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Theme.popGradient)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showCancelConfirm = true
                    } label: {
                        Text("解約")
                            .font(.mikotoSans(13, weight: .heavy))
                            .foregroundStyle(Theme.coral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Theme.coral.opacity(0.4), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12, weight: .heavy))
                            Text("アップグレード")
                                .font(.mikotoSans(13, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.popGradient)
                        )
                        .shadow(color: Theme.coral.opacity(0.35), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(library.photos.count)",
                label: "作成した写真",
                color: Theme.coral,
                icon: "photo.stack.fill"
            )
            statCard(
                value: "\(uniqueStyleCount)",
                label: "使ったスタイル",
                color: Theme.lavender,
                icon: "sparkles"
            )
        }
    }

    private func statCard(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color))
            Text(value)
                .font(.mikotoDisplay(26, weight: .black))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.mikotoSans(11, weight: .heavy))
                .foregroundStyle(Theme.inkSubtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private var uniqueStyleCount: Int {
        Set(library.photos.compactMap { $0.styleID }).count
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.mikotoDisplay(13, weight: .black))
            .tracking(0.6)
            .foregroundStyle(Theme.inkSubtle)
    }

    private var accountSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "person.fill", color: Theme.sky, title: "表示名", value: displayedName) {
                draftName = displayedName == "ゲスト" ? "" : displayedName
                showEditName = true
            }
            divider
            settingsRow(icon: "envelope.fill", color: Theme.tangerine, title: "メールアドレス", value: auth.user?.email ?? "—", action: nil)
            divider
            settingsRow(icon: "arrow.clockwise", color: Theme.mint, title: "購入を復元", value: "", action: {
                // Restore via RevenueCat would go here
            })
            divider
            settingsRow(icon: "creditcard.fill", color: Theme.lavender, title: "サブスクリプション管理", value: "", action: {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            })
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func appSection(prefs: AppPreferences) -> some View {
        @Bindable var prefs = prefs
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Theme.tangerine))
                Text("通知")
                    .font(.mikotoSans(14, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Toggle("", isOn: $prefs.notificationsEnabled)
                    .labelsHidden()
                    .tint(Theme.coral)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            divider

            settingsRow(icon: "globe", color: Theme.lavender, title: "言語", value: "日本語", action: nil)
            divider
            Button {
                showDeleteConfirm = true
            } label: {
                settingsRowContent(icon: "trash.fill", color: Theme.coral, title: "ライブラリをすべて削除", value: "", destructive: true)
            }
            .buttonStyle(.plain)
            .disabled(library.photos.isEmpty)
            .opacity(library.photos.isEmpty ? 0.5 : 1)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private var supportSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "questionmark.circle.fill", color: Theme.sky, title: "ヘルプ・FAQ", value: "", action: {
                if let url = URL(string: "https://rork.com") {
                    UIApplication.shared.open(url)
                }
            })
            divider
            settingsRow(icon: "envelope.fill", color: Theme.tangerine, title: "お問い合わせ", value: "", action: {
                if let url = URL(string: "mailto:support@mikoto.app?subject=ミコトについて") {
                    UIApplication.shared.open(url)
                }
            })
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private var legalSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "doc.text.fill", color: Theme.inkSubtle, title: "利用規約", value: "", action: {
                if let url = URL(string: "https://rork.com/terms") {
                    UIApplication.shared.open(url)
                }
            })
            divider
            settingsRow(icon: "hand.raised.fill", color: Theme.inkSubtle, title: "プライバシーポリシー", value: "", action: {
                if let url = URL(string: "https://rork.com/privacy") {
                    UIApplication.shared.open(url)
                }
            })
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func settingsRow(icon: String, color: Color, title: String, value: String, action: (() -> Void)? = nil) -> some View {
        Group {
            if let action {
                Button(action: action) {
                    settingsRowContent(icon: icon, color: color, title: title, value: value, destructive: false)
                }
                .buttonStyle(.plain)
            } else {
                settingsRowContent(icon: icon, color: color, title: title, value: value, destructive: false)
            }
        }
    }

    private func settingsRowContent(icon: String, color: Color, title: String, value: String, destructive: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(color))
            Text(title)
                .font(.mikotoSans(14, weight: .heavy))
                .foregroundStyle(destructive ? Theme.coral : Theme.ink)
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(.mikotoSans(12, weight: .medium))
                    .foregroundStyle(Theme.inkSubtle)
                    .lineLimit(1)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Theme.inkSubtle.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
            .padding(.leading, 56)
    }

    private var signOutButton: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .heavy))
                Text("ログアウト")
                    .font(.mikotoSans(15, weight: .heavy))
            }
            .foregroundStyle(Theme.coral)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.coral.opacity(0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var deleteAccountButton: some View {
        Button {
            showDeleteAccountConfirm = true
        } label: {
            Text("アカウントを削除")
                .font(.mikotoSans(13, weight: .heavy))
                .foregroundStyle(Theme.inkSubtle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text("ミコト")
                .font(.mikotoDisplay(12, weight: .black))
                .foregroundStyle(Theme.inkSubtle)
            Text("バージョン 1.0.0 · Made in Tokyo")
                .font(.mikotoSans(11, weight: .medium))
                .foregroundStyle(Theme.inkSubtle.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
