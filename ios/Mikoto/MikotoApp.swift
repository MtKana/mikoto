import SwiftUI

@main
struct MikotoApp: App {
    @State private var library = PhotoLibraryStore()
    @State private var auth = AuthManager()
    @State private var credits = CreditStore()
    @State private var onboarding = OnboardingState()
    @State private var prefs = AppPreferences()
    @State private var userStyle = UserStyleStore()
    @State private var cloudSync = CloudSync()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .environment(auth)
                .environment(credits)
                .environment(onboarding)
                .environment(prefs)
                .environment(userStyle)
                .environment(cloudSync)
                .preferredColorScheme(.light)
                .tint(Theme.coral)
                .task {
                    cloudSync.attach(library: library, credits: credits, userStyle: userStyle)
                    cloudSync.userDidChange(auth.user?.id)
                }
                .onChange(of: auth.user?.id) { _, newID in
                    cloudSync.userDidChange(newID)
                }
                .onOpenURL { url in
                    Task { await auth.handleDeepLink(url) }
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        Task { await auth.handleDeepLink(url) }
                    }
                }
        }
    }
}
