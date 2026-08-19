import Foundation

struct MasteryEngine {
    let collections: [MasteryCollection]

    init(collections: [MasteryCollection] = MasteryCatalogue.collections()) { self.collections = collections }

    static func score(difficulty: Difficulty, attempts: Int, hints: Int) -> Int {
        let base = attempts <= 1 ? 96 : attempts == 2 ? 88 : 80
        let bonus = difficulty == .easy ? 0 : difficulty == .medium ? 2 : 4
        return min(100, max(70, base + bonus - max(0, hints) * 3))
    }

    func recordCorrect(player: PlayerSeed, attempts: Int, hints: Int, daily: Bool, careerStats: PlayerCareerStats? = nil, date: Date = Date(), state: inout MasteryState) -> MasteryUpdate {
        let performance = Self.score(difficulty: player.difficulty, attempts: attempts, hints: hints)
        let beforeIDs = Set(state.masteredPlayers.keys)
        let previous = state.masteredPlayers[player.id]
        if var record = previous {
            record.correctCount += 1
            record.bestScore = max(record.bestScore, performance)
            record.bestAttempts = min(record.bestAttempts, attempts)
            record.lowestHints = min(record.lowestHints, hints)
            if let careerStats { record.careerStats = careerStats }
            state.masteredPlayers[player.id] = record
        } else {
            state.masteredPlayers[player.id] = MasteredPlayer(
                playerID: player.id, firstMasteredAt: date, firstDifficulty: player.difficulty,
                firstAttempts: attempts, firstHintsUsed: hints, firstWasDaily: daily,
                unlockScore: performance, bestScore: performance, correctCount: 1,
                bestAttempts: attempts, lowestHints: hints, careerStats: careerStats
            )
        }
        let afterIDs = Set(state.masteredPlayers.keys)
        var deltas: [MasteryCollectionDelta] = []
        var awards: [MasteryAwardRecord] = []
        for collection in collections where collection.category != .global && collection.eligiblePlayerIDs.contains(player.id) {
            let before = collection.eligiblePlayerIDs.intersection(beforeIDs).count
            let after = collection.eligiblePlayerIDs.intersection(afterIDs).count
            if before != after {
                deltas.append(.init(collectionID: collection.id, name: collection.name, icon: collection.icon, category: collection.category, before: before, after: after, total: collection.eligiblePlayerIDs.count))
            }
            let fraction = collection.eligiblePlayerIDs.isEmpty ? 0 : Double(after) / Double(collection.eligiblePlayerIDs.count)
            for milestone in collection.milestones where fraction >= milestone.threshold {
                let awardID = "\(collection.id).\(milestone.tier.rawValue)"
                guard state.earnedAwards[awardID] == nil else { continue }
                let award = MasteryAwardRecord(id: awardID, collectionID: collection.id, tier: milestone.tier, earnedAt: date, reward: milestone.reward)
                state.earnedAwards[awardID] = award
                state.claimedRewardIDs.insert(awardID)
                awards.append(award)
            }
        }
        let regionMasters = collections.filter { $0.category == .region }.allSatisfy { state.earnedAwards["\($0.id).master"] != nil }
        if regionMasters, state.earnedAwards["global-wikiball-globe.master"] == nil,
           let globe = collections.first(where: { $0.id == "global-wikiball-globe" }), let milestone = globe.milestones.first {
            let award = MasteryAwardRecord(id: "global-wikiball-globe.master", collectionID: globe.id, tier: .master, earnedAt: date, reward: milestone.reward)
            state.earnedAwards[award.id] = award
            state.claimedRewardIDs.insert(award.id)
            awards.append(award)
        }
        let priority: [CollectionCategory] = [.global, .region, .league, .country, .special]
        awards.sort { left, right in
            let lhs = collections.first(where: { $0.id == left.collectionID })?.category
            let rhs = collections.first(where: { $0.id == right.collectionID })?.category
            return priority.firstIndex(of: lhs ?? .special)! < priority.firstIndex(of: rhs ?? .special)!
        }
        let totalReward = awards.reduce(MasteryReward()) { .init(xp: $0.xp + $1.reward.xp, coins: $0.coins + $1.reward.coins, cosmeticID: $1.reward.cosmeticID ?? $0.cosmeticID) }
        let current = state.masteredPlayers[player.id]!
        return MasteryUpdate(playerID: player.id, isNewPlayer: previous == nil, scoreImproved: previous.map { current.bestScore > $0.bestScore } ?? false, unlockScore: current.unlockScore, bestScore: current.bestScore, collectionDeltas: deltas, newAwards: awards, reward: totalReward)
    }

    func progress(for collection: MasteryCollection, state: MasteryState) -> MasteryProgress {
        if collection.category == .global {
            let regionCollections = collections.filter { $0.category == .region }
            let mastered = regionCollections.filter { state.earnedAwards["\($0.id).master"] != nil }.count
            let tier: MasteryTier? = state.earnedAwards["\(collection.id).master"] == nil ? nil : .master
            return MasteryProgress(collection: collection, mastered: mastered, total: regionCollections.count, historicalTier: tier)
        }
        let mastered = collection.eligiblePlayerIDs.intersection(state.masteredPlayers.keys).count
        let tier = collection.milestones.map(\.tier).filter { state.earnedAwards["\(collection.id).\($0.rawValue)"] != nil }.max()
        return MasteryProgress(collection: collection, mastered: mastered, total: collection.eligiblePlayerIDs.count, historicalTier: tier)
    }

    func allProgress(state: MasteryState) -> [MasteryProgress] { collections.map { progress(for: $0, state: state) } }

    func collections(containing playerID: String) -> [MasteryCollection] {
        collections.filter { $0.eligiblePlayerIDs.contains(playerID) && $0.category != .global }
    }

    func candidatePools(for collectionID: String, players: [PlayerSeed], state: MasteryState) -> (all: [PlayerSeed], missing: [PlayerSeed]) {
        guard let collection = collections.first(where: { $0.id == collectionID }) else { return ([], []) }
        let all = players.filter { collection.eligiblePlayerIDs.contains($0.id) }
        return (all, all.filter { state.masteredPlayers[$0.id] == nil })
    }
}

enum MasteryCatalogue {
    static func collections(players: [PlayerSeed] = SeedData.players, leagues: [LeagueOption] = SeedData.leagues) -> [MasteryCollection] {
        var result: [MasteryCollection] = []
        let groupedCountries = Dictionary(grouping: players, by: \.nationality)
        for (index, country) in groupedCountries.keys.sorted().enumerated() {
            let ids = Set(groupedCountries[country, default: []].map(\.id))
            guard !ids.isEmpty else { continue }
            result.append(.init(id: "country-\(slug(country))", definitionVersion: 1, name: country, category: .country, icon: flag(country), description: "Master every represented \(country) player.", eligiblePlayerIDs: ids, milestones: milestones(for: .country, key: slug(country)), trophyFamily: "Country Medal", displayOrder: 100 + index))
        }
        for (index, region) in Region.allCases.enumerated() {
            let ids = Set(players.filter { $0.region == region }.map(\.id))
            guard !ids.isEmpty else { continue }
            result.append(.init(id: "region-\(slug(region.rawValue))", definitionVersion: 1, name: regionTrophy(region), category: .region, icon: regionIcon(region), description: "Master players from across \(region.rawValue).", eligiblePlayerIDs: ids, milestones: milestones(for: .region, key: slug(region.rawValue)), trophyFamily: regionTrophy(region), displayOrder: index))
        }
        let leagueNames = ["English Crown", "Iberian Star", "Italian Heritage Cup", "German Meister Shield", "French Elite Trophy", "Stateside Trophy"]
        for (index, league) in leagues.enumerated() {
            let clubs = Set(league.clubs.map { GameRules.normalizeGuess($0) })
            let ids = Set(players.filter { player in player.career.contains { clubs.contains(GameRules.normalizeGuess(GameRules.baseClubName($0.club))) } }.map(\.id))
            guard !ids.isEmpty else { continue }
            let name = index < leagueNames.count ? leagueNames[index] : league.league
            result.append(.init(id: "league-\(league.id)", definitionVersion: 1, name: name, category: .league, icon: "🏟", description: "Collect players with senior careers in the \(league.league).", eligiblePlayerIDs: ids, milestones: milestones(for: .league, key: league.id), trophyFamily: name, displayOrder: 200 + index))
        }
        let travellers = Set(players.filter { seniorClubs($0).count >= 6 }.map(\.id))
        if !travellers.isEmpty {
            result.append(.init(id: "special-journeymen", definitionVersion: 1, name: "Journeymen", category: .special, icon: "✈️", description: "Players who represented six or more senior clubs.", eligiblePlayerIDs: travellers, milestones: milestones(for: .special, key: "journeymen"), trophyFamily: "World Traveller", displayOrder: 300))
        }
        result.append(.init(id: "global-wikiball-globe", definitionVersion: 1, name: "The Wikiball Globe", category: .global, icon: "🌐", description: "Earn Master in all five continental collections.", eligiblePlayerIDs: Set(players.map(\.id)), milestones: [.init(tier: .master, threshold: 1, reward: .init(xp: 1_000, coins: 500, cosmeticID: "wikiball-globe"))], trophyFamily: "Wikiball Globe", displayOrder: 400))
        return result
    }

    static func milestones(for category: CollectionCategory, key: String) -> [MasteryMilestone] {
        let rewards: [MasteryReward]
        switch category {
        case .country: rewards = [.init(xp: 50), .init(coins: 75), .init(xp: 150, cosmeticID: "\(key)-emblem"), .init(xp: 250, coins: 150, cosmeticID: "\(key)-master")]
        case .league: rewards = [.init(xp: 50), .init(coins: 75), .init(xp: 150), .init(xp: 250, coins: 100, cosmeticID: "\(key)-emblem")]
        case .region: rewards = [.init(xp: 100), .init(xp: 150, coins: 75), .init(xp: 300, coins: 150, cosmeticID: "\(key)-frame"), .init(xp: 500, coins: 250, cosmeticID: "\(key)-master")]
        case .special: rewards = [.init(cosmeticID: "travel-badge"), .init(coins: 100), .init(xp: 150, cosmeticID: "journeyman-gold"), .init(xp: 250, coins: 150, cosmeticID: "world-traveller")]
        case .global: rewards = []
        }
        return zip(MasteryTier.allCases, rewards).map { .init(tier: $0.0, threshold: $0.0.threshold, reward: $0.1) }
    }

    static func seniorClubs(_ player: PlayerSeed) -> Set<String> {
        Set(player.career.map { stop in
            var club = GameRules.baseClubName(stop.club)
            if club.hasSuffix(" B") || club.hasSuffix(" C") { club = String(club.dropLast(2)) }
            return club
        })
    }

    static func slug(_ value: String) -> String { GameRules.normalizeGuess(value).replacingOccurrences(of: " ", with: "-") }
    static func regionTrophy(_ region: Region) -> String { switch region { case .europe: return "European Crown"; case .southAmerica: return "Libertadores Chalice"; case .africa: return "African Unity Cup"; case .northAmerica: return "Continental Shield"; case .asiaPacific: return "Pacific Star" } }
    static func regionIcon(_ region: Region) -> String { switch region { case .europe: return "🇪🇺"; case .southAmerica: return "🌎"; case .africa: return "🌍"; case .northAmerica: return "🌎"; case .asiaPacific: return "🌏" } }
    static func flag(_ country: String) -> String { ["Argentina":"🇦🇷", "Australia":"🇦🇺", "Brazil":"🇧🇷", "England":"🏴", "France":"🇫🇷", "Ivory Coast":"🇨🇮", "Portugal":"🇵🇹", "Spain":"🇪🇸", "United States":"🇺🇸", "Uruguay":"🇺🇾"][country] ?? "🏳️" }
}
