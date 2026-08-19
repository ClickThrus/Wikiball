# Wikiball ⚽️

Wikiball is a native iOS football guessing game: identify the player from their chronological senior-club career, with career history fetched from Wikipedia's MediaWiki API.

## Primary app: iOS

The product is now a **native SwiftUI iPhone app**. Development should focus on `ios/`.

### Native MVP

- Guess players from club + year history
- Live Wikipedia career fetching with curated fallbacks
- Easy / Medium / Hard difficulty
- Combinable filters for decade, club/team, player region, and league/country
- Daily Challenge + Quick Play
- XP, Wikicoins, streaks and progression tiers
- Rookie → Prospect → Pro → Star → World Class → Legend
- Three-attempt rounds and purchasable hints
- Native persistence using UserDefaults
- Native Share Sheet results
- SwiftUI menus, haptics and iPhone-first interaction

## Open in Xcode

The native project definition is `ios/project.yml`, using XcodeGen so project settings stay reviewable in source control.

From the `ios` directory:

```bash
xcodegen generate
open Wikiball.xcodeproj
```

The deployment target is iOS 17+.

## Data approach

Each player seed contains a Wikipedia page title plus a curated fallback career. At round load, Wikiball requests wikitext through the official MediaWiki API and extracts `yearsN` / `clubsN` fields from the football biography infobox. If the request or parser fails, the curated fallback keeps the game playable.

League/country filters are career-based: for example, selecting `England · Premier League` means players who have played for a Premier League club, rather than only English-nationality players.

Every resolved round links back to its Wikipedia source. Transfer fees remain out of scope until a robust attributable data approach is defined.

## Web prototype

The existing React/Vite files are an early prototype and are **not the primary product**. Keep them only as reference while native iOS reaches feature parity; do not add new product features there.

See `AGENTS.md` for Codex product rules and implementation guardrails.

Wikiball is not affiliated with Wikipedia, FIFA, UEFA, any football club, league, or player.
