# Wikiball iOS

This is the primary Wikiball product.

## Setup

1. Install XcodeGen if it is not already installed.
2. Run `xcodegen generate` from this directory.
3. Open `Wikiball.xcodeproj` in Xcode.
4. Select an iPhone simulator and run.

The app targets iOS 17+ and is built with SwiftUI.

## Current native features

- Daily Challenge and Quick Play
- Wikipedia-backed career history with curated fallback data
- Difficulty, decade, team, region and league/country filters
- XP, Wikicoins, streaks and tier progression
- Hints and three attempts per round
- Local persistence
- Native share results
- Wikipedia source attribution after a round resolves
- StoreKit 2 Club subscriptions and consumable Wikicoin top-ups
- Animated goal, near-miss and far-miss match feedback with native haptics and generated audio cues
- Looping intro and main-game background music with automatic screen-based switching
- Wikipedia player portraits with on-device background removal for correct-answer celebrations
- Layered stadium ambience plus dedicated crowd reactions for goals, near misses and far misses
- Animated, themed hint cards and varied career-card backgrounds
- Custom profiles with a typed display name, emoji or initials avatar, badge colours, favourite club/player and optional personal connection hints
- Wikiball Mastery with unique player cards, country/continental/league progress, Journeymen sets and permanent milestone history
- The Clubhouse with Trophy Cabinet, featured trophies, Play Missing rounds and Club-only presentation themes
- Optional attributed senior appearances/goals on collected cards when Wikipedia data is complete
- Debug-only unlimited testing access for free hints, repeat Daily rewards and Clubhouse themes without weakening Release entitlements

## Validation status

- XcodeGen project generation succeeds from `project.yml`.
- Core Swift sources type-check with Swift 6.2 and the non-UI rules/parser checks pass.
- The live MediaWiki parser is smoke-tested against a current football biography page.
- `WikiballTests` covers normalization, aliases, filters, rewards, daily replay protection, save migration and Wikipedia parsing.
- The shared run scheme uses `Configuration.storekit` for local subscription and coin-pack testing.

A full iOS build, XCTest run and simulator smoke test still require a Mac with the full Xcode app selected via `xcode-select`; Command Line Tools alone cannot provide the iOS SDK or Simulator.

## App Store baseline

- Display name: `Wikiball`
- Deployment target: iOS 17
- Devices: iPhone
- Current placeholder bundle identifier: `com.wikiball.app` (replace with the App Store team identifier before signing)
- Version/build numbers use Xcode defaults until the TestFlight release workflow is configured
- No privacy-sensitive permissions are requested
- `Assets.xcassets/AppIcon.appiconset` contains a replaceable placeholder icon

The generated `.xcodeproj` is intentionally ignored. Regenerate it from `project.yml` after pulling project changes.

## Monetization setup

Create matching products in App Store Connect before TestFlight:

- `com.wikiball.club.monthly`
- `com.wikiball.club.annual`
- `com.wikiball.coins.100`
- `com.wikiball.coins.300`
- `com.wikiball.coins.700`

Monthly and annual Club products belong in one subscription group; Wikicoin packs are consumables. StoreKit supplies customer-facing localized prices. Purchased coin credits are deduplicated by verified transaction ID and never expire.

Before production submission, complete App Store Connect paid-app agreements, tax and banking details, product localizations/review screenshots, and the app privacy-policy URL. The MVP ledger is local; move purchased balances and processed transaction IDs to an authenticated server using the App Store Server API before cross-device accounts or high-volume sales.
