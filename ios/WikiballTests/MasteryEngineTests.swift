import XCTest
@testable import Wikiball

final class MasteryEngineTests: XCTestCase {
    func testStablePlayerIDsAreUniqueAndRarityMapsFromDifficulty() {
        XCTAssertEqual(Set(SeedData.players.map(\.id)).count, SeedData.players.count)
        XCTAssertTrue(SeedData.players.allSatisfy { !$0.id.contains(" ") })
        XCTAssertEqual(SeedData.players.first { $0.id == "lionel-messi" }?.cardRarity, .common)
        XCTAssertEqual(SeedData.players.first { $0.id == "luis-suarez" }?.cardRarity, .rare)
        XCTAssertEqual(SeedData.players.first { $0.id == "tim-cahill" }?.cardRarity, .elite)
    }

    func testMasteryScoreAndRepeatImprovement() {
        XCTAssertEqual(MasteryEngine.score(difficulty: .easy, attempts: 1, hints: 0), 96)
        XCTAssertEqual(MasteryEngine.score(difficulty: .medium, attempts: 2, hints: 1), 87)
        XCTAssertEqual(MasteryEngine.score(difficulty: .hard, attempts: 3, hints: 0), 84)
        var state = MasteryState.empty
        let engine = MasteryEngine()
        let player = SeedData.players.first { $0.id == "luis-suarez" }!
        let first = engine.recordCorrect(player: player, attempts: 3, hints: 2, daily: false, state: &state)
        let repeatWin = engine.recordCorrect(player: player, attempts: 1, hints: 0, daily: false, state: &state)
        XCTAssertTrue(first.isNewPlayer)
        XCTAssertFalse(repeatWin.isNewPlayer)
        XCTAssertTrue(repeatWin.scoreImproved)
        XCTAssertEqual(state.masteredPlayers.count, 1)
        XCTAssertEqual(state.masteredPlayers[player.id]?.correctCount, 2)
        XCTAssertEqual(state.masteredPlayers[player.id]?.unlockScore, 76)
        XCTAssertEqual(state.masteredPlayers[player.id]?.bestScore, 98)
    }

    func testOnePlayerStarterCollectionAwardsEveryTierOnlyOnce() {
        let player = SeedData.players.first { $0.id == "lionel-messi" }!
        let collection = MasteryCollection(id: "country-argentina", definitionVersion: 1, name: "Argentina", category: .country, icon: "🇦🇷", description: "Test", eligiblePlayerIDs: [player.id], milestones: MasteryCatalogue.milestones(for: .country, key: "argentina"), trophyFamily: "Country Medal", displayOrder: 0)
        let engine = MasteryEngine(collections: [collection])
        var state = MasteryState.empty
        let first = engine.recordCorrect(player: player, attempts: 1, hints: 0, daily: false, state: &state)
        let repeatWin = engine.recordCorrect(player: player, attempts: 1, hints: 0, daily: false, state: &state)
        XCTAssertEqual(first.newAwards.map(\.tier), [.bronze, .silver, .gold, .master])
        XCTAssertEqual(first.reward, MasteryReward(xp: 450, coins: 225, cosmeticID: "argentina-master"))
        XCTAssertTrue(repeatWin.newAwards.isEmpty)
        XCTAssertEqual(repeatWin.reward, MasteryReward())
    }

    func testCollectionExpansionLowersCurrentCompletionWithoutRevokingAwards() {
        let messi = SeedData.players.first { $0.id == "lionel-messi" }!
        let firstDefinition = MasteryCollection(id: "country-argentina", definitionVersion: 1, name: "Argentina", category: .country, icon: "🇦🇷", description: "Test", eligiblePlayerIDs: [messi.id], milestones: MasteryCatalogue.milestones(for: .country, key: "argentina"), trophyFamily: "Country Medal", displayOrder: 0)
        var state = MasteryState.empty
        _ = MasteryEngine(collections: [firstDefinition]).recordCorrect(player: messi, attempts: 1, hints: 0, daily: false, state: &state)
        let expanded = MasteryCollection(id: firstDefinition.id, definitionVersion: 2, name: "Argentina", category: .country, icon: "🇦🇷", description: "Expanded", eligiblePlayerIDs: [messi.id, "new-player"], milestones: firstDefinition.milestones, trophyFamily: "Country Medal", displayOrder: 0)
        let progress = MasteryEngine(collections: [expanded]).progress(for: expanded, state: state)
        XCTAssertEqual(progress.percent, 50)
        XCTAssertEqual(progress.historicalTier, .master)
        XCTAssertNotNil(state.earnedAwards["country-argentina.master"])
    }

    func testLeagueMembershipSupportsOnePlayerInMultipleLeaguesAndJourneymen() {
        let catalogue = MasteryCatalogue.collections()
        let henryLeagues = catalogue.filter { $0.category == .league && $0.eligiblePlayerIDs.contains("thierry-henry") }
        XCTAssertTrue(Set(henryLeagues.map(\.id)).isSuperset(of: ["league-england-premier-league", "league-spain-la-liga", "league-italy-serie-a", "league-france-ligue-1", "league-usa-canada-mls"]))
        XCTAssertTrue(catalogue.first { $0.id == "special-journeymen" }?.eligiblePlayerIDs.contains("didier-drogba") == true)
    }

    func testGlobalTrophyRequiresAllContinentalMasters() {
        let engine = MasteryEngine()
        var state = MasteryState.empty
        var lastUpdate: MasteryUpdate?
        for player in SeedData.players { lastUpdate = engine.recordCorrect(player: player, attempts: 1, hints: 0, daily: false, state: &state) }
        XCTAssertNotNil(state.earnedAwards["global-wikiball-globe.master"])
        XCTAssertTrue(lastUpdate?.newAwards.contains(where: { $0.collectionID == "global-wikiball-globe" }) == true)
        XCTAssertEqual(lastUpdate?.newAwards.first?.collectionID, "global-wikiball-globe")
    }

    func testPlayMissingCandidatePoolsExcludeCollectedCards() {
        let engine = MasteryEngine()
        var state = MasteryState.empty
        let collection = engine.collections.first { $0.id == "region-europe" }!
        let first = SeedData.players.first { collection.eligiblePlayerIDs.contains($0.id) }!
        _ = engine.recordCorrect(player: first, attempts: 1, hints: 0, daily: false, state: &state)
        let pools = engine.candidatePools(for: collection.id, players: SeedData.players, state: state)
        XCTAssertTrue(pools.all.contains(first))
        XCTAssertFalse(pools.missing.contains(first))
        XCTAssertEqual(pools.all.count - pools.missing.count, 1)
    }

    func testMasteryPersistenceAndMalformedPayloadMigration() throws {
        var profile = PlayerProfile()
        let player = SeedData.players[0]
        _ = MasteryEngine().recordCorrect(player: player, attempts: 1, hints: 0, daily: true, state: &profile.mastery)
        let restored = try JSONDecoder().decode(PlayerProfile.self, from: JSONEncoder().encode(profile))
        XCTAssertEqual(restored.mastery, profile.mastery)

        let malformed = #"{"xp":321,"coins":9,"mastery":"broken"}"#.data(using: .utf8)!
        let migrated = try JSONDecoder().decode(PlayerProfile.self, from: malformed)
        XCTAssertEqual(migrated.xp, 321)
        XCTAssertEqual(migrated.coins, 9)
        XCTAssertEqual(migrated.mastery, .empty)
    }
}
