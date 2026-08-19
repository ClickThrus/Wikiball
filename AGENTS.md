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
- Add unit tests for Wikipedia wikitext parsing and filter matching.
- Expand the curated player pool to 100+ players with reviewed league/region metadata.
- Add app icon, launch experience and App Store-ready branding.
- Add achievements, seasonal ladders and Game Center leaderboards.
- Add friend challenges and richer shareable result cards.
- Consider iCloud/account sync after the local game loop is stable.
