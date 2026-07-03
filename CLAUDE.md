# Widgeon — daily-ritual lock screen widget app (iOS)

One app bundling daily-reset widgets around a lock-screen pet. Strategy (decided, research-backed): single app, not a portfolio; freemium later (gate characters/widget slots — tangible unlocks). Brand: clean, mature, playful; "New you at midnight."

## Build
- xcodegen project: edit `project.yml` → `xcodegen generate` (never edit .xcodeproj directly)
- Build: `xcodebuild -project Widgeon.xcodeproj -scheme Widgeon -destination 'platform=iOS Simulator,id=<udid>' CODE_SIGNING_ALLOWED=NO build`
- **Use the iOS 26.1 simulator** (one exists named EmojiTest-26-1) — the 26.3 sim runtime is missing the emoji font (everything renders as ? boxes). Not an app bug.
- Screenshots: launch with `SIMCTL_CHILD_WIDGEON_TAB=pet|today|settings` to pick the tab.
- No signing team yet — user's Apple Developer enrollment ($99) is pending; sim-only until then (blocks device install, HealthKit on device, TestFlight).

## Architecture
- App target (`App/`) + WidgetKit extension (`Widgets/`); `Shared/` compiles into both. App Group `group.com.webbhayes.widgeon` (falls back to standard defaults unsigned). Bundle ids `com.webbhayes.widgeon` / `.widgets` (must stay prefixed).
- 10 widget kinds: vocab (500 words) / roast (80, vulgar) / affirmation (60, first-person) / wisdom (KJV + Stoic, citation-accurate) / fortune (48) / life progress / steps (HealthKit) / drink (goal mode or booze-limit mode w/ 6am reset) / pet (interactive) / XP level.
- Daily content: deterministic `(dayNumber * prime) % count` per bank (JSON in `Shared/Resources/`), flips at local midnight, offline.
- Interactive widgets via App Intents: `FeedPetIntent`, `AddDrinkIntent`.
- Life XP (`XPModel`): feed +20, train +30, hydration +15; once/day dedupe; quadratic levels.
- Pet: 6 characters (duck/cat/dog/turtle/plant/pixel), **XP-driven evolution** (petXP thresholds 20/100/250/500/900/1500/2500), step goal auto-trains (+30, the Digimon mechanic), feed streaks. Codable state: new fields must be optional (back-compat with saved state).

## Design handoff (from claude.ai Claude Design)
Source: `~/Downloads/Widgeon Daily Ritual App.zip` (README + HTML prototype; pixel sprite data embedded in the HTML as string arrays). Tokens: gold #FFC44D on navy #0B0D24; **day/night flip at 6:30am/pm** (day: mint #E7F5EC→#F3F8E6, ink #183A2A, accent #22A868); Instrument Serif (bundled) for display type.
- Phase 1 DONE (commit e6bf853): Palette struct in `Shared/Theme.swift`, fonts bundled, XP evolution.
- Phase 2 DONE (uncommitted): all app + widget views re-skinned to `Theme.palette()` day/night + Instrument Serif display type, accents unified to gold. `Theme.nextFlip(after:)` + `BrandBackground`; `DailyProvider` emits a timeline entry at each 6:30 flip so home-screen widgets flip on schedule (accessory/lock widgets are system-tinted, left as-is). Settings uses a custom serif header (system large title can't be recolored on a transparent scroll-edge nav bar).
- **Phase 3 (next): pixel sprite engine** — port sprites from the handoff HTML to SwiftUI Canvas (replaces emoji; the Tamagotchi look).
- Phase 4: meadow as Pet-screen live background (dawn→night sky) + countdown lock widget. (Full-screen live lock wallpaper is impossible on iOS — decided adaptation.)
- Then: train card UI, heart particles, evolution celebration banner.

## Roadmap after design
Achievements, gacha egg collection (needs art), pixel town, more wisdom traditions (Quran/Gita/Dhammapada — source translations carefully, citations exact), roast spice toggle (clean default for 4+ rating), StoreKit unlock, app icon (a widgeon is a duck).

## Working style
User wants token-efficient work: lean prose, targeted reads, batch edits, no decorative recaps. Scriptable prototypes (12 scripts) still live in the user's iCloud Scriptable folder — separate from this repo.
