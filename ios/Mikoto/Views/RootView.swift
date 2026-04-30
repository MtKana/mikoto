import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(OnboardingState.self) private var onboarding
    @Environment(CreditStore.self) private var credits
    @Environment(UserStyleStore.self) private var userStyle
    @Environment(PhotoLibraryStore.self) private var library
    @State private var selection: Tab = .home
    @State private var didSyncForUser: String?

    enum Tab: Hashable { case home, library, settings }

    var body: some View {
        Group {
            if auth.isLoading {
                loadingView
            } else if auth.user == nil {
                SignInView()
            } else if !onboarding.hasCompleted {
                OnboardingFlow()
            } else {
                mainTabs
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            Theme.bone.ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.popGradient)
                        .frame(width: 72, height: 72)
                        .shadow(color: Theme.coral.opacity(0.4), radius: 16, y: 6)
                    Text("M")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                ProgressView()
                    .tint(Theme.coral)
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "sparkles") }
                .tag(Tab.home)

            LibraryView()
                .tabItem { Label("ライブラリ", systemImage: "photo.stack.fill") }
                .tag(Tab.library)

            SettingsView()
                .tabItem { Label("設定", systemImage: "person.crop.circle.fill") }
                .tag(Tab.settings)
        }
        .tint(Theme.coral)
        .task(id: auth.user?.id) {
            guard let userId = auth.user?.id, didSyncForUser != userId else { return }
            didSyncForUser = userId
            await credits.loadFromSupabase(userId: userId)
            await userStyle.loadFromSupabase(userId: userId)
            await library.loadFromSupabase(userId: userId)
        }
    }
}
