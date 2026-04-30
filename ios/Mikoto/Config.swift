import Foundation

enum Config {
    static let supabaseURL: String = {
        if let value = Bundle.main.infoDictionary?["EXPO_PUBLIC_SUPABASE_URL"] as? String, !value.isEmpty {
            return value
        }
        return "https://nmunmpgljrtljithkjic.supabase.co"
    }()

    static let supabaseAnonKey: String = {
        if let value = Bundle.main.infoDictionary?["EXPO_PUBLIC_SUPABASE_ANON_KEY"] as? String, !value.isEmpty {
            return value
        }
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tdW5tcGdsanJ0bGppdGhramljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczODE1NDgsImV4cCI6MjA5Mjk1NzU0OH0.AeS7jZILVz52tGxhMLJCGB4kYCKeqDRVWCy3u3oLo-I"
    }()
}
