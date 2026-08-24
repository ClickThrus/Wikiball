# Wikiball agent guide

## Product north star

Wikiball is a **native iOS football game**. It should feel like a game first and a database second. Core loop: see a player's club journey → guess → get instant feedback → earn progress → play again.

## Platform

1. `ios/` is the primary product and must receive all new feature work.
2. Use native SwiftUI and Apple platform APIs where practical. Do not wrap the web prototype in a WebView.
3. Target iPhone first. iPad can come later.
4. The root React/Vite prototype is reference-only until native reaches parity; do not extend it with new product features.

## Non-negotiables

1. Keep guessing fast, colourful, touch-first and native-feeling.
2. Fetch player career history from Wikipedia through the official MediaWiki API when possible.
3. Preserve curated fallbacks so network failure never blocks play.
4. Show Wikipedia attribution only after a round resolves; never leak the answer through links, accessibility labels, debug UI, logging, previews or share metadata beforehand.
5. Do not add transfer fees until a robust attributable source/parser is defined.
6. Local progress must survive relaunches. Future accounts should migrate it.
7. Rewards encourage play without pay-to-win mechanics.
8. Play filters are first-class and combinable: difficulty, decade, club/team, region, and league/country.

## Visual system — non-negotiable

1. Approved Wikiball concept renders are visual targets. Do not independently reinterpret the brand on each screen.
2. SwiftUI owns **layout, behaviour, live text, accessibility and state**. Complex brand appearance should come from reviewed assets in `Assets.xcassets`.
3. Do not try to recreate major branded artwork primarily from `RoundedRectangle`, ad-hoc `LinearGradient`, emoji or SF Symbols.
4. Use `ios/Wikiball/WikiballDesignSystem.swift` for canonical palette, spacing, radii, typography roles, responsive metrics, asset names and shared visual components.
5. Reuse one canonical HUD, avatar renderer, coin treatment, rank treatment, button system and bottom navigation rather than duplicating them per screen.
6. Art-directed panels should preserve their approved composition with stable aspect ratios and asset-backed backgrounds. Functional content such as lists, filters, search and keyboard input should remain genuinely adaptive SwiftUI.
7. Do not scale an entire screen screenshot as the production UI. Do not bake live labels, progress, prices or user data into artwork.
8. For every fidelity task: attach only the approved reference for that screen, use deterministic DEBUG fixture data, capture an actual simulator screenshot, compare/overlay it, fix the five largest discrepancies, then freeze reusable components before moving on.
9. New screens must remain responsive on smaller and larger supported iPhones. Prefer scrolling/stacking over aggressive shrinking or fixed-height hacks.
10. See `docs/WIKIBALL_DESIGN_SYSTEM.md` and `docs/WIKIBALL_ASSET_MANIFEST.md` before doing visual reconstruction work.

## Filters

- Decade: include a player if any senior-career stop overlaps the selected decade.
- Team: include a player if their curated career includes that club, stripping `(loan)` for matching.
- Region: means the player's football/nationality region: Europe, South America, Africa, North America, Asia-Pacific.
- League/country: career-based. Example: `England · Premier League` includes players who played for a mapped Premier League club regardless of nationality.
- If a combination has no matches, do not silently ignore filters. Tell the player and make resetting easy.

## Progression

Rookie → Prospect → Pro → Star → World Class → Legend. XP controls tiers, Wikicoins fund hints, and streaks add bonuses. Difficulty changes base rewards.

## iOS experience

- Prefer native SwiftUI navigation, sheets, menus, ShareLink, sensory feedback/haptics, Dynamic Type and VoiceOver-safe components.
- The career timeline is the hero of the round screen.
- Keep controls reachable with one hand and avoid dense forms.
- Never require sign-up for the core game.
- Daily Challenge should be deterministic for the same local calendar date.

## Data quality

Prefer senior career entries from `Infobox football biography` (`years1`, `clubs1`, etc.). Keep loan spells when Wikipedia lists them separately. Clean citations, templates and wiki-link syntax before rendering. If parsing fails, use the explicit curated fallback rather than inventing history.

## Good next Codex tasks

- Generate/open the Xcode project from `ios/project.yml` and fix any compile issues.
- Import the P0 assets from `docs/WIKIBALL_ASSET_MANIFEST.md`, then rebuild Home first against the approved reference using the shared design system.
- Add screenshot/reference-device visual regression checks for the canonical Home/Play components.
- Add unit tests for Wikipedia wikitext parsing and filter matching.
- Expand the curated player pool to 100+ players with reviewed league/region metadata.
- Add app icon, launch experience and App Store-ready branding.
- Add achievements, seasonal ladders and Game Center leaderboards.
- Add friend challenges and richer shareable result cards.
- Consider iCloud/account sync after the local game loop is stable.
