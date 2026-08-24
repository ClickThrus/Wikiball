# Wikiball Design System v1

## Objective

The approved Wikiball concept renders are the visual north star. Native SwiftUI should **assemble** the brand rather than attempt to redraw every branded treatment with `RoundedRectangle`, `LinearGradient`, SF Symbols, emoji and guessed font sizes.

The target implementation split is approximately:

- **70% native SwiftUI:** layout, live text, buttons, progress, lists, keyboard, accessibility, StoreKit and navigation.
- **25% reviewed artwork assets:** hero panels, card treatments, crests, trophies, sticker frames, avatar art, coins, VS shield and decorative effects.
- **5% motion/effects:** restrained SwiftUI/Core Animation transitions and state feedback.

This is the canonical approach for all new visual work.

## Core rule

> SwiftUI owns structure and behaviour. Reviewed assets own complex brand appearance.

Do not ask each screen to independently recreate the same brand with primitives.

## Canonical visual tokens

Use `ios/Wikiball/WikiballDesignSystem.swift` for:

- palette
- spacing
- radii
- shadows
- typography roles
- responsive metrics
- canonical asset names
- art-backed card shell
- primary game button

Do not add ad-hoc colour literals or random font sizes to new screens unless the reference comparison proves a new token is required.

## Responsive strategy

Do **not** scale the entire app like a screenshot and do **not** let every decorative composition freely reflow like a website.

Use a hybrid approach:

### Art-directed areas

Examples:

- Home hero
- Quick Play hero
- Daily card illustration
- Versus shield/hero
- Result celebration
- Season Ticket hero
- trophy cards
- sticker frames

Preserve their designed composition using:

- stable aspect ratios
- approved artwork backgrounds
- live SwiftUI overlays
- capped proportional art scaling

### Functional areas

Examples:

- search
- keyboards
- filters
- collection grids
- settings
- long career timelines
- lists/sheets

Use normal adaptive SwiftUI:

- `ScrollView`
- `LazyVStack`
- `LazyVGrid`
- `ViewThatFits`
- safe-area insets
- Dynamic Type
- one native keyboard

### Screen-width guidance

`WBResponsiveMetrics` uses the available width to derive:

- compact vs regular margins
- a centred maximum content width
- bounded art scale
- major section spacing

Avoid full-screen `GeometryReader` arithmetic scattered across individual screens.

## Typography

All screen typography should use semantic roles rather than arbitrary values:

- `WBDesign.Typography.hero`
- `screenTitle`
- `cardTitle`
- `body`
- `label`
- `number`

The current mapping uses the rounded system font as a temporary fallback. When the approved commercially licensed font is selected, replace the mapping in one place rather than editing every screen.

## Artwork-backed cards

Use `WBArtCard` for branded panels where appropriate.

Example:

```swift
WBArtCard(
    artworkName: WBArtwork.Home.playHeroBackground,
    cornerRadius: WBDesign.Radius.hero,
    aspectRatio: 1.72,
    fallbackColors: [WBDesign.Palette.blue, WBDesign.Palette.purple]
) {
    HStack {
        VStack(alignment: .leading) {
            Text("PLAY\nWIKIBALL")
                .font(WBDesign.Typography.hero())
            WBPrimaryButton(title: "Play") {
                // navigate to Play
            }
        }
        Spacer()
        WBArtworkImage(name: WBArtwork.Home.playHeroFootball, contentMode: .fit)
            .frame(maxWidth: 150)
    }
    .padding(WBDesign.Spacing.xl)
}
```

The artwork may contain:

- lighting
- texture
- stadium detail
- decorative swooshes
- non-dynamic highlights
- panel edge treatment

The SwiftUI overlay should contain:

- live title/subtitle
- CTA
- dynamic progress
- timers
- counts
- accessibility labels

Never bake live values into the artwork.

## Stretchable / nine-slice artwork

For panels that must change height, export artwork with safe stretch regions.

When an asset has decorative corners/borders:

- preserve corner geometry
- preserve border thickness
- stretch only the interior region
- document cap insets in the asset manifest

If SwiftUI's standard resizable image behaviour cannot preserve the art, implement the single reusable stretchable wrapper once rather than screen-specific hacks.

## Images vs vectors

Prefer:

- PDF/vector for logos, simple icons, crests and geometric badges
- PNG/WebP-derived PNG assets for textured/rendered artwork with transparency
- flattened decorative backgrounds for complex hero treatments

Do not export an entire screen as one image.

## Accessibility

Decorative artwork is accessibility-hidden.

Live controls and labels remain native SwiftUI so they retain:

- VoiceOver
- Dynamic Type where practical
- semantic button behaviour
- hit targets
- native keyboard handling
- localisation capability

## Branding hierarchy

Canonical reusable pieces should include:

1. Wikiball logo
2. main HUD
3. avatar frame
4. coin
5. streak/flame
6. rank crest
7. XP track
8. primary/secondary buttons
9. bottom navigation
10. card shells
11. sticker frames
12. trophy card shells

A visual fix to one canonical component must propagate rather than being copied into each screen.

## Screen implementation order

Freeze and rebuild in this order:

1. Home
2. Play
3. Gameplay
4. Correct Result
5. Collection
6. Profile
7. Trophy Cabinet
8. Shop
9. Versus
10. Versus Result

Do not perform another broad visual rewrite of all screens at once.

For each screen:

1. attach only the approved reference
2. use deterministic DEBUG fixture data
3. implement against the canonical design system
4. capture iPhone reference-device screenshot
5. compare side-by-side
6. use a 50% opacity overlay if practical
7. fix the five largest discrepancies
8. freeze reusable components before moving on

## What not to do

Avoid:

- emoji as production icons
- SF Symbols standing in for major branded graphics
- random one-off gradients
- AI-generated assets with inconsistent perspective/style inside the app
- photoreal player/avatar stand-ins
- screen-wide screenshot backgrounds containing baked text
- absolute positioning for ordinary functional content
- arbitrary `Spacer()` blocks used to imitate screenshots
- separate HUD/avatar/nav implementations per screen

## Design source of truth

The approved screenshot is a visual target, but it must be converted into a measurable design source before fidelity work is considered complete.

For each screen record:

- reference viewport
- horizontal margins
- section heights
- card aspect ratios
- corner radii
- text roles/sizes
- asset bounds
- major gaps
- bottom safe-area behaviour

Figma is recommended for this handoff, but the implementation must not depend on Figma at runtime.
