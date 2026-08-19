import Foundation

enum CardRarity: String, Codable, CaseIterable, Identifiable {
    case common, rare, elite, icon, legend
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self { case .common: return "🟢"; case .rare: return "🔵"; case .elite: return "🟣"; case .icon: return "🟡"; case .legend: return "🌈" }
    }
}

enum CollectionCategory: String, Codable, CaseIterable, Identifiable {
    case country, region, league, special, global
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum MasteryTier: String, Codable, CaseIterable, Identifiable, Comparable {
    case bronze, silver, gold, master
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var threshold: Double { switch self { case .bronze: return 0.25; case .silver: return 0.5; case .gold: return 0.75; case .master: return 1 } }
    static func < (lhs: Self, rhs: Self) -> Bool { allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)! }
}

struct MasteryReward: Codable, Equatable {
    let xp: Int
    let coins: Int
    let cosmeticID: String?
    init(xp: Int = 0, coins: Int = 0, cosmeticID: String? = nil) { self.xp = xp; self.coins = coins; self.cosmeticID = cosmeticID }
}

struct MasteryMilestone: Codable, Equatable, Identifiable {
    let tier: MasteryTier
    let threshold: Double
    let reward: MasteryReward
    var id: String { tier.rawValue }
}

struct MasteryCollection: Identifiable, Equatable {
    let id: String
    let definitionVersion: Int
    let name: String
    let category: CollectionCategory
    let icon: String
    let description: String
    let eligiblePlayerIDs: Set<String>
    let milestones: [MasteryMilestone]
    let trophyFamily: String
    let displayOrder: Int
}

struct MasteredPlayer: Codable, Equatable {
    let playerID: String
    let firstMasteredAt: Date
    let firstDifficulty: Difficulty
    let firstAttempts: Int
    let firstHintsUsed: Int
    let firstWasDaily: Bool
    let unlockScore: Int
    var bestScore: Int
    var correctCount: Int
    var bestAttempts: Int
    var lowestHints: Int
    var careerStats: PlayerCareerStats?

    var isFirstTouch: Bool { firstAttempts == 1 }
    var isNoHints: Bool { firstHintsUsed == 0 }
    var isDailyEdition: Bool { firstWasDaily }
    var isPerfect: Bool { firstAttempts == 1 && firstHintsUsed == 0 }
    var needsImprovement: Bool { bestScore < 85 }
}

struct PlayerCareerStats: Codable, Equatable {
    let seniorAppearances: Int?
    let seniorGoals: Int?
    let transferFees: [TransferFee]?
}

struct TransferFee: Codable, Equatable, Identifiable {
    let fromClub: String
    let toClub: String
    let amount: String
    let sourceURL: URL
    var id: String { "\(fromClub)-\(toClub)-\(amount)" }
}

struct MasteryAwardRecord: Codable, Equatable, Identifiable {
    let id: String
    let collectionID: String
    let tier: MasteryTier
    let earnedAt: Date
    let reward: MasteryReward
}

struct MasteryState: Codable, Equatable {
    var masteredPlayers: [String: MasteredPlayer] = [:]
    var earnedAwards: [String: MasteryAwardRecord] = [:]
    var claimedRewardIDs: Set<String> = []
    var featuredTrophyIDs: [String] = []
    var selectedCabinetThemeID = "classic"

    static let empty = MasteryState()
}

struct MasteryProgress: Equatable, Identifiable {
    let collection: MasteryCollection
    let mastered: Int
    let total: Int
    let historicalTier: MasteryTier?
    var id: String { collection.id }
    var fraction: Double { total == 0 ? 0 : Double(mastered) / Double(total) }
    var percent: Int { Int((fraction * 100).rounded()) }
    var nextMilestone: MasteryMilestone? { collection.milestones.first(where: { $0.threshold > fraction }) }
    var playersToNext: Int {
        guard let nextMilestone else { return 0 }
        return max(0, Int(ceil(nextMilestone.threshold * Double(total))) - mastered)
    }
}

struct MasteryCollectionDelta: Equatable, Identifiable {
    let collectionID: String
    let name: String
    let icon: String
    let category: CollectionCategory
    let before: Int
    let after: Int
    let total: Int
    var id: String { collectionID }
}

struct MasteryUpdate: Equatable {
    let playerID: String
    let isNewPlayer: Bool
    let scoreImproved: Bool
    let unlockScore: Int
    let bestScore: Int
    let collectionDeltas: [MasteryCollectionDelta]
    let newAwards: [MasteryAwardRecord]
    let reward: MasteryReward
}

enum CabinetTheme: String, Codable, CaseIterable, Identifiable {
    case classic, spectrum, midnight
    var id: String { rawValue }
    var name: String { switch self { case .classic: return "Classic Cabinet"; case .spectrum: return "Spectrum Cabinet"; case .midnight: return "Midnight Stadium" } }
    var requiresClub: Bool { self != .classic }
}
