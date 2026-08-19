import XCTest
@testable import Wikiball

final class PurchaseServiceTests: XCTestCase {
    func testProductCoinMappings() {
        XCTAssertEqual(PurchaseService.coinAmount(for: PurchaseService.ProductID.coins100), 100)
        XCTAssertEqual(PurchaseService.coinAmount(for: PurchaseService.ProductID.coins300), 300)
        XCTAssertEqual(PurchaseService.coinAmount(for: PurchaseService.ProductID.coins700), 700)
        XCTAssertNil(PurchaseService.coinAmount(for: PurchaseService.ProductID.clubMonthly))
    }

    func testSubscriptionRenewalCoinMappings() {
        XCTAssertEqual(PurchaseService.renewalCoins(for: PurchaseService.ProductID.clubMonthly), 100)
        XCTAssertEqual(PurchaseService.renewalCoins(for: PurchaseService.ProductID.clubAnnual), 1_200)
        XCTAssertNil(PurchaseService.renewalCoins(for: PurchaseService.ProductID.coins100))
    }

    @MainActor
    func testCoinCreditsAreIdempotentByTransaction() {
        let store = GameStore()
        let initialCoins = store.profile.coins
        let transactionID = UInt64.random(in: 10_000_000...UInt64.max)
        XCTAssertTrue(store.creditPurchasedCoins(100, transactionID: transactionID))
        XCTAssertEqual(store.profile.coins, initialCoins + 100)
        XCTAssertFalse(store.creditPurchasedCoins(100, transactionID: transactionID))
        XCTAssertEqual(store.profile.coins, initialCoins + 100)
    }

    func testPurchaseLedgerSurvivesProfileEncoding() throws {
        var profile = PlayerProfile()
        profile.displayName = "Alex"
        profile.avatarEmoji = "🏆"
        profile.favoriteTeam = "Chelsea"
        profile.favoritePlayer = "Didier Drogba"
        profile.processedPurchaseIDs = [42, 99]
        let data = try JSONEncoder().encode(profile)
        let restored = try JSONDecoder().decode(PlayerProfile.self, from: data)
        XCTAssertEqual(restored.processedPurchaseIDs, [42, 99])
        XCTAssertEqual(restored.displayName, "Alex")
        XCTAssertEqual(restored.avatarEmoji, "🏆")
        XCTAssertEqual(restored.favoriteTeam, "Chelsea")
        XCTAssertEqual(restored.favoritePlayer, "Didier Drogba")
    }
}
