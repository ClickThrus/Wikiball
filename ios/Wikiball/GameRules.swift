import Foundation

enum GameRules {
    static let hintCost = 20

    static func normalizeGuess(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    static func accepts(_ guess: String, for player: PlayerSeed) -> Bool {
        let normalized = normalizeGuess(guess)
        guard !normalized.isEmpty else { return false }
        return ([player.name] + player.aliases).contains { normalizeGuess($0) == normalized }
    }

    static func missFeedback(for guess: String, player: PlayerSeed) -> MatchFeedbackKind {
        let entered = normalizeGuess(guess)
        guard entered.count >= 4 else { return .farMiss }
        let candidates = ([player.name] + player.aliases).map(normalizeGuess)
        let isClose = candidates.contains { candidate in
            let allowance = max(2, min(3, candidate.count / 5))
            return abs(candidate.count - entered.count) <= allowance && editDistance(entered, candidate) <= allowance
        }
        return isClose ? .nearMiss : .farMiss
    }

    static func baseClubName(_ club: String) -> String {
        club.replacingOccurrences(of: #"^\s*(?:→|&rarr;)\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(
            of: #"\s*\((?:loan|on loan)\)\s*$"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func careerStop(_ stop: CareerStop, overlapsDecadeStarting start: Int) -> Bool {
        let years = stop.years
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
            .filter { $0 >= 1900 && $0 <= 2200 }
        guard let first = years.first else { return false }
        let last = years.dropFirst().first ?? (stop.years.contains("–") || stop.years.contains("-") ? 2200 : first)
        return first <= start + 9 && last >= start
    }

    static func matches(_ player: PlayerSeed, filters: GameFilters, leagues: [LeagueOption] = SeedData.leagues) -> Bool {
        guard filters.difficulty == nil || player.difficulty == filters.difficulty else { return false }
        if let decade = filters.decade, let start = Int(decade.prefix(4)),
           !player.career.contains(where: { careerStop($0, overlapsDecadeStarting: start) }) { return false }
        if let team = filters.team,
           !player.career.contains(where: { baseClubName($0.club).caseInsensitiveCompare(team) == .orderedSame }) { return false }
        guard filters.region == nil || player.region == filters.region else { return false }
        if let leagueID = filters.leagueID {
            guard let league = leagues.first(where: { $0.id == leagueID }) else { return false }
            let normalizedClubs = Set(league.clubs.map { normalizeGuess($0) })
            guard player.career.contains(where: { normalizedClubs.contains(normalizeGuess(baseClubName($0.club))) }) else { return false }
        }
        return true
    }

    static func rewards(for difficulty: Difficulty, attemptsRemaining: Int, streakBeforeWin: Int, dailyBonus: Bool) -> RoundReward {
        let base: (xp: Int, coins: Int) = switch difficulty {
        case .easy: (80, 15)
        case .medium: (120, 22)
        case .hard: (180, 30)
        }
        let attemptsUsedBeforeSuccess = max(0, 3 - attemptsRemaining)
        let multiplier = [1.0, 0.85, 0.70][min(attemptsUsedBeforeSuccess, 2)]
        return RoundReward(
            xp: Int((Double(base.xp) * multiplier).rounded()) + min(streakBeforeWin, 10) * 5 + (dailyBonus ? 50 : 0),
            coins: base.coins + min(streakBeforeWin, 8)
        )
    }

    static func canAwardDaily(profile: PlayerProfile, dateKey: String) -> Bool {
        !profile.rewardedDailyDates.contains(dateKey)
    }

    private static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        var previous = Array(0...right.count)
        for (leftIndex, leftCharacter) in left.enumerated() {
            var current = [leftIndex + 1]
            for (rightIndex, rightCharacter) in right.enumerated() {
                current.append(min(
                    current[rightIndex] + 1,
                    previous[rightIndex + 1] + 1,
                    previous[rightIndex] + (leftCharacter == rightCharacter ? 0 : 1)
                ))
            }
            previous = current
        }
        return previous.last ?? 0
    }
}

struct RoundReward: Equatable {
    let xp: Int
    let coins: Int
}
