import Foundation
import Observation

@Observable
final class CreditStore {
    static let costPerPhoto: Int = 5

    enum Plan: String, Codable, Sendable {
        case free
        case standard
        case professional
    }

    enum BillingCycle: String, Codable, Sendable {
        case monthly
        case annual
    }

    var balance: Int {
        didSet { persist() }
    }
    var plan: Plan {
        didSet { persist() }
    }
    var cycle: BillingCycle {
        didSet { persist() }
    }
    var trialActive: Bool {
        didSet { persist() }
    }
    var trialEndsAt: Date? {
        didSet { persist() }
    }
    var renewalDate: Date {
        didSet { persist() }
    }
    var totalGenerated: Int {
        didSet { persist() }
    }

    var onChange: (() -> Void)?
    private var suppressOnChange: Bool = false

    private let key = "mikoto.credit.state.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(Persisted.self, from: data) {
            self.balance = saved.balance
            self.plan = saved.plan
            self.cycle = saved.cycle
            self.trialActive = saved.trialActive
            self.trialEndsAt = saved.trialEndsAt
            self.renewalDate = saved.renewalDate
            self.totalGenerated = saved.totalGenerated
            self.refreshIfNeeded()
        } else {
            self.balance = 15
            self.plan = .free
            self.cycle = .monthly
            self.trialActive = false
            self.trialEndsAt = nil
            self.renewalDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            self.totalGenerated = 0
        }
    }

    var monthlyAllowance: Int {
        switch plan {
        case .free: return 15
        case .standard: return 75
        case .professional: return 225
        }
    }

    var planNameJP: String {
        switch plan {
        case .free: return "無料プラン"
        case .standard: return "スタンダード"
        case .professional: return "プロフェッショナル"
        }
    }

    var isSubscribed: Bool {
        plan != .free
    }

    var canGenerate: Bool {
        balance >= Self.costPerPhoto
    }

    func deduct(_ amount: Int = costPerPhoto) {
        balance = max(0, balance - amount)
        totalGenerated += 1
    }

    func grantWelcomeBonus() {
        balance = max(balance, 15)
    }

    func subscribe(plan: Plan, cycle: BillingCycle, withTrial: Bool) {
        self.plan = plan
        self.cycle = cycle
        self.trialActive = withTrial
        if withTrial {
            self.trialEndsAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        } else {
            self.trialEndsAt = nil
        }
        let interval: Calendar.Component = cycle == .annual ? .year : .month
        self.renewalDate = Calendar.current.date(byAdding: interval, value: 1, to: Date()) ?? Date()
        self.balance = monthlyAllowance
    }

    func cancelSubscription() {
        plan = .free
        trialActive = false
        trialEndsAt = nil
    }

    func refreshIfNeeded() {
        if Date() >= renewalDate {
            balance = monthlyAllowance
            let interval: Calendar.Component = cycle == .annual ? .year : .month
            renewalDate = Calendar.current.date(byAdding: interval, value: 1, to: Date()) ?? Date()
        }
    }

    func reset() {
        balance = 15
        plan = .free
        cycle = .monthly
        trialActive = false
        trialEndsAt = nil
        renewalDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        totalGenerated = 0
    }

    private func persist() {
        let snap = Persisted(
            balance: balance,
            plan: plan,
            cycle: cycle,
            trialActive: trialActive,
            trialEndsAt: trialEndsAt,
            renewalDate: renewalDate,
            totalGenerated: totalGenerated
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: key)
        }
        if !suppressOnChange { onChange?() }
    }

    func applyRemote(
        plan: Plan,
        cycle: BillingCycle,
        balance: Int,
        trialActive: Bool,
        trialEndsAt: Date?,
        renewalDate: Date,
        totalGenerated: Int
    ) {
        suppressOnChange = true
        defer { suppressOnChange = false }
        self.plan = plan
        self.cycle = cycle
        self.balance = balance
        self.trialActive = trialActive
        self.trialEndsAt = trialEndsAt
        self.renewalDate = renewalDate
        self.totalGenerated = totalGenerated
    }

    nonisolated private struct Persisted: Codable, Sendable {
        let balance: Int
        let plan: Plan
        let cycle: BillingCycle
        let trialActive: Bool
        let trialEndsAt: Date?
        let renewalDate: Date
        let totalGenerated: Int
    }
}
