# Wikiball Asset-Driven UI — Implementation Status

Branch: `agent/wikiball-design-system-v1`

This branch converts the native iOS app from screen-by-screen SwiftUI approximation toward a shared asset-driven game UI. It remains separate from `agent/wikiball-mvp` until local simulator screenshot QA is complete.

## Implemented

### Design system

- canonical dark/spectrum palette
- spacing and corner-radius tokens
- semantic typography roles
- responsive metrics and content-width rules
- shared art-backed card component
- shared primary button
- central artwork naming
- documented 70% native SwiftUI / 25% branded artwork / 5% motion approach

### Shared branded components

- canonical main HUD
- logo renderer
- Wikicoin badge
- streak treatment
- tier/rank crest renderer
- custom four-tab bottom navigation
- responsive compact/regular HUD variants
- safe fallback when optional artwork is absent

### Main information architecture

Four main tabs are implemented:

1. Home
2. Play
3. Collection
4. Profile

Home and Play are deliberately different:

- Home = dashboard, Daily state, Career, collection activity and route into Play
- Play = Quick Play, Daily, Versus entry, Custom Game and Featured Leagues

### Home

- branded Play hero
- live profile/XP/coin/streak HUD
- Daily dashboard state
- next Career/trophy context
- Career progress
- Continue Collecting module
- responsive content-driven layout; no large blank spacer dependency

### Play

- branded Quick Play hero
- Daily and Versus mode cards
- Custom Game summary
- unified filter sheet for Difficulty/Era/Region/League/Club
- Featured League shortcuts
- scroll-first responsive composition rather than shrinking every card to one viewport

### Gameplay

- dedicated branded gameplay HUD
- Club Journey timeline
- three-attempt football display
- one native TextField and one FocusState
- Return key uses the same submit path as the button
- wrong guesses preserve focus for quick retry
- hint controls and personal profile hint
- Give Up flow
- horizontal autocomplete suggestions
- responsive compact/regular HUD handling

### Result

- Correct / Full Time states
- celebratory result artwork
- player sticker presentation
- XP / coins / sticker rewards
- Career progress deltas
- Wikipedia-source status after the answer is revealed
- Next Player
- Share Result
- Back to Play
- trophy-unlock celebration

### Collection

- Player Collection header/count
- search
- collected-only filter
- three-column responsive sticker grid
- Standard/Silver/Gold/Spectrum/Missing visual frames
- mystery treatment for uncollected players

### Profile

- canonical avatar/HUD
- current tier
- Career progress
- Stats/Achievements/Locker Room/Season Ticket dashboard tiles
- premium/Season Ticket banner

### Locker Room

- primitive emoji/initial face renderer retired from the canonical avatar display
- 12 original fictional illustrated/vector portrait presets
- six starter/free and six Season Ticket cosmetic presets
- modular background themes
- draft editing model with Cancel/Save
- persisted avatar preset/background using stable IDs
- same canonical avatar renderer used across the new app shell

### Trophy Cabinet

- original League/National/Continental/Global Wikiball trophy families
- Bronze/Silver/Gold/Master state treatment
- cabinet progress cards
- earned-tier preservation
- trophy detail presentation

### Shop

- branded Season Ticket hero
- actual StoreKit product list rather than baked prices
- subscription purchase routing
- Wikicoin pack purchase routing
- Restore Purchases

### Native launch + loading

- `LaunchScreen.storyboard` provides the static pre-SwiftUI launch frame
- launch frame uses the same stadium background and Wikiball logo assets as dynamic startup
- `project.yml` sets `UILaunchStoryboardName: LaunchScreen`
- matching dynamic SwiftUI stadium loading experience
- progress tied to local bootstrap phases rather than a purely fake long timer
- profile restore phase
- local football-data phase
- collection/Career phase
- match-preparation phase
- StoreKit refresh does not gate app launch
- offline/noncritical-service-friendly architecture
- Reduce Motion support

### Artwork pack

Original in-repo vector assets now include:

- logo
- Wikicoin
- streak flame
- XP crest
- avatar frame
- six rank crests
- Home hero/card art
- Play mode/card art
- Versus shield
- result burst
- Season Ticket hero
- six sticker frames/states
- twelve fictional avatars
- four original trophy families
- stadium loading background

See `docs/WIKIBALL_ASSET_MANIFEST.md` for exact asset names and status.

### Build validation

A GitHub Actions macOS/Xcode workflow now:

1. checks out the branch
2. installs XcodeGen
3. generates `Wikiball.xcodeproj`
4. builds the Wikiball scheme for the generic iOS Simulator without code signing

The redesigned native app, SVG asset catalogue and branded launch storyboard compile successfully in CI with Xcode 16.4. The earlier gameplay frame-layout compiler error was fixed before the green build.

## Known limitations / follow-up validation

### Visual screenshot fidelity

The connected environment cannot run the user’s local iPhone 17 Pro/Pro Max Xcode Simulator and compare it with the approved screenshots. Final visual acceptance therefore still requires the local loop:

1. run approved reference device
2. capture simulator screenshot
3. compare side by side / 50% overlay
4. fix top five visual differences
5. repeat

Do not call a screen reference-perfect until that loop is complete.

### Versus networking

The current base branch does not contain a production-ready remote friend-challenge backend that this branch can safely wire into the new card without inventing behaviour. The new Play screen preserves the Versus entry point, but full create/join networking should be connected when the authoritative Versus implementation is merged.

### Profile destinations

Profile visually exposes Stats and Achievements. The branch prioritised the shared shell and core game loop; final dedicated Stats/Achievements navigation should be confirmed against the latest local branch before destructive changes to older profile code. Trophy Cabinet has a reusable standalone view ready to wire.

### StoreKit product catalogue

The Shop deliberately renders the StoreKit products currently defined by the repo. Pricing/product-ID changes should be made in StoreKit/App Store Connect as a separate commercial configuration change, not hard-coded into the visual layer.

### Football media and trademarks

- real-player photos still require per-file Wikimedia Commons commercial-compatible licence/attribution checks
- official club/league marks require separate rights review
- original Wikiball fallback tokens should remain available
- this branch’s new decorative SVGs do not copy official competition trophies or club marks

### Local work may be newer

The user has been iterating in Xcode/Codex outside the connected GitHub branch. Before merging this PR, compare the user’s current local working copy with `agent/wikiball-mvp` so recent local UI/data work is not accidentally overwritten.

## Recommended acceptance pass

Before merging:

- [x] GitHub Actions Xcode build green
- [ ] iPhone 17 Pro screenshot pass
- [ ] iPhone 17 Pro Max screenshot pass
- [ ] one smaller supported iPhone pass
- [ ] keyboard open/closed gameplay pass on simulator/device
- [ ] cold/warm/offline launch visual pass
- [ ] StoreKit test configuration pass
- [ ] avatar Save/Cancel/relaunch persistence pass
- [ ] Quick Play/Daily/Custom round pass
- [ ] Result/Next Player/Share pass
- [ ] collection search/filter pass
- [ ] VoiceOver spot check
- [ ] Reduce Motion spot check

Only after these checks should the PR move from Draft to Ready for Review.
