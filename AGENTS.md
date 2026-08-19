# Wikiball agent guide

## Product north star

Wikiball should feel like a game first and a database second. Core loop: see a player's club journey → guess → get instant feedback → earn progress → play again.

## Non-negotiables

1. Keep guessing fast, colourful and mobile-first.
2. Fetch player career history from Wikipedia through the official MediaWiki API when possible.
3. Preserve curated fallbacks so network failure never blocks play.
4. Show Wikipedia attribution only after a round resolves; never leak the answer via DOM copy, links, alt text or debug UI before then.
5. Do not add transfer fees until a robust attributable source/parser is defined.
6. Local progress must survive refreshes. Future accounts should migrate it.
7. Rewards encourage play without pay-to-win mechanics.
8. Play filters are first-class: difficulty, decade, club/team and region can be combined.

## Filters

- Decade: include a player if any senior-career stop overlaps the selected decade.
- Team: include a player if their curated career includes that club, stripping `(loan)` for matching.
- Region: currently means the player's football/nationality region: Europe, South America, Africa, North America, Asia-Pacific.
- If a filter combination has no matches, do not silently ignore it. Tell the player and offer Reset filters.

## Progression

Rookie → Prospect → Pro → Star → World Class → Legend. XP controls tiers, coins fund hints, and streaks add bonuses. Difficulty changes base rewards.

## Data quality

Prefer senior career entries from `Infobox football biography` (`years1`, `clubs1`, etc.). Keep loan spells when Wikipedia lists them separately. Clean citations, templates and wiki-link syntax before rendering. If parsing fails, use the explicit curated fallback rather than inventing history.

## Good next Codex tasks

- Unit-test Wikipedia wikitext parsing.
- Expand curated pool to 100+ players and review difficulty/region/team metadata.
- Add server-backed accounts and leaderboards.
- Add friend challenges and shareable results.
- Add achievements and seasonal ladders.
- Improve parser coverage for unusual infobox formatting.
