import Foundation

struct Config {
    // Keys expected in Info.plist. You can add these as String entries if you want to override.
    private static let supabaseURLKey = "EXPO_PUBLIC_SUPABASE_URL"
    private static let supabaseAnonKeyKey = "EXPO_PUBLIC_SUPABASE_ANON_KEY"

    static var EXPO_PUBLIC_SUPABASE_URL: String {
        if let dict = Bundle.main.infoDictionary,
           let value = dict[supabaseURLKey] as? String {
            return value
        }
        return ""
    }

    static var EXPO_PUBLIC_SUPABASE_ANON_KEY: String {
        if let dict = Bundle.main.infoDictionary,
           let value = dict[supabaseAnonKeyKey] as? String {
            return value
        }
        return ""
    }
}
