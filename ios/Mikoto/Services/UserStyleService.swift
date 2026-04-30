import Foundation

nonisolated struct StyleAnswers: Sendable {
    let goal: String
    let ageRange: String
    let impression: String
    let struggle: String
    let symptoms: [String]
    let weekend: String
    let atmosphere: String
    let selfWord: String
    let outfit: String
}

nonisolated struct UserStyleService: Sendable {
    private let supabaseURL: String = {
        let env = ProcessInfo.processInfo.environment
        let configured = env["EXPO_PUBLIC_SUPABASE_URL"] ?? ""
        return configured.isEmpty ? "https://nmunmpgljrtljithkjic.supabase.co" : configured
    }()
    private let supabaseAnonKey: String = {
        let env = ProcessInfo.processInfo.environment
        let configured = env["EXPO_PUBLIC_SUPABASE_ANON_KEY"] ?? ""
        return configured.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tdW5tcGdsanJ0bGppdGhramljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczODE1NDgsImV4cCI6MjA5Mjk1NzU0OH0.AeS7jZILVz52tGxhMLJCGB4kYCKeqDRVWCy3u3oLo-I" : configured
    }()
    var inlineAuthError: String?
    private let oauthRedirect = "mikoto://auth-callback"

    private static var toolkitURL: String {
        let env = ProcessInfo.processInfo.environment
        let v = env["EXPO_PUBLIC_TOOLKIT_URL"] ?? ""
        return v.isEmpty ? "https://toolkit.rork.com" : v
    }

    private static var secretKey: String {
        let env = ProcessInfo.processInfo.environment
        return env["EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY"] ?? ""
    }

    static func generate(answers: StyleAnswers) async throws -> UserStyleData {
        // Try API up to 2 times across two model fallbacks. If everything fails,
        // synthesize a sensible style locally so the user never gets stuck.
        let models = ["openai/gpt-5-mini", "openai/gpt-4o-mini"]
        var lastError: Error?

        for model in models {
            for attempt in 0..<2 {
                do {
                    return try await callAPI(model: model, answers: answers)
                } catch {
                    lastError = error
                    if attempt == 0 {
                        try? await Task.sleep(for: .milliseconds(600))
                    }
                }
            }
        }

        #if DEBUG
        print("[UserStyleService] All API attempts failed — using local fallback. lastError=\(String(describing: lastError))")
        #endif
        return localFallback(answers: answers)
    }

    private static func callAPI(model: String, answers: StyleAnswers) async throws -> UserStyleData {
        guard !secretKey.isEmpty else { throw PhotoGenError.missingConfig }

        let url = URL(string: "\(toolkitURL)/v2/vercel/v1/chat/completions")!
        let userPrompt = buildPrompt(answers)

        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "あなたは日本のマッチングアプリ専門のフォトスタイリストです。ユーザーの回答に基づき、その人だけのオリジナル写真スタイルを設計します。返答は必ず指定したJSONフォーマットのみで、説明文や ```json``` などのコードフェンスは絶対に含めないでください。"
                ],
                ["role": "user", "content": userPrompt]
            ],
            "response_format": ["type": "json_object"]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PhotoGenError.serverError(0) }
        switch http.statusCode {
        case 200: break
        case 401: throw PhotoGenError.authError
        case 402: throw PhotoGenError.insufficientBalance
        case 413: throw PhotoGenError.payloadTooLarge
        case 429: throw PhotoGenError.rateLimited
        default:  throw PhotoGenError.serverError(http.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw PhotoGenError.decodingFailed
        }

        let cleaned = stripCodeFences(content)
        guard let contentData = cleaned.data(using: .utf8) else {
            throw PhotoGenError.decodingFailed
        }

        do {
            return try JSONDecoder().decode(UserStyleData.self, from: contentData)
        } catch {
            throw PhotoGenError.decodingFailed
        }
    }

    // MARK: - Local fallback

    private static func localFallback(answers a: StyleAnswers) -> UserStyleData {
        let key = (a.atmosphere + a.selfWord + a.weekend + a.outfit).lowercased()

        let preset: (String, String, String, String, String, String, String, [String]) = {
            if key.contains("ロマンティック") || key.contains("夢") {
                return ("夕霞", "Yugasumi", "Twilight Bloom",
                        "夕暮れに溶ける、優しい余韻",
                        "ロマンティック・大人",
                        "golden hour soft warm light, dreamy bokeh, cinematic, intimate close-up",
                        "sun.max.fill",
                        ["#F8B4A2", "#C7A0E8"])
            } else if key.contains("都会") || key.contains("洗練") {
                return ("都映", "Toei", "City Reflection",
                        "都会の光に映える、洗練の表情",
                        "都会的・モダン",
                        "modern cityscape backdrop, soft window light, sleek minimalist composition",
                        "sparkles",
                        ["#5B6CFF", "#9AA8FF"])
            } else if key.contains("ナチュラル") || key.contains("素朴") || key.contains("カジュアル") {
                return ("陽だまり", "Hidamari", "Sunlit Calm",
                        "ぬくもりに包まれる、自然体の一枚",
                        "ナチュラル・温かい",
                        "soft natural daylight, linen tones, gentle outdoor garden background",
                        "leaf.fill",
                        ["#F5C77E", "#E8A07A"])
            } else if key.contains("情熱") || key.contains("エネルギ") || key.contains("冒険") {
                return ("煌", "Kirameki", "Vivid Spark",
                        "鼓動が伝わる、ドラマチックな一枚",
                        "鮮やか・ドラマティック",
                        "vibrant golden hour with rich saturated tones, dynamic angle, confident energy",
                        "flame.fill",
                        ["#FF6B6B", "#FFB36B"])
            } else if key.contains("知的") || key.contains("思慮") || key.contains("クラシック") {
                return ("静謐", "Seihitsu", "Quiet Grace",
                        "静けさに宿る、知性のまなざし",
                        "上品・知的",
                        "library or atelier interior, soft side window light, refined neutral palette",
                        "book.fill",
                        ["#8C7A66", "#3A3A52"])
            } else {
                return ("優景", "Yukei", "Soft Horizon",
                        "あなただけの、優しい光景",
                        "優しい・親しみやすい",
                        "soft pastel light, warm peach background, gentle smile, approachable",
                        "heart.fill",
                        ["#F8A6B8", "#F4C57A"])
            }
        }()

        let explanation = """
        \(orDefault(a.atmosphere))な雰囲気を好み、休日は\(orDefault(a.weekend))あなたには、\(preset.0)（\(preset.1)）がぴったりです。\(orDefault(a.selfWord))という人柄が伝わるよう、表情と光の柔らかさを大切に設計しました。\(orDefault(a.outfit))の服装感と調和し、マッチングアプリで「もう一度見たい」と感じてもらえる一枚に仕上がります。
        """

        let prompt = "\(preset.5). Keep facial features and identity exactly the same. Square 1:1, head-and-shoulders portrait."

        return UserStyleData(
            nameJP: preset.0,
            nameRomaji: preset.1,
            nameEN: preset.2,
            tagline: preset.3,
            description: "あなた専用に設計された撮影シーン。\(preset.4)な空気感の中で、自然な表情を引き出します。",
            explanation: explanation,
            prompt: prompt,
            mood: preset.4,
            symbol: preset.6,
            swatchHex: preset.7
        )
    }

    private static func stripCodeFences(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            if let firstNewline = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: firstNewline)...])
            }
            if t.hasSuffix("```") {
                t = String(t.dropLast(3))
            }
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func buildPrompt(_ a: StyleAnswers) -> String {
        """
        次のユーザーのために、世界に一つだけのマッチングアプリ用フォトスタイルを設計してください。
        既存の8スタイル（清楚、カフェ、桜、オフィス、夕日、ネオン、京都、上品）とは違う、本人専用の名前と世界観にしてください。

        ## ユーザーの回答
        - 目的: \(orDefault(a.goal))
        - 年齢: \(orDefault(a.ageRange))
        - 見られたい印象: \(orDefault(a.impression))
        - 今の悩み: \(orDefault(a.struggle))
        - 当てはまる症状: \(a.symptoms.isEmpty ? "（特になし）" : a.symptoms.joined(separator: "、"))
        - 休日の過ごし方: \(orDefault(a.weekend))
        - 好きな雰囲気: \(orDefault(a.atmosphere))
        - 自分を一言で: \(orDefault(a.selfWord))
        - 服装の好み: \(orDefault(a.outfit))

        ## 出力ルール
        次のキーを持つJSONオブジェクトのみを返してください（追加のキーや前置き文は不要）：

        {
          "nameJP": "2〜4文字の漢字またはカタカナ名",
          "nameRomaji": "Romaji",
          "nameEN": "Short evocative English name",
          "tagline": "12文字程度の日本語キャッチコピー",
          "description": "70〜100文字の日本語、撮影シーンの説明",
          "explanation": "200〜280文字の日本語、なぜこのスタイルがあなたにぴったりなのかを、ユーザーの回答に温かく具体的に触れて説明",
          "mood": "短い日本語の雰囲気タグ（例: ロマンティック・大人）",
          "prompt": "Detailed English photo edit prompt: setting, lighting, wardrobe, expression, color grading, composition. Must end with exactly: 'Keep facial features and identity exactly the same. Square 1:1, head-and-shoulders portrait.'",
          "symbol": "次のSF Symbol名から1つ選ぶ: heart.fill, star.fill, leaf.fill, sparkles, moon.stars.fill, flame.fill, bolt.fill, drop.fill, sun.max.fill, snowflake, camera.macro, paintpalette.fill, music.note, book.fill, pawprint.fill, mountain.2.fill, cup.and.saucer.fill, wind",
          "swatchHex": ["#RRGGBB", "#RRGGBB"]
        }
        """
    }

    private static func orDefault(_ s: String) -> String {
        s.isEmpty ? "（未回答）" : s
    }
}
