# Wikiball Production Asset Manifest

This manifest defines the artwork that should replace primitive SwiftUI approximations. Asset names match `WBArtwork` in `WikiballDesignSystem.swift` where already defined.

## Export rules

For each raster asset:

- design at 3x the intended point size where practical
- use transparent PNG for layered illustrations
- remove unused transparent margins
- export sRGB
- avoid baked live text/numbers
- keep compression visually lossless at phone scale

For vector/PDF assets:

- preserve vectors
- use a single-scale PDF where supported by Xcode asset catalogues
- ensure any fonts are outlined if text is intentionally part of the logo artwork

Every asset should have:

- source design file/frame
- production owner/source
- licence or internal-creation status
- intended screens
- point-size target
- whether it is stretchable
- cap insets if stretchable

## P0 — shared brand assets

| Asset name | Type | Purpose | Notes |
|---|---|---|---|
| `WBLogoFull` | vector/PDF | Full Wikiball logo | Canonical logo used in HUD/loading/result |
| `WBCoin` | vector/PDF | Wikicoin icon | No emoji fallback in production |
| `WBStreakFlame` | vector/PDF | Streak icon | Match approved HUD style |
| `WBXPCrest` | vector/PDF | XP/rank crest shell | Rank-specific artwork may later split by tier |
| `WBAvatarFrame` | PNG/PDF | Canonical profile frame | Must work at small HUD and large Profile sizes |

## P0 — Home

| Asset name | Type | Purpose | Dynamic overlay |
|---|---|---|---|
| `WBHomePlayHeroBackground` | PNG | Blue/purple hero treatment, stadium/lighting texture | title, subtitle, CTA |
| `WBHomePlayHeroFootball` | transparent PNG | Hero football/pitch illustration | none |
| `WBHomeDailyBackground` | PNG/stretchable | Purple Daily status card treatment | timer, reward, state, CTA |
| `WBHomeCareerBackground` | PNG/stretchable | Career progress card treatment | progress, rank, next reward |

Recommended hero art ratio: approximately 1.65–1.80 width/height based on final measured reference.

## P0 — Play

| Asset name | Type | Purpose |
|---|---|---|
| `WBPlayQuickBackground` | PNG | Quick Play hero visual treatment |
| `WBPlayDailyBackground` | PNG/stretchable | Daily mode card |
| `WBPlayVersusBackground` | PNG/stretchable | Versus mode card |
| `WBPlayCustomBackground` | PNG/stretchable | Custom Game panel |
| `WBVersusShield` | vector/PDF | Shared VS shield |

## P0 — result / collection

| Asset | Type | Purpose |
|---|---|---|
| `WBResultCorrectBurst` | transparent PNG | Correct-result celebratory burst/glow |
| `WBStickerStandard` | vector/PNG | Standard sticker frame |
| `WBStickerBronze` | vector/PNG | Bronze sticker frame |
| `WBStickerSilver` | vector/PNG | Silver sticker frame |
| `WBStickerGold` | vector/PNG | Gold sticker frame |
| `WBStickerSpectrum` | vector/PNG | Spectrum/foil sticker frame |
| `WBStickerMissing` | vector/PNG | Mystery silhouette frame |

Sticker frames must contain no real-player portrait and no live player name.

## P1 — Profile / Career

Produce consistent rank/progression assets for:

- Rookie
- Prospect
- Pro
- Star
- World Class
- Legend

Career cards should use a shared shell plus live league/country progress rather than unique flattened cards for every league.

## P1 — Trophy Cabinet

Create original Wikiball trophy artwork, not replicas of protected competition trophies.

Families:

- league
- national
- continental
- global

Material variants:

- Bronze
- Silver
- Gold
- Master/Spectrum

Suggested original continental concepts:

- European Crown
- Libertadores-inspired but original chalice concept (do not trace real trophy)
- African Unity Cup
- Continental Shield
- Pacific Star
- Wikiball Globe

## P1 — Shop

| Asset name | Type | Purpose |
|---|---|---|
| `WBShopSeasonTicketBackground` | PNG | Premium purple/gold Season Ticket hero |
| `WBShopCoinPackSmall` | PNG | 100 coin pack |
| `WBShopCoinPackMedium` | PNG | 350 coin pack |
| `WBShopCoinPackLarge` | PNG | 800 coin pack |

Price and plan text must remain live StoreKit-backed text.

## P1 — Locker Room/avatar

Use complete illustrated portrait presets first rather than constructing faces from SwiftUI primitives.

Production target:

- 24–40 cohesive head-and-shoulder portrait presets
- identical crop/pose/lighting/style
- transparent background
- no real footballer likeness
- no club logos

Optional modular layers:

- compatible accessories
- profile frames
- backgrounds
- shirt colour mask only if art is designed for it

Do not expose customisation controls without production-quality art for that control.

## P2 — Loading

Create:

- static launch background matching first frame of loading view
- dynamic stadium/tunnel background
- optional blue light sweep overlay

Keep logo and progress text live where possible in the dynamic loading view. Native launch screen remains static.

## Nine-slice / stretchable candidates

Likely candidates:

- Daily card shell
- Versus card shell
- Career card shell
- setup/configuration panels
- profile stat cards

Before implementation, record cap insets from the design source. Do not guess them independently in each screen.

## Rights review

Before public commercial release:

- real-player photos: confirm Wikimedia Commons per-file commercial-compatible licence and store attribution metadata
- official club/league marks: rights review required; Wikipedia availability does not equal commercial reuse permission
- fallback club/league tokens: use original Wikiball artwork
- fonts: confirm commercial mobile-app embedding rights

## Asset handoff checklist

An asset is production-ready only when:

- [ ] source frame/file is known
- [ ] name matches manifest
- [ ] correct dimensions/crop
- [ ] no live text baked in
- [ ] licence/source recorded
- [ ] Retina quality verified
- [ ] dark-background contrast verified
- [ ] small-size rendering checked
- [ ] Xcode asset catalogue import checked
- [ ] simulator screenshot compared to approved reference
