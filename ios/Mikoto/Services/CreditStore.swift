import Foundation
import Observation
import Supabase

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

    var balance: Int
    var plan: Plan
    var cycle: BillingCycle
    var trialActive: Bool
    var trialEndsAt: Date?
    var renewalDate: Date
    var totalGenerated: Int

    var userId: String?
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
        } else {
            self.balance = 15
            self.plan = .free
            self.cycle = .monthly
            self.trialActive = false
            self.trialEndsAt = nil
            self.renewalDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            self.totalGenerated = 0
        }
        refreshIfNeeded()
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
        persistAndSync()
    }

    func grantWelcomeBonus() {
        balance = max(balance, 15)
        persistAndSync()
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
        persistAndSync()
    }

    func cancelSubscription() {
        plan = .free
        trialActive = false
        trialEndsAt = nil
        persistAndSync()
    }

    func refreshIfNeeded() {
        guard Date() >= renewalDate else { return }
        balance = monthlyAllowance
        let interval: Calendar.Component = cycle == .annual ? .year : .month
        renewalDate = Calendar.current.date(byAdding: interval, value: 1, to: Date()) ?? Date()
        persistAndSync()
    }

    func reset() {
        balance = 15
        plan = .free
        cycle = .monthly
        trialActive = false
        trialEndsAt = nil
        renewalDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        totalGenerated = 0
        persistAndSync()
    }

    // MARK: - Supabase Sync

    @MainActor
    func loadFromSupabase(userId: String) async {
        self.userId = userId
        do {
            let records: [ProfileRecord] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value

            guard let record = records.first else {
                NSLog("[CreditStore] no profile found, creating initial profile")
                persistAndSync()
                return
            }

            balance = record.balance
            plan = Plan(rawValue: record.plan) ?? .free
            cycle = BillingCycle(rawValue: record.cycle) ?? .monthly
            trialActive = record.trialActive
            trialEndsAt = record.trialEndsAt.flatMap { iso8601.date(from: $0) }
            if let d = iso8601.date(from: record.renewalDate) {
                renewalDate = d
            }
            totalGenerated = record.totalGenerated
            persistLocally()

            NSLog("[CreditStore] loaded from Supabase: balance=%d plan=%@ total=%d", balance, plan.rawValue, totalGenerated)
        } catch {
            NSLog("[CreditStore] load failed: %@", error.localizedDescription)
        }
    }

    // MARK: - Persistence

    private func persistLocally() {
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

    private func persistAndSync() {
        persistLocally()
        guard let userId else { return }
        Task {
            do {
                let record = ProfileRecord(
                    id: userId,
                    balance: balance,
                    plan: plan.rawValue,
                    cycle: cycle.rawValue,
                    trialActive: trialActive,
                    trialEndsAt: trialEndsAt.map { iso8601.string(from: $0) },
                    renewalDate: iso8601.string(from: renewalDate),
                    totalGenerated: totalGenerated
                )
                try await supabase.from("profiles").upsert(record).execute()
            } catch {
                NSLog("[CreditStore] sync failed: %@", error.localizedDescription)
            }
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
