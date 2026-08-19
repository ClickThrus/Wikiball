import Foundation
import CoreGraphics
import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    struct RoundState: Identifiable {
        let id = UUID()
        let seed: PlayerSeed
        var career: [CareerStop]
        var usedLiveWikipedia: Bool
        var careerStats: PlayerCareerStats?
        var attempts = 3
        var hints = 0
        var guesses: [String] = []
        var resolved = false
        var won = false
        var reward = RoundReward(xp: 0, coins: 0)
        var masteryUpdate: MasteryUpdate?
        let profileHint: String?
        var profileHintRevealed = false
        let daily: Bool
        let sourceCollectionID: String?
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
    @Published var successPlayerImage: CGImage?
    @Published var masteryCelebration: MasteryAwardRecord?
    @Published var additionalMasteryAwards = 0
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: soundKey)
            syncBackgroundMusic()
        }
    }

    private let wiki = WikipediaService()
    private let audio = AudioFeedbackService()
    let masteryEngine = MasteryEngine()
    private let profileKey = "wikiball.profile.v1"
    private let soundKey = "wikiball.sound.enabled"
    private var isAppActive = true

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

    var masteryProgress: [MasteryProgress] { masteryEngine.allProgress(state: profile.mastery) }
    var masteredPlayerCount: Int { profile.mastery.masteredPlayers.count }
    var nextMasteryTarget: MasteryProgress? {
        let started = masteryProgress.filter { $0.mastered > 0 && $0.nextMilestone != nil && $0.collection.category != .global }
        return started.sorted { ($0.playersToNext, $0.collection.displayOrder) < ($1.playersToNext, $1.collection.displayOrder) }.first
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

    func setAppActive(_ active: Bool) {
        isAppActive = active
        syncBackgroundMusic()
    }

    func syncBackgroundMusic() {
        guard soundEnabled, isAppActive else {
            audio.stopMusic()
            audio.stopCrowdAmbience()
            return
        }
        audio.playMusic(round == nil ? .intro : .mainGame)
        guard let round else {
            audio.stopCrowdAmbience()
            return
        }
        let ambience: CrowdAmbienceTrack
        if round.seed.difficulty == .hard {
            ambience = .stadium
        } else if round.daily {
            ambience = .realistic
        } else {
            ambience = .continuous
        }
        audio.playCrowdAmbience(ambience)
    }

    func startRound(daily: Bool = false, collectionID: String? = nil) async {
        let seed: PlayerSeed?
        if daily {
            seed = dailyPlayer()
        } else if let collectionID {
            let pools = masteryEngine.candidatePools(for: collectionID, players: SeedData.players, state: profile.mastery)
            seed = !pools.missing.isEmpty && Int.random(in: 0..<100) < 80 ? pools.missing.randomElement() : pools.all.randomElement()
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
        var careerStats: PlayerCareerStats?
        var live = false
        do {
            let liveData = try await wiki.careerData(for: seed.wikipediaTitle)
            career = liveData.career
            careerStats = liveData.stats
            live = true
        } catch {
            live = false
        }
        round = RoundState(
            seed: seed,
            career: career,
            usedLiveWikipedia: live,
            careerStats: careerStats,
            profileHint: GameRules.profileHint(for: seed, profile: profile),
            daily: daily,
            sourceCollectionID: collectionID
        )
        successPlayerImage = nil
        Task { [weak self] in
            let image = await WikipediaPlayerImageService.shared.cutout(for: seed.wikipediaTitle)
            guard self?.round?.seed.id == seed.id else { return }
            self?.successPlayerImage = image
        }
    }

    func startMasteryRound(collectionID: String) async { await startRound(collectionID: collectionID) }

    func startNextRound() async { await startRound(collectionID: round?.sourceCollectionID) }

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

    func buyProfileHint() {
        guard var round, !round.resolved, !round.profileHintRevealed, round.profileHint != nil else { return }
        guard profile.coins >= GameRules.hintCost else {
            message = "You need \(GameRules.hintCost) coins for a profile hint."
            return
        }
        profile.coins -= GameRules.hintCost
        profile.hintsUsed += 1
        round.profileHintRevealed = true
        self.round = round
        message = "Personal hint unlocked · −\(GameRules.hintCost) coins"
        feedbackPulse += 1
        if soundEnabled { audio.play(.hint) }
        saveProfile()
    }

    func updateProfile(displayName: String, avatarEmoji: String, avatarColor: String, avatarUsesInitials: Bool, favoriteTeam: String?, favoritePlayer: String?) {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.displayName = trimmedName.isEmpty ? "Player" : String(trimmedName.prefix(24))
        let trimmedEmoji = avatarEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.avatarEmoji = trimmedEmoji.isEmpty ? "⚽️" : String(trimmedEmoji.prefix(1))
        profile.avatarColor = ProfileAvatarPalette.ids.contains(avatarColor) ? avatarColor : "purple"
        profile.avatarUsesInitials = avatarUsesInitials
        profile.favoriteTeam = favoriteTeam?.nilIfBlank
        profile.favoritePlayer = favoritePlayer?.nilIfBlank
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
        successPlayerImage = nil
        guess = ""
        message = ""
        masteryCelebration = nil
        additionalMasteryAwards = 0
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
            let hints = round.hints + (round.profileHintRevealed ? 1 : 0)
            var mastery = profile.mastery
            let masteryUpdate = masteryEngine.recordCorrect(player: round.seed, attempts: max(1, round.guesses.count), hints: hints, daily: round.daily, careerStats: round.careerStats, state: &mastery)
            profile.mastery = mastery
            profile.xp += masteryUpdate.reward.xp
            profile.coins += masteryUpdate.reward.coins
            round.masteryUpdate = masteryUpdate
            self.round = round
            message = dailyAlreadyRewarded
                ? "Correct! Daily bonus already collected — replay for fun."
                : "Correct! +\(reward.xp + masteryUpdate.reward.xp) XP · +\(reward.coins + masteryUpdate.reward.coins) coins"
            if let primary = masteryUpdate.newAwards.first {
                additionalMasteryAwards = max(0, masteryUpdate.newAwards.count - 1)
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(2.9))
                    guard self?.round?.seed.id == round.seed.id else { return }
                    self?.masteryCelebration = primary
                }
            }
        } else {
            profile.streak = 0
            message = "It was \(round.seed.name)."
        }
        saveProfile()
    }

    func dismissMasteryCelebration() { masteryCelebration = nil; additionalMasteryAwards = 0 }

    func collection(for id: String) -> MasteryCollection? { masteryEngine.collections.first(where: { $0.id == id }) }

    func toggleFeaturedTrophy(_ awardID: String) {
        if let index = profile.mastery.featuredTrophyIDs.firstIndex(of: awardID) {
            profile.mastery.featuredTrophyIDs.remove(at: index)
        } else if profile.mastery.featuredTrophyIDs.count < 3, profile.mastery.earnedAwards[awardID] != nil {
            profile.mastery.featuredTrophyIDs.append(awardID)
        }
        saveProfile()
    }

    func selectCabinetTheme(_ theme: CabinetTheme, clubActive: Bool) {
        guard !theme.requiresClub || clubActive else { return }
        profile.mastery.selectedCabinetThemeID = theme.id
        saveProfile()
    }

    private func presentFeedback(_ kind: MatchFeedbackKind) {
        let moment = MatchMoment(kind: kind)
        matchMoment = moment
        if soundEnabled { audio.play(kind) }
        if kind == .goal { successPulse += 1 } else { warningPulse += 1 }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(kind == .goal ? 2.8 : 1.05))
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

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
