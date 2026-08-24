import SwiftUI

@main
struct WikiballApp: App {
    @StateObject private var store: GameStore
    @StateObject private var purchases: PurchaseService

    init() {
        let gameStore = GameStore()
        _store = StateObject(wrappedValue: gameStore)
        _purchases = StateObject(wrappedValue: PurchaseService { amount, transactionID in
            gameStore.creditPurchasedCoins(amount, transactionID: transactionID)
        })
    }

    var body: some Scene {
        WindowGroup {
            WBStartupGate {
                WikiballExperienceRoot()
            }
            .environmentObject(store)
            .environmentObject(purchases)
        }
    }
}
