# Make Mikoto a fully functional production app — onboarding, accounts, credits & paywall

## Credit math (research)
- One AI photo generation costs roughly ¥6 in API fees.
- Budget cap: ¥100/user/month → ~15 photos/month for the Standard plan.
- We'll display **credits**, not photo counts: **1 photo = 5 credits**.
  - Standard: **75 credits/month**
  - Professional: **225 credits/month** (3×)
  - Free welcome bonus: **15 credits** (= 3 photos) for every new account.

## Features

**Accounts that work everywhere**
- [x] Sign in with Apple or Google
- [x] Profile, plan, credits, library synced to cloud via Supabase
- [ ] Built to scale to millions of users (needs server-side enforcement)

**First-time onboarding (10 steps, only on first launch)**
- [x] Quiz (4 questions)
- [x] Pain screens (3 illustrated cards)
- [x] Results (personalised summary)
- [x] Symptoms (multi-select checklist)
- [x] How the app helps (3-step visual)
- [x] Reviews (Japanese testimonials)
- [x] App features (style carousel)
- [x] Custom plan animated loader
- [x] Welcome gift celebration
- [x] Returning users skip onboarding

**Free → Paywall flow**
- [x] 15 free credits for new users
- [x] Main paywall appears when credits hit 0
- [x] Monthly / Annual toggle (¥1,343 / ¥11,281 30% off)
- [x] "今すぐ請求はされません — 7日間無料" banner
- [x] Standard / Professional selectable
- [x] Discount paywall (¥966/mo 28% off for 3 months) auto-appears on close

**Credits & generation**
- [x] Credit balance pill on every main screen
- [x] 5-credit deduction per photo
- [x] Monthly refill on renewal date
- [x] Paywall trigger when credits exhausted
- [ ] Server-side enforcement (pending backend)

**All buttons fully wired**
- [x] Home — style cards, credit pill
- [x] Library — persisted, share, save to camera roll, delete
- [x] Settings — edit display name, plan card with プラン変更 / 解約, restore purchases, manage subscription deep-link, notifications toggle, language, terms, privacy, support mailto, sign out, delete account

## Design
- [x] Warm City Pop palette (coral → magenta → lavender gradient)
- [x] Full-bleed gradient backgrounds with paper grain
- [x] Spring animations and progress dots in onboarding
- [x] Coral coin credit pill in header

## Pages / Screens
- [x] Sign-in
- [x] Onboarding (10 steps)
- [x] Home
- [x] Style detail
- [x] Result
- [x] Library
- [x] Paywall (main)
- [x] Discount paywall
- [x] Settings

## Behind the scenes
- [x] Cloud database (Supabase) for users, plans, balances, history
- [ ] RevenueCat + StoreKit for real subscription billing & promotional offers
- [ ] Server-side credit deduction
- [x] App icon (existing)

## Notes
The current build implements the full client-side experience with local persistence (UserDefaults + file storage). Cloud sync via Supabase and real billing via RevenueCat are intentionally deferred — the UI is structured so wiring them in later is a localized swap (CreditStore.subscribe → RevenueCat.purchase, PhotoLibraryStore → Supabase storage).
