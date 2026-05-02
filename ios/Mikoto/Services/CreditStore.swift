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

    var balance: Int = 15
    var plan: Plan = .free
    var cycle: BillingCycle = .monthly
    var trialActive: Bool = false
    var trialEndsAt: Date?
    var renewalDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    var totalGenerated: Int = 0

    private var userId: String?
    private var key: String { "mikoto.credit.\(userId ?? "default").v1" }

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

    var isSubscribed: Bool { plan != .free }
    var canGenerate: Bool { balance >= Self.costPerPhoto }

    func switchUser(_ userId: String) {
        self.userId = userId
        reload()
    }

    func deduct(_ amount: Int = costPerPhoto) {
        balance = max(0, balance - amount)
        totalGenerated += 1
        persist()
    }

    func grantWelcomeBonus() {
        balance = max(balance, 15)
        persist()
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
        persist()
    }

    func cancelSubscription() {
        plan = .free
        trialActive = false
        trialEndsAt = nil
        persist()
    }

    func refreshIfNeeded() {
        guard Date() >= renewalDate else { return }
        balance = monthlyAllowance
        let interval: Calendar.Component = cycle == .annual ? .year : .month
        renewalDate = Calendar.current.date(byAdding: interval, value: 1, to: Date()) ?? Date()
        persist()
    }

    func reset() {
        balance = 15
        plan = .free
        cycle = .monthly
        trialActive = false
        trialEndsAt = nil
        renewalDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        totalGenerated = 0
        persist()
    }

    // MARK: - Persistence

    private func reload() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(Persisted.self, from: data) {
            balance = saved.balance
            plan = saved.plan
            cycle = saved.cycle
            trialActive = saved.trialActive
            trialEndsAt = saved.trialEndsAt
            renewalDate = saved.renewalDate
            totalGenerated = saved.totalGenerated
        } else {
            balance = 15
            plan = .free
            cycle = .monthly
            trialActive = false
            trialEndsAt = nil
            renewalDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            totalGenerated = 0
        }
        refreshIfNeeded()
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
