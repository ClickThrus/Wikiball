import XCTest
@testable import Wikiball

final class GameRulesTests: XCTestCase {
    private let player = PlayerSeed(
        name: "Zlatan Ibrahimović",
        aliases: ["Zlatan", "Ibra"],
        wikipediaTitle: "Zlatan Ibrahimović",
        difficulty: .hard,
        nationality: "Sweden",
        region: .europe,
        position: "Striker",
        career: [
            CareerStop(years: "1999–2001", club: "Malmö FF"),
            CareerStop(years: "2001–2004", club: "Ajax"),
            CareerStop(years: "2010–2011", club: "AC Milan (loan)"),
            CareerStop(years: "2016–2018", club: "Manchester United")
        ]
    )

    func testGuessNormalizationHandlesAccentsCaseAndPunctuation() {
        XCTAssertEqual(GameRules.normalizeGuess("  ZLATAN Ibrahimović! "), "zlatanibrahimovic")
        XCTAssertTrue(GameRules.accepts("Zlatan Ibrahimovic", for: player))
        XCTAssertTrue(GameRules.accepts("IBRA", for: player))
        XCTAssertFalse(GameRules.accepts("Ronaldo", for: player))
    }

    func testWrongGuessFeedbackDistinguishesCloseTyposFromDifferentPlayers() {
        XCTAssertEqual(GameRules.missFeedback(for: "Zlatan Ibrahomovic", player: player), .nearMiss)
        XCTAssertEqual(GameRules.missFeedback(for: "Ibar", player: player), .nearMiss)
        XCTAssertEqual(GameRules.missFeedback(for: "Lionel Messi", player: player), .farMiss)
        XCTAssertEqual(GameRules.missFeedback(for: "Z", player: player), .farMiss)
    }

    func testProfileHintsUseFavouriteClubAndPlayerContext() {
        var profile = PlayerProfile()
        XCTAssertNil(GameRules.profileHint(for: player, profile: profile, players: [player]))

        profile.favoriteTeam = "Manchester United"
        XCTAssertEqual(
            GameRules.profileHint(for: player, profile: profile, players: [player]),
            "Your favourite club — Manchester United — appears in this career."
        )

        profile.favoriteTeam = nil
        profile.favoritePlayer = "Zlatan Ibrahimović"
        XCTAssertEqual(
            GameRules.profileHint(for: player, profile: profile, players: [player]),
            "Your favourite player is especially relevant to this round."
        )
    }

    func testDecadeUsesAnyOverlappingCareerStop() {
        XCTAssertTrue(GameRules.careerStop(player.career[0], overlapsDecadeStarting: 2000))
        XCTAssertTrue(GameRules.matches(player, filters: GameFilters(decade: "2000s")))
        XCTAssertFalse(GameRules.matches(player, filters: GameFilters(decade: "2020s")))
    }

    func testLoanClubMatchesBaseClub() {
        XCTAssertEqual(GameRules.baseClubName("AC Milan (loan)"), "AC Milan")
        XCTAssertEqual(GameRules.baseClubName("→ AC Milan (loan)"), "AC Milan")
        XCTAssertTrue(GameRules.matches(player, filters: GameFilters(team: "AC Milan")))
    }

    func testRegionAndLeagueFiltering() {
        XCTAssertTrue(GameRules.matches(player, filters: GameFilters(region: .europe)))
        XCTAssertFalse(GameRules.matches(player, filters: GameFilters(region: .africa)))
        XCTAssertTrue(GameRules.matches(player, filters: GameFilters(leagueID: "england-premier-league")))
        XCTAssertFalse(GameRules.matches(player, filters: GameFilters(leagueID: "usa-canada-mls")))
    }

    func testAllFiltersApplyTogether() {
        let matching = GameFilters(difficulty: .hard, decade: "2010s", team: "Manchester United", region: .europe, leagueID: "england-premier-league")
        XCTAssertTrue(GameRules.matches(player, filters: matching))
        var failing = matching
        failing.region = .southAmerica
        XCTAssertFalse(GameRules.matches(player, filters: failing))
    }

    func testRewardsScaleByAttemptAndDailyCannotBeClaimedTwice() {
        XCTAssertEqual(GameRules.rewards(for: .easy, attemptsRemaining: 3, streakBeforeWin: 0, dailyBonus: false), RoundReward(xp: 80, coins: 15))
        XCTAssertEqual(GameRules.rewards(for: .medium, attemptsRemaining: 2, streakBeforeWin: 0, dailyBonus: false).xp, 102)
        XCTAssertEqual(GameRules.rewards(for: .hard, attemptsRemaining: 1, streakBeforeWin: 2, dailyBonus: true).xp, 186)

        var profile = PlayerProfile()
        XCTAssertTrue(GameRules.canAwardDaily(profile: profile, dateKey: "2026-08-19"))
        profile.rewardedDailyDates.insert("2026-08-19")
        XCTAssertFalse(GameRules.canAwardDaily(profile: profile, dateKey: "2026-08-19"))
    }

    func testProfileDecodesOldSavesWithoutLosingProgress() throws {
        let oldJSON = #"{"xp":900,"coins":12,"streak":3,"bestStreak":4,"correct":5,"played":7,"lastDaily":"2026-08-18"}"#.data(using: .utf8)!
        let profile = try JSONDecoder().decode(PlayerProfile.self, from: oldJSON)
        XCTAssertEqual(profile.xp, 900)
        XCTAssertEqual(profile.displayName, "Player")
        XCTAssertEqual(profile.avatarEmoji, "⚽️")
        XCTAssertEqual(profile.avatarColor, "purple")
        XCTAssertFalse(profile.avatarUsesInitials)
        XCTAssertTrue(profile.rewardedDailyDates.contains("2026-08-18"))
        XCTAssertEqual(profile.hintsUsed, 0)
    }
}

private extension GameFilters {
    init(difficulty: Difficulty? = nil, decade: String? = nil, team: String? = nil, region: Region? = nil, leagueID: String? = nil) {
        self.init()
        self.difficulty = difficulty
        self.decade = decade
        self.team = team
        self.region = region
        self.leagueID = leagueID
    }
}
