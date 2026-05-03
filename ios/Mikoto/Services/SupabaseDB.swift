import Foundation
import Supabase

private let supabaseURLString: String = {
    let value = Config.EXPO_PUBLIC_SUPABASE_URL
    if !value.isEmpty { return value }
    return "https://nmunmpgljrtljithkjic.supabase.co"
}()

private let supabaseAnonKeyString: String = {
    let value = Config.EXPO_PUBLIC_SUPABASE_ANON_KEY
    if !value.isEmpty { return value }
    return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tdW5tcGdsanJ0bGppdGhramljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczODE1NDgsImV4cCI6MjA5Mjk1NzU0OH0.AeS7jZILVz52tGxhMLJCGB4kYCKeqDRVWCy3u3oLo-I"
}()

let supabase = SupabaseClient(
    supabaseURL: URL(string: supabaseURLString)!,
    supabaseKey: supabaseAnonKeyString
)
