# Wikiball Production Asset Manifest

This manifest defines the artwork used by the asset-driven native SwiftUI design system. The current branch contains an original in-repo SVG starter pack so branded surfaces are no longer approximated with generic SwiftUI shapes. SVGs preserve vectors in the Xcode asset catalogue and can later be replaced one-for-one by refined Figma/illustrator exports without changing screen code.

## Status legend

- ✅ Implemented and wired
- 🟡 Implemented starter asset; visual refinement/simulator comparison still required
- ⬜ Planned

## Export rules

For raster replacements, design at 3x the intended point size where practical, use transparent sRGB PNGs for layered illustrations, remove unnecessary transparent margins, avoid baking live text/numbers, and keep compression visually lossless at phone scale.

For vector assets, preserve vector representation in Xcode. Any intentionally embedded lettering must be outlined. Every externally supplied asset must have source, ownership/licence, intended screens and production-review status recorded.

## Shared brand assets

| Status | Asset name | Type | Purpose |
|---|---|---|---|
| ✅ | `WBLogoFull` | SVG | Canonical Wikiball mark used in HUD/loading/result |
| ✅ | `WBCoin` | SVG | Wikicoin icon |
| ✅ | `WBStreakFlame` | SVG | Streak icon |
| ✅ | `WBXPCrest` | SVG | Generic XP/rank crest fallback |
| ✅ | `WBAvatarFrame` | SVG | Canonical spectrum profile frame |

## Home

| Status | Asset name | Type | Purpose |
|---|---|---|---|
| ✅ | `WBHomePlayHeroBackground` | SVG | Blue/purple stadium hero surface |
| ✅ | `WBHomePlayHeroFootball` | SVG | Layered hero football artwork |
| ✅ | `WBHomeDailyBackground` | SVG | Purple Daily dashboard surface |
| ✅ | `WBHomeCareerBackground` | SVG | Career/progression dashboard surface |

Live overlays remain SwiftUI: title, CTA, Daily state, progress, rewards and counters.

## Play

| Status | Asset name | Type | Purpose |
|---|---|---|---|
| ✅ | `WBPlayQuickBackground` | SVG | Quick Play hero |
| ✅ | `WBPlayDailyBackground` | SVG | Daily mode card |
| ✅ | `WBPlayVersusBackground` | SVG | Versus mode card |
| ✅ | `WBPlayCustomBackground` | SVG | Custom Game card |
| ✅ | `WBVersusShield` | SVG | Original Wikiball VS shield |

## Result / Collection

| Status | Asset name | Type | Purpose |
|---|---|---|---|
| ✅ | `WBResultCorrectBurst` | SVG | Correct-result celebratory glow/burst |
| ✅ | `WBStickerStandard` | SVG | Standard sticker frame |
| ✅ | `WBStickerBronze` | SVG | Bronze sticker frame |
| ✅ | `WBStickerSilver` | SVG | Silver sticker frame |
| ✅ | `WBStickerGold` | SVG | Gold sticker frame |
| ✅ | `WBStickerSpectrum` | SVG | Spectrum/foil sticker frame |
| ✅ | `WBStickerMissing` | SVG | Mystery/missing sticker frame |

Sticker art contains no player likeness or live player name. Real-player imagery remains a separate licensed-media layer.

## Career rank crests

| Status | Asset |
|---|---|
| ✅ | `WBRankRookie` |
| ✅ | `WBRankProspect` |
| ✅ | `WBRankPro` |
| ✅ | `WBRankStar` |
| ✅ | `WBRankWorldClass` |
| ✅ | `WBRankLegend` |

The shared `WBRankCrestView` selects these assets dynamically from the user’s current tier.

## Trophy Cabinet

Original Wikiball trophy families are implemented rather than replicas of real-world competition trophies.

| Status | Asset | Family |
|---|---|---|
| ✅ | `WBTrophyLeague` | League |
| ✅ | `WBTrophyNational` | Country/National |
| ✅ | `WBTrophyContinental` | Region/Continental |
| ✅ | `WBTrophyGlobal` | Special/Global |

Bronze/Silver/Gold/Master are represented by state/material treatment around the original family artwork. Earned historical tiers remain preserved in the data model.

## Shop

| Status | Asset name | Type | Purpose |
|---|---|---|---|
| ✅ | `WBShopSeasonTicketBackground` | SVG | Premium purple/gold Season Ticket hero |
| ⬜ | `WBShopCoinPackSmall` | SVG/PNG | Coin-pack illustration |
| ⬜ | `WBShopCoinPackMedium` | SVG/PNG | Coin-pack illustration |
| ⬜ | `WBShopCoinPackLarge` | SVG/PNG | Coin-pack illustration |

Price and plan text remain live StoreKit-backed data and must never be baked into artwork.

## Locker Room / fictional avatars

The production architecture is preset-first rather than a primitive SwiftUI face builder.

Implemented starter catalogue:

- ✅ `WBAvatar01`
- ✅ `WBAvatar02`
- ✅ `WBAvatar03`
- ✅ `WBAvatar04`
- ✅ `WBAvatar05`
- ✅ `WBAvatar06`
- ✅ `WBAvatar07`
- ✅ `WBAvatar08`
- ✅ `WBAvatar09`
- ✅ `WBAvatar10`
- ✅ `WBAvatar11`
- ✅ `WBAvatar12`

All twelve are original fictional vector portraits using a consistent head-and-shoulders composition. The first six are free presets; the latter six are wired as Season Ticket cosmetics. Background/theme customisation is modular and persisted separately.

Longer-term target remains 24–40 reviewed presets with identical crop/pose/lighting and additional compatible accessories. No real footballer likenesses or official club logos should be introduced into user-avatar art.

## Loading

| Status | Asset | Purpose |
|---|---|---|
| ✅ | `WBLoadingStadiumBackground` | Dynamic native SwiftUI loading scene |
| 🟡 | Static native launch artwork | First-frame match still needs local Xcode launch-screen verification |

The dynamic loading screen is wired to actual local bootstrap phases and does not block on StoreKit, ads or external network services.

## Stretching / responsiveness

Current SVG artwork is generally rendered with aspect-fill/fit inside responsive containers rather than being distorted. When a refined raster card replaces an SVG, preserve its corners using cap-inset/stretchable-image treatment where required. Good candidates are Daily, Versus, Career and configuration card surfaces.

## Rights review

Before public commercial release:

- real-player photos: confirm Wikimedia Commons per-file commercial-compatible licence and persist attribution metadata
- official club/league marks: separate rights review required; Wikipedia availability does not equal commercial reuse permission
- fallback club/league tokens: original Wikiball artwork only
- fonts: confirm commercial mobile-app embedding rights before adding bundled display fonts
- externally supplied artwork: record creator/source/licence in this manifest or a linked rights register

The SVG starter pack currently in this branch is original in-repo Wikiball artwork created for the project and contains no official club/league marks or real-player likenesses.

## Production handoff checklist

An asset is production-ready only when:

- [x] stable asset name exists
- [x] live text/numbers are not baked into card surfaces
- [x] Xcode asset-catalogue entry exists for implemented starter art
- [x] fallback behaviour exists if an asset is unavailable
- [ ] iPhone 17 Pro simulator screenshot compared to approved reference
- [ ] iPhone 17 Pro Max simulator screenshot compared to approved reference
- [ ] smaller supported iPhone checked for clipping/scrolling
- [ ] refined art source frame/file archived where applicable
- [ ] external licence/source recorded where applicable
- [ ] Retina/detail review completed for any future raster replacements
