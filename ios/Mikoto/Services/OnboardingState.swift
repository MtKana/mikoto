import Foundation
import Observation

@Observable
final class OnboardingState {
    var hasCompleted: Bool = false {
        didSet { UserDefaults.standard.set(hasCompleted, forKey: key) }
    }

    // Profile-icon questions
    var usesDatingApps: String = ""        // "はい" / "いいえ"
    var iconConfidence: String = ""        // confidence level
    var iconConcerns: Set<String> = []     // multi-select 悩み

    // Personality / lifestyle (used to generate the user's unique style)
    var weekend: String = ""
    var atmosphere: String = ""
    var selfWord: String = ""
    var outfit: String = ""

    // Legacy fields kept for compatibility with StyleAnswers
    var goal: String = ""
    var ageRange: String = ""
    var impression: String = ""
    var struggle: String = ""

    private var userId: String?
    private var key: String { "mikoto.onboarding.\(userId ?? "default").v1" }

    func switchUser(_ userId: String) {
        self.userId = userId
        hasCompleted = UserDefaults.standard.bool(forKey: key)
    }

    func complete() {
        hasCompleted = true
    }

    func reset() {
        hasCompleted = false
    }

    func answers() -> StyleAnswers {
        StyleAnswers(
            goal: goal.isEmpty ? (usesDatingApps == "はい" ? "マッチングアプリで素敵な出会い" : "印象を変えたい") : goal,
            ageRange: ageRange,
            impression: impression,
            struggle: struggle.isEmpty ? iconConcerns.first ?? "" : struggle,
            symptoms: Array(iconConcerns),
            weekend: weekend,
            atmosphere: atmosphere,
            selfWord: selfWord,
            outfit: outfit
        )
    }
}
