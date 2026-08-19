import Foundation
import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    struct RoundState: Identifiable {
        let id = UUID()
        let seed: PlayerSeed
        var career: [CareerStop]
        var usedLiveWikipedia: Bool
        var attempts = 3
        var hints = 0
        var guesses: [String] = []
        var resolved = false
        var won = false
        let daily: Bool
    }

    @Published var profile: PlayerProfile
    @Published var filters = GameFilters()
    @Published var round: RoundState?
    @Published var guess = ""
    @Published var message = ""
    @Published var isLoading = false
    @Published var feedbackPulse = 0

    private let wiki = WikipediaService()
    private let profileKey = "wikiball.profile.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let saved = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            profile = saved
        } else {
            profile = PlayerProfile()
        }
    }

    var filteredPlayers: [PlayerSeed] {
        SeedData.players.filter { player in
            (filters.difficulty == nil || player.difficulty == filters.difficulty) &&
            matchesDecade(player) &&
            (filters.team == nil || player.career.contains { SeedData.baseClubName($0.club) == filters.team }) &&
            (filters.region == nil || player.region == filters.region) &&
            matchesLeague(player)
        }
    }

    var currentTier: Tier {
        SeedData.tiers.last(where: { profile.xp >= $0.minimumXP }) ?? SeedData.tiers[0]
    }

    var nextTier: Tier? {
        guard let index = SeedData.tiers.firstIndex(where: { $0.id == currentTier.id }), index + 1 < SeedData.tiers.count else { return nil }
        return SeedData.tiers[index + 1]
    }

    var tierProgress: Double {
        guard let nextTier else { return 1 }
        let completed = Double(profile.xp - currentTier.minimumXP)
        let span = Double(nextTier.minimumXP - currentTier.minimumXP)
        return min(max(completed / span, 0), 1)
    }

    var selectedLeague: LeagueOption? {
        guard let id = filters.leagueID else { return nil }
        return SeedData.leagues.first(where: { $0.id == id })
    }

    func startRound(daily: Bool = false) async {
        let seed: PlayerSeed?
        if daily {
            seed = dailyPlayer()
        } else {
            seed = filteredPlayers.randomElement()
        }
        guard let seed else {
            message = "No players match that combination yet. Try removing a filter."
            return
        }

        isLoading = true
        message = ""
        guess = ""
        var career = seed.career
        var live = false
        do {
            career = try await wiki.career(for: seed.wikipediaTitle)
            live = true
        } catch {
            live = false
        }
        round = RoundState(seed: seed, career: career, usedLiveWikipedia: live, daily: daily)
        isLoading = false
    }

    func submitGuess() {
        guard var round, !round.resolved else { return }
        let entered = guess.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !entered.isEmpty else { return }
        round.guesses.append(entered)
        let accepted = [round.seed.name] + round.seed.aliases
        if accepted.contains(where: { normalize($0) == normalize(entered) }) {
            self.round = round
            finishRound(won: true)
        } else if round.attempts <= 1 {
            self.round = round
            finishRound(won: false)
        } else {
            round.attempts -= 1
            self.round = round
            message = "Not that player — have another go."
            feedbackPulse += 1
        }
        guess = ""
    }

    func buyHint() {
        guard var round, !round.resolved, round.hints < 3 else { return }
        guard profile.coins >= 20 else {
            message = "You need 20 coins for another hint."
            return
        }
        profile.coins -= 20
        round.hints += 1
        self.round = round
        message = "Hint unlocked · −20 coins"
        saveProfile()
    }

    func giveUp() { finishRound(won: false) }

    func resetFilters() {
        filters = GameFilters()
        message = ""
    }

    func closeRound() {
        round = nil
        guess = ""
        message = ""
    }

    func shareText() -> String? {
        guard let round, round.resolved else { return nil }
        let result = round.won ? "🟩" : "⬛️"
        let attemptsUsed = 4 - round.attempts
        return "Wikiball ⚽️\n\(result) \(round.daily ? "Daily" : "Career") · \(attemptsUsed)/3\n🔥 \(profile.streak) streak · \(currentTier.name)\nCan you name the player from the journey?"
    }

    private func finishRound(won: Bool) {
        guard var round, !round.resolved else { return }
        let alreadyPlayedDaily = round.daily && profile.lastDaily == todayKey()
        let reward: (xp: Int, coins: Int) = switch round.seed.difficulty {
        case .easy: (80, 15)
        case .medium: (120, 22)
        case .hard: (180, 30)
        }
        let usedAttempts = 3 - round.attempts
        let attemptMultiplier = max(0.55, 1.0 - Double(usedAttempts) * 0.15)
        let streakBonus = won ? min(profile.streak, 10) * 5 : 0
        let dailyBonus = won && round.daily && !alreadyPlayedDaily ? 50 : 0
        let earnedXP = won && !alreadyPlayedDaily ? Int((Double(reward.xp) * attemptMultiplier).rounded()) + streakBonus + dailyBonus : 0
        let earnedCoins = won && !alreadyPlayedDaily ? reward.coins + min(profile.streak, 8) : 0

        round.resolved = true
        round.won = won
        self.round = round
        profile.played += 1
        if won {
            profile.correct += 1
            profile.streak += 1
            profile.bestStreak = max(profile.bestStreak, profile.streak)
            profile.xp += earnedXP
            profile.coins += earnedCoins
            message = "Correct! +\(earnedXP) XP · +\(earnedCoins) coins"
        } else {
            profile.streak = 0
            message = "It was \(round.seed.name)."
        }
        if round.daily { profile.lastDaily = todayKey() }
        feedbackPulse += 1
        saveProfile()
    }

    private func matchesLeague(_ player: PlayerSeed) -> Bool {
        guard let league = selectedLeague else { return true }
        return player.career.contains { league.clubs.contains(SeedData.baseClubName($0.club)) }
    }

    private func matchesDecade(_ player: PlayerSeed) -> Bool {
        guard let decade = filters.decade, let start = Int(decade.prefix(4)) else { return true }
        let end = start + 9
        return player.career.contains { stop in
            let years = stop.years.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }.filter { $0 >= 1900 }
            guard let first = years.first else { return false }
            let last = years.dropFirst().first ?? (stop.years.contains("–") ? 2100 : first)
            return first <= end && last >= start
        }
    }

    private func dailyPlayer() -> PlayerSeed? {
        let score = todayKey().unicodeScalars.reduce(0) { $0 + Int($1.value) }
        guard !SeedData.players.isEmpty else { return nil }
        return SeedData.players[score % SeedData.players.count]
    }

    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func normalize(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
}
