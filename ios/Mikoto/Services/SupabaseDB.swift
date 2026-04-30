import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: Config.supabaseURL)!,
    supabaseKey: Config.supabaseAnonKey
)

let iso8601: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

// MARK: - Database Record Types

nonisolated struct ProfileRecord: Codable, Sendable {
    let id: String
    var balance: Int
    var plan: String
    var cycle: String
    var trialActive: Bool
    var trialEndsAt: String?
    var renewalDate: String
    var totalGenerated: Int

    enum CodingKeys: String, CodingKey {
        case id, balance, plan, cycle
        case trialActive = "trial_active"
        case trialEndsAt = "trial_ends_at"
        case renewalDate = "renewal_date"
        case totalGenerated = "total_generated"
    }
}

nonisolated struct UserStyleRecord: Codable, Sendable {
    let userId: String
    var styleData: UserStyleData

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case styleData = "style_data"
    }
}

nonisolated struct PhotoRecord: Codable, Sendable {
    let id: String
    let userId: String
    let styleId: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case styleId = "style_id"
        case createdAt = "created_at"
    }
}
