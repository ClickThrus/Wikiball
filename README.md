# Wikiball ⚽️

Wikiball is a colourful football guessing game: identify the player from their chronological senior-club career, with career history fetched directly from Wikipedia's MediaWiki API.

## MVP

- Guess players from club + year history
- Live Wikipedia infobox parsing with curated fallbacks
- Easy / Medium / Hard difficulty
- Filters for decade, club/team and player region
- Daily Challenge + endless play
- XP, coins, streaks and tier progression
- Hints and three-attempt rounds
- Persistent local profile and stats
- Mobile-first responsive UI

## Run locally

```bash
npm install
npm run dev
```

Build with `npm run build`.

## Data approach

Each player seed contains a Wikipedia page title plus a curated fallback career. At round load, Wikiball requests wikitext through the official MediaWiki API and extracts `yearsN` / `clubsN` fields from the football biography infobox. If the live request or parser fails, the fallback keeps the game playable.

Every resolved round links back to its Wikipedia source. Transfer fees are intentionally out of scope for the first MVP because chronological senior-club history is more consistently represented in biography infoboxes.

See `AGENTS.md` for Codex product rules and implementation guardrails.

Wikiball is not affiliated with Wikipedia, FIFA, UEFA, any football club, or any player.
