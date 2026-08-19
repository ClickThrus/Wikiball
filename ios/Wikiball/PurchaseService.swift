import Foundation
import StoreKit

@MainActor
final class PurchaseService: ObservableObject {
    enum ProductID {
        static let clubMonthly = "com.wikiball.club.monthly"
        static let clubAnnual = "com.wikiball.club.annual"
        static let coins100 = "com.wikiball.coins.100"
        static let coins300 = "com.wikiball.coins.300"
        static let coins700 = "com.wikiball.coins.700"

        static let subscriptions: Set<String> = [clubMonthly, clubAnnual]
        static let all: Set<String> = subscriptions.union([coins100, coins300, coins700])
    }

    enum PurchaseError: LocalizedError {
        case failedVerification
        var errorDescription: String? { "The App Store could not verify this purchase." }
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isClubMember = false
    @Published private(set) var isLoading = false
    @Published private(set) var purchasingProductID: String?
    @Published var statusMessage: String?

    private let creditCoins: @MainActor (Int, UInt64) -> Bool
    private var updatesTask: Task<Void, Never>?

    init(creditCoins: @escaping @MainActor (Int, UInt64) -> Bool) {
        self.creditCoins = creditCoins
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handle(update)
            }
        }
    }

    deinit { updatesTask?.cancel() }

    var subscriptions: [Product] {
        products.filter { ProductID.subscriptions.contains($0.id) }
            .sorted { $0.id == ProductID.clubMonthly && $1.id != ProductID.clubMonthly }
    }

    var coinPacks: [Product] {
        products.filter { Self.coinAmount(for: $0.id) != nil }
            .sorted { (Self.coinAmount(for: $0.id) ?? 0) < (Self.coinAmount(for: $1.id) ?? 0) }
    }

    func prepare() async {
        guard products.isEmpty else {
            await refreshEntitlements()
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: ProductID.all)
            await refreshEntitlements()
            if products.isEmpty { statusMessage = "The shop is temporarily unavailable. Please try again later." }
        } catch {
            statusMessage = "Couldn’t load the shop. Check your connection and try again."
        }
    }

    func purchase(_ product: Product) async {
        guard purchasingProductID == nil else { return }
        purchasingProductID = product.id
        statusMessage = nil
        defer { purchasingProductID = nil }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                try await process(verified(verification))
                statusMessage = Self.coinAmount(for: product.id) == nil
                    ? "Welcome to Wikiball Club!"
                    : "Wikicoins added to your balance."
            case .pending:
                statusMessage = "Purchase pending approval. Your access will update automatically."
            case .userCancelled:
                break
            @unknown default:
                statusMessage = "The purchase could not be completed."
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusMessage = isClubMember ? "Wikiball Club restored." : "No active Club membership was found."
        } catch {
            statusMessage = "Couldn’t restore purchases. Please try again."
        }
    }

    func refreshEntitlements() async {
        var clubActive = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if ProductID.subscriptions.contains(transaction.productID),
               transaction.revocationDate == nil,
               (transaction.expirationDate ?? .distantFuture) > Date(),
               !transaction.isUpgraded {
                clubActive = true
                grantCoinsIfNeeded(for: transaction)
            }
        }
        isClubMember = clubActive
    }

    static func coinAmount(for productID: String) -> Int? {
        switch productID {
        case ProductID.coins100: return 100
        case ProductID.coins300: return 300
        case ProductID.coins700: return 700
        default: return nil
        }
    }

    static func renewalCoins(for productID: String) -> Int? {
        switch productID {
        case ProductID.clubMonthly: return 100
        case ProductID.clubAnnual: return 1_200
        default: return nil
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await process(transaction)
    }

    private func process(_ transaction: Transaction) async {
        if transaction.revocationDate == nil { grantCoinsIfNeeded(for: transaction) }
        await transaction.finish()
        await refreshEntitlements()
    }

    private func grantCoinsIfNeeded(for transaction: Transaction) {
        guard let amount = Self.coinAmount(for: transaction.productID) ?? Self.renewalCoins(for: transaction.productID) else { return }
        _ = creditCoins(amount, transaction.id)
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw PurchaseError.failedVerification
        }
    }
}
