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

## Next validation

The first Codex/Xcode task should be to generate the project, build the iOS target, fix compile warnings/errors, and add a small XCTest suite for filtering and Wikipedia parsing before expanding the player database.
