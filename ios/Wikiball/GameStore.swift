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
        var reward = RoundReward(xp: 0, coins: 0)
        let daily: Bool
    }

    @Published var profile: PlayerProfile
    @Published var filters = GameFilters()
    @Published var round: RoundState?
    @Published var guess = ""
    @Published var message = ""
    @Published var isLoading = false
    @Published var feedbackPulse = 0
    @Published var successPulse = 0
    @Published var warningPulse = 0
    @Published var matchMoment: MatchMoment?
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: soundKey) }
    }

    private let wiki = WikipediaService()
    private let audio = AudioFeedbackService()
    private let profileKey = "wikiball.profile.v1"
    private let soundKey = "wikiball.sound.enabled"

    init() {
        soundEnabled = UserDefaults.standard.object(forKey: soundKey) == nil
            ? true
            : UserDefaults.standard.bool(forKey: soundKey)
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let saved = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            profile = saved
        } else {
            profile = PlayerProfile()
        }
    }

    var filteredPlayers: [PlayerSeed] {
        SeedData.players.filter { GameRules.matches($0, filters: filters) }
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
        defer { isLoading = false }
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
    }

    func surpriseMe() async {
        resetFilters()
        await startRound()
    }

    func submitGuess() {
        guard var round, !round.resolved else { return }
        let entered = guess.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !entered.isEmpty else { return }
        round.guesses.append(entered)
        if GameRules.accepts(entered, for: round.seed) {
            self.round = round
            presentFeedback(.goal)
            finishRound(won: true)
        } else {
            let miss = GameRules.missFeedback(for: entered, player: round.seed)
            presentFeedback(miss)
            if round.attempts <= 1 {
                self.round = round
                finishRound(won: false)
            } else {
                round.attempts -= 1
                self.round = round
                message = miss == .nearMiss ? "So close — that one was just wide." : "That one’s landed in the crowd. Try again."
            }
        }
        guess = ""
    }

    func buyHint() {
        guard var round, !round.resolved, round.hints < 3 else { return }
        guard profile.coins >= GameRules.hintCost else {
            message = "You need \(GameRules.hintCost) coins for another hint."
            return
        }
        profile.coins -= GameRules.hintCost
        profile.hintsUsed += 1
        round.hints += 1
        self.round = round
        message = "Hint unlocked · −20 coins"
        feedbackPulse += 1
        if soundEnabled { audio.play(.hint) }
        saveProfile()
    }

    @discardableResult
    func creditPurchasedCoins(_ amount: Int, transactionID: UInt64) -> Bool {
        guard amount > 0, !profile.processedPurchaseIDs.contains(transactionID) else { return false }
        profile.processedPurchaseIDs.insert(transactionID)
        profile.coins += amount
        saveProfile()
        return true
    }

    func giveUp() { finishRound(won: false) }

    func resetFilters() {
        filters = GameFilters()
        message = ""
    }

    func closeRound() {
        round = nil
        matchMoment = nil
        guess = ""
        message = ""
    }

    func shareText() -> String? {
        guard let round, round.resolved else { return nil }
        let attemptsUsed = round.guesses.count
        let result: String
        if round.won {
            result = String(repeating: "⬜", count: max(0, attemptsUsed - 1)) + "🟩" + String(repeating: "⬜", count: max(0, 3 - attemptsUsed))
        } else if attemptsUsed == 0 {
            result = "🏳️ Gave up"
        } else {
            result = String(repeating: "⬛", count: min(attemptsUsed, 3)) + String(repeating: "⬜", count: max(0, 3 - attemptsUsed))
        }
        let mode = round.daily ? "Daily #\(Self.dailyNumber())" : "Quick Play"
        return "WIKIBALL ⚽️\n\n\(mode)\n\(result)\n🔥 Streak \(profile.streak) · \(currentTier.name)\n\nCan you get it?"
    }

    private func finishRound(won: Bool) {
        guard var round, !round.resolved else { return }
        let dateKey = Self.dayKey()
        let dailyAlreadyRewarded = round.daily && !GameRules.canAwardDaily(profile: profile, dateKey: dateKey)
        let reward = won && !dailyAlreadyRewarded
            ? GameRules.rewards(for: round.seed.difficulty, attemptsRemaining: round.attempts, streakBeforeWin: profile.streak, dailyBonus: round.daily)
            : RoundReward(xp: 0, coins: 0)

        round.resolved = true
        round.won = won
        round.reward = reward
        self.round = round
        profile.played += 1
        if won {
            profile.correct += 1
            profile.streak += 1
            profile.bestStreak = max(profile.bestStreak, profile.streak)
            profile.xp += reward.xp
            profile.coins += reward.coins
            switch round.seed.difficulty {
            case .easy: profile.easyCorrect += 1
            case .medium: profile.mediumCorrect += 1
            case .hard: profile.hardCorrect += 1
            }
            if round.daily && !dailyAlreadyRewarded {
                profile.rewardedDailyDates.insert(dateKey)
                profile.dailyCompleted += 1
            }
            message = dailyAlreadyRewarded
                ? "Correct! Daily bonus already collected — replay for fun."
                : "Correct! +\(reward.xp) XP · +\(reward.coins) coins"
        } else {
            profile.streak = 0
            message = "It was \(round.seed.name)."
        }
        saveProfile()
    }

    private func presentFeedback(_ kind: MatchFeedbackKind) {
        let moment = MatchMoment(kind: kind)
        matchMoment = moment
        if soundEnabled { audio.play(kind) }
        if kind == .goal { successPulse += 1 } else { warningPulse += 1 }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(kind == .goal ? 1.35 : 1.05))
            guard self?.matchMoment?.id == moment.id else { return }
            self?.matchMoment = nil
        }
    }

    private func dailyPlayer() -> PlayerSeed? {
        let score = Self.dayKey().unicodeScalars.reduce(0) { $0 + Int($1.value) }
        guard !SeedData.players.isEmpty else { return nil }
        return SeedData.players[score % SeedData.players.count]
    }

    static func dayKey(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func dailyNumber(for date: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? calendar.startOfDay(for: date)
        let day = calendar.startOfDay(for: date)
        return max(1, (calendar.dateComponents([.day], from: start, to: day).day ?? 0) + 1)
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
}
