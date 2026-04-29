import SwiftUI

nonisolated struct PhotoStyle: Identifiable, Hashable, Sendable {
    let id: String
    let nameJP: String
    let nameRomaji: String
    let nameEN: String
    let tagline: String
    let description: String
    let prompt: String
    let swatch: [Color]
    let symbol: String
    let mood: String

    static let all: [PhotoStyle] = [
        PhotoStyle(
            id: "seiso",
            nameJP: "清楚",
            nameRomaji: "Seiso",
            nameEN: "Pure & Clean",
            tagline: "王道の好印象",
            description: "白シャツに自然光。誰にでも好かれる清潔感のある一枚。",
            prompt: "Transform this person into a stunning Japanese dating app profile photo in the 'seiso' (pure and clean) style. They should be wearing a crisp white blouse or shirt with neat collar, soft natural daylight from a window, against a clean creamy off-white background with very gentle bokeh. Gentle warm smile, looking slightly off-camera. Editorial, magazine-quality. Skin should look natural and fresh, not over-smoothed. Keep facial features and identity exactly the same. Soft Tokyo morning light aesthetic. Square 1:1 framing, head-and-shoulders portrait, slight grain, very tasteful and refined.",
            swatch: [Color(red: 1.00, green: 0.95, blue: 0.85), Color(red: 1.00, green: 0.85, blue: 0.78)],
            symbol: "sun.max.fill",
            mood: "明るい・爽やか"
        ),
        PhotoStyle(
            id: "cafe",
            nameJP: "カフェ",
            nameRomaji: "Café",
            nameEN: "Café Hour",
            tagline: "デート映えする雰囲気",
            description: "おしゃれな喫茶店で、自然な笑顔の一枚。",
            prompt: "Transform this person into a beautiful Japanese dating app profile photo in a stylish Tokyo café. They are seated at a wooden counter, holding a latte cup with both hands at chest level, soft window light from the side. Background: warm bokeh of pendant lights and shelves of beans, café in Daikanyama or Nakameguro vibe. Cozy beige knit or simple sweater. Genuine candid laugh, eyes wrinkled with warmth. Rich shallow depth of field, film-like color grading, warm cinnamon-honey tones. Keep facial features and identity exactly the same. Square 1:1, slightly tilted, lifestyle editorial.",
            swatch: [Color(red: 1.00, green: 0.65, blue: 0.40), Color(red: 0.85, green: 0.45, blue: 0.30)],
            symbol: "cup.and.saucer.fill",
            mood: "ほっこり・あたたか"
        ),
        PhotoStyle(
            id: "sakura",
            nameJP: "桜",
            nameRomaji: "Sakura",
            nameEN: "Cherry Blossoms",
            tagline: "春の柔らかな光",
            description: "桜並木の下、やさしい風と光に包まれて。",
            prompt: "Transform this person into a romantic Japanese dating app profile photo standing under cherry blossom trees in full bloom along Meguro River. Soft pink petals gently falling, dreamy bokeh of pink and white blossoms filling the background, late afternoon spring light, very soft and diffused. Subject wearing a light cream beige trench coat or pastel cardigan. Looking slightly upward with a serene gentle smile, hair softly moving in the breeze. Pastel film aesthetic, warm pink and cream tones, whisper-soft contrast. Keep facial features and identity exactly the same. Square 1:1, head-and-shoulders, magazine portrait quality.",
            swatch: [Color(red: 1.00, green: 0.60, blue: 0.78), Color(red: 0.95, green: 0.40, blue: 0.65)],
            symbol: "leaf.fill",
            mood: "ロマンティック"
        ),
        PhotoStyle(
            id: "office",
            nameJP: "オフィス",
            nameRomaji: "Office",
            nameEN: "Professional",
            tagline: "知的で誠実な印象",
            description: "落ち着いたスーツ姿で、信頼感を演出。",
            prompt: "Transform this person into an elegant professional Japanese dating app profile photo. They are dressed in a tailored navy or charcoal suit (or smart blazer with simple top), photographed in a modern Tokyo office building lobby with soft architectural lighting. Background: blurred floor-to-ceiling windows with city light, subtle warm reflections. Confident calm expression, slight smile. Clean, polished, cinematic editorial portrait, high-end corporate magazine style with shallow depth of field. Keep facial features and identity exactly the same. Square 1:1, head-and-shoulders, refined and trustworthy mood.",
            swatch: [Color(red: 0.30, green: 0.55, blue: 1.00), Color(red: 0.55, green: 0.40, blue: 1.00)],
            symbol: "briefcase.fill",
            mood: "知的・誠実"
        ),
        PhotoStyle(
            id: "yuhi",
            nameJP: "夕日",
            nameRomaji: "Yūhi",
            nameEN: "Golden Hour",
            tagline: "ロマンチックな光",
            description: "魔法の時間。夕陽が肌をやさしく染める。",
            prompt: "Transform this person into a beautiful Japanese dating app profile photo at golden hour on a Shonan beach or Tokyo Bay rooftop. Sun is low, casting warm golden light directly across their face, hair gently lit from behind creating a soft halo. Wearing a cream linen shirt or soft pastel knit. Eyes looking gently to the side with a peaceful smile. Sky in soft amber, peach, and rose tones. Cinematic, dreamy, very warm, slight lens flare, anamorphic film aesthetic. Keep facial features and identity exactly the same. Square 1:1, head-and-shoulders, romantic editorial portrait.",
            swatch: [Color(red: 1.00, green: 0.55, blue: 0.30), Color(red: 1.00, green: 0.30, blue: 0.45)],
            symbol: "sun.haze.fill",
            mood: "シネマティック"
        ),
        PhotoStyle(
            id: "urban",
            nameJP: "ネオン",
            nameRomaji: "Neon",
            nameEN: "Tokyo Street",
            tagline: "おしゃれで都会的",
            description: "夜の表参道。ネオンに溶ける都会の表情。",
            prompt: "Transform this person into a stylish Japanese dating app profile photo on a Tokyo street at night, Omotesando or Shibuya vibe. Soft neon and storefront bokeh in the background — purples, pinks, ambers. Wearing a chic black turtleneck or designer coat. Confident, cool expression with a subtle smile, slight head tilt. Cinematic 35mm film aesthetic, deep contrast but soft skin tones, hint of city sparkle in the eyes. Keep facial features and identity exactly the same. Square 1:1, head-and-shoulders, fashion magazine portrait.",
            swatch: [Color(red: 0.95, green: 0.27, blue: 0.65), Color(red: 0.40, green: 0.30, blue: 1.00)],
            symbol: "moon.stars.fill",
            mood: "クール・スタイリッシュ"
        ),
        PhotoStyle(
            id: "ryokan",
            nameJP: "京都",
            nameRomaji: "Kyōto",
            nameEN: "Travel & Adventure",
            tagline: "活発でアクティブな印象",
            description: "京都の小道。旅好きで好奇心旺盛な雰囲気。",
            prompt: "Transform this person into a charming Japanese dating app profile photo as a traveler in Kyoto's Higashiyama district. Subject walking through traditional sloped stone streets with wooden machiya houses. Wearing a comfortable cream cardigan over a simple shirt or a light beige jacket, small leather crossbody bag hint. Soft golden afternoon light, gentle natural smile mid-stride or pausing to look back. Background: blurred lanterns, traditional shop signs, soft historic atmosphere. Travel-magazine photography style, very warm and inviting. Keep facial features and identity exactly the same. Square 1:1, head-and-shoulders.",
            swatch: [Color(red: 0.45, green: 0.85, blue: 0.65), Color(red: 1.00, green: 0.80, blue: 0.25)],
            symbol: "map.fill",
            mood: "好奇心・元気"
        ),
        PhotoStyle(
            id: "minimal",
            nameJP: "上品",
            nameRomaji: "Jōhin",
            nameEN: "Editorial",
            tagline: "上質で大人の魅力",
            description: "余白の美。ミニマルで洗練された一枚。",
            prompt: "Transform this person into a refined editorial Japanese dating app profile photo. Pure beige or warm taupe seamless studio backdrop, ultra-soft Rembrandt lighting from one side. Wearing simple cashmere knit in oatmeal or camel tone. Calm direct gaze into the camera, very subtle confident smile, gentle warmth in the eyes. High-end fashion magazine quality, MUJI x Vogue Japan aesthetic, beautifully soft skin texture (not over-smoothed), elegant, minimal, mature sophistication. Keep facial features and identity exactly the same. Square 1:1, head-and-shoulders portrait.",
            swatch: [Color(red: 1.00, green: 0.82, blue: 0.55), Color(red: 0.95, green: 0.55, blue: 0.40)],
            symbol: "sparkles",
            mood: "上品・大人"
        )
    ]
}
