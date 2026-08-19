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

## Validation status

- XcodeGen project generation succeeds from `project.yml`.
- Core Swift sources type-check with Swift 6.2 and the non-UI rules/parser checks pass.
- The live MediaWiki parser is smoke-tested against a current football biography page.
- `WikiballTests` covers normalization, aliases, filters, rewards, daily replay protection, save migration and Wikipedia parsing.

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
