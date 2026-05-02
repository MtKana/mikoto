import SwiftUI

@main
struct MikotoApp: App {
    @State private var library = PhotoLibraryStore()
    @State private var auth = AuthManager()
    @State private var credits = CreditStore()
    @State private var onboarding = OnboardingState()
    @State private var prefs = AppPreferences()
    @State private var userStyle = UserStyleStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .environment(auth)
                .environment(credits)
                .environment(onboarding)
                .environment(prefs)
                .environment(userStyle)
                .preferredColorScheme(.light)
                .tint(Theme.coral)
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
