import SwiftUI

struct ClubhouseView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("⚽️🏆").font(.system(size: 48))
                    Text("THE CLUBHOUSE").font(.largeTitle.weight(.black))
                    Text("Play · Learn · Master · Collect").foregroundStyle(.secondary)
                    ProgressView(value: Double(store.masteredPlayerCount), total: Double(max(1, SeedData.players.count))).tint(.mint)
                    Text("\(store.masteredPlayerCount) / \(SeedData.players.count) player cards collected").font(.caption.weight(.bold))
                }
                .padding(24).frame(maxWidth: .infinity)
                .background(.purple.opacity(0.18), in: RoundedRectangle(cornerRadius: 26))

                clubhouseLink("Mastery", "Countries, continents and leagues", "globe.europe.africa.fill", .cyan) { MasteryHomeView() }
                clubhouseLink("Trophy Cabinet", "Display every earned milestone", "trophy.fill", .yellow) { TrophyCabinetView() }
                clubhouseLink("Player Cards", "Browse your personal football collection", "rectangle.portrait.on.rectangle.portrait", .mint) { PlayerCollectionView() }
                clubhouseLink("Sets", "Complete special football collections", "square.grid.2x2.fill", .orange) { SetsView() }
                clubhouseLink("Locker Room", "Cabinet themes and presentation", "paintpalette.fill", .pink) { LockerRoomView() }
            }.padding()
        }
        .navigationTitle("The Clubhouse")
        .iOSInlineNavigationTitle()
    }

    private func clubhouseLink<Destination: View>(_ title: String, _ subtitle: String, _ icon: String, _ tint: Color, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 15) {
                Image(systemName: icon).font(.title2.weight(.black)).foregroundStyle(tint).frame(width: 48, height: 48).background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline.weight(.black)); Text(subtitle).font(.caption).foregroundStyle(.secondary) }
                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }.padding(16).background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }
}

struct MasteryHomeView: View {
    @EnvironmentObject private var store: GameStore
    private var progress: [MasteryProgress] { store.masteryProgress }
    private var almost: [MasteryProgress] { progress.filter { $0.mastered > 0 && $0.nextMilestone != nil }.sorted { ($0.playersToNext, $0.collection.displayOrder) < ($1.playersToNext, $1.collection.displayOrder) }.prefix(4).map { $0 } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("WIKIBALL MASTERY").font(.largeTitle.weight(.black))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MasterySummaryTile("Players mastered", "\(store.masteredPlayerCount)", "person.crop.circle.badge.checkmark")
                    MasterySummaryTile("Countries started", "\(progress.filter { $0.collection.category == .country && $0.mastered > 0 }.count)", "flag.fill")
                    MasterySummaryTile("Countries mastered", "\(progress.filter { $0.collection.category == .country && $0.historicalTier == .master }.count)", "medal.fill")
                    MasterySummaryTile("Continental trophies", "\(progress.filter { $0.collection.category == .region && $0.historicalTier == .master }.count) / 5", "trophy.fill")
                }
                if !almost.isEmpty { masterySection("Almost There", items: almost) }
                masterySection("Continents", items: progress.filter { $0.collection.category == .region })
                masterySection("Countries", items: progress.filter { $0.collection.category == .country })
                masterySection("Leagues", items: progress.filter { $0.collection.category == .league })
            }.padding()
        }.navigationTitle("Mastery").iOSInlineNavigationTitle()
    }

    @ViewBuilder private func masterySection(_ title: String, items: [MasteryProgress]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title.uppercased()).font(.caption.weight(.black)).tracking(1).foregroundStyle(.secondary)
                ForEach(items) { item in NavigationLink { CollectionDetailView(collectionID: item.id) } label: { MasteryProgressCard(progress: item) }.buttonStyle(.plain) }
            }
        }
    }
}

private struct MasterySummaryTile: View {
    let title: String; let value: String; let icon: String
    init(_ title: String, _ value: String, _ icon: String) { self.title = title; self.value = value; self.icon = icon }
    var body: some View { VStack(spacing: 6) { Image(systemName: icon).foregroundStyle(.mint); Text(value).font(.title2.weight(.black)); Text(title).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity, minHeight: 100).background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18)) }
}

struct MasteryProgressCard: View {
    let progress: MasteryProgress
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack { Text(progress.collection.icon).font(.title2); Text(progress.collection.name).font(.headline.weight(.black)); Spacer(); Text("\(progress.percent)%").font(.headline.weight(.black)).foregroundStyle(.mint) }
            ProgressView(value: progress.fraction).tint(tierColor(progress.historicalTier))
            HStack { Text("\(progress.mastered) / \(progress.total) mastered"); Spacer(); Text(progress.historicalTier?.label ?? "Unplayed") }.font(.caption.weight(.bold)).foregroundStyle(.secondary)
            if let next = progress.nextMilestone { Text("Next: \(next.tier.label) · \(progress.playersToNext) player\(progress.playersToNext == 1 ? "" : "s") to go").font(.caption2).foregroundStyle(.secondary) }
        }.padding(15).background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18)).accessibilityElement(children: .combine)
    }
}

struct CollectionDetailView: View {
    @EnvironmentObject private var store: GameStore
    let collectionID: String
    private var collection: MasteryCollection? { store.collection(for: collectionID) }
    private var progress: MasteryProgress? { collection.map { store.masteryEngine.progress(for: $0, state: store.profile.mastery) } }
    private var players: [PlayerSeed] { guard let collection else { return [] }; return SeedData.players.filter { collection.eligiblePlayerIDs.contains($0.id) } }

    var body: some View {
        ScrollView {
            if let collection, let progress {
                VStack(spacing: 18) {
                    Text(collection.icon).font(.system(size: 54)); Text(collection.name).font(.largeTitle.weight(.black)).multilineTextAlignment(.center)
                    Text(collection.description).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    MasteryProgressCard(progress: progress)
                    Button { Task { await store.startMasteryRound(collectionID: collection.id) } } label: { Label(progress.mastered < progress.total ? "Play Missing" : "Continue Mastery", systemImage: "play.fill").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).tint(.mint)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(players) { PlayerCardTile(player: $0, record: store.profile.mastery.masteredPlayers[$0.id]) } }
                    VStack(alignment: .leading, spacing: 10) { Text("MILESTONES").font(.caption.weight(.black)).foregroundStyle(.secondary); ForEach(collection.milestones) { milestone in MilestoneRow(collection: collection, milestone: milestone) } }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding()
            }
        }.navigationTitle(collection?.name ?? "Collection").iOSInlineNavigationTitle()
    }
}

private struct MilestoneRow: View {
    @EnvironmentObject private var store: GameStore
    let collection: MasteryCollection; let milestone: MasteryMilestone
    var earned: MasteryAwardRecord? { store.profile.mastery.earnedAwards["\(collection.id).\(milestone.tier.rawValue)"] }
    var body: some View { HStack { TrophyArtworkView(tier: milestone.tier, family: collection.trophyFamily, size: 42); VStack(alignment: .leading) { Text("\(milestone.tier.label) · \(Int(milestone.threshold * 100))%").font(.headline); Text(rewardText(milestone.reward)).font(.caption).foregroundStyle(.secondary); if let earned { Text("Earned \(earned.earnedAt.formatted(date: .abbreviated, time: .omitted))").font(.caption2).foregroundStyle(.mint) } }; Spacer(); Image(systemName: earned == nil ? "lock.fill" : "checkmark.seal.fill").foregroundStyle(earned == nil ? Color.secondary : Color.mint) }.padding(12).background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 15)) }
}

struct PlayerCollectionView: View {
    @EnvironmentObject private var store: GameStore
    @State private var search = ""
    @State private var filters = PlayerCardFilters()
    @State private var showingFilters = false

    private var players: [PlayerSeed] { SeedData.players.filter(matches).sorted { $0.name < $1.name } }
    private func matches(_ player: PlayerSeed) -> Bool {
        let record = store.profile.mastery.masteredPlayers[player.id]
        if !search.isEmpty && (record == nil || !player.name.localizedCaseInsensitiveContains(search)) { return false }
        if let value = filters.country, player.nationality != value { return false }
        if let value = filters.region, player.region != value { return false }
        if let value = filters.position, player.position != value { return false }
        if let value = filters.rarity, player.cardRarity != value { return false }
        if let value = filters.club, !player.career.contains(where: { GameRules.baseClubName($0.club) == value }) { return false }
        if let value = filters.decade, !player.career.contains(where: { $0.years.contains(String(value.prefix(3))) }) { return false }
        if let value = filters.leagueID, !(store.collection(for: "league-\(value)")?.eligiblePlayerIDs.contains(player.id) ?? false) { return false }
        if let value = filters.collectionID, !(store.collection(for: value)?.eligiblePlayerIDs.contains(player.id) ?? false) { return false }
        switch filters.status { case .all: break; case .collected: if record == nil { return false }; case .missing: if record != nil { return false }; case .perfect: if record?.isPerfect != true { return false }; case .needsImprovement: if record?.needsImprovement != true { return false } }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack { VStack(alignment: .leading) { Text("PLAYER COLLECTION").font(.title.weight(.black)); Text("\(store.masteredPlayerCount) / \(SeedData.players.count) collected").foregroundStyle(.secondary) }; Spacer(); Button { showingFilters = true } label: { Label("Filters", systemImage: filters.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill") } }
                ProgressView(value: Double(store.masteredPlayerCount), total: Double(max(1, SeedData.players.count))).tint(.mint)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(players) { player in NavigationLink { PlayerCardDetailView(playerID: player.id) } label: { PlayerCardTile(player: player, record: store.profile.mastery.masteredPlayers[player.id]) }.buttonStyle(.plain) } }
            }.padding()
        }.navigationTitle("Player Cards").iOSInlineNavigationTitle().searchable(text: $search, prompt: "Search collected players").sheet(isPresented: $showingFilters) { PlayerCardFilterView(filters: $filters) }
    }
}

private enum PlayerCardStatus: String, CaseIterable, Identifiable { case all, collected, missing, perfect, needsImprovement = "Needs Improvement"; var id: String { rawValue }; var label: String { rawValue.capitalized } }
private struct PlayerCardFilters {
    var country: String?; var region: Region?; var leagueID: String?; var club: String?; var decade: String?; var position: String?; var rarity: CardRarity?; var status: PlayerCardStatus = .all; var collectionID: String?
    var isEmpty: Bool { country == nil && region == nil && leagueID == nil && club == nil && decade == nil && position == nil && rarity == nil && status == .all && collectionID == nil }
}

private struct PlayerCardFilterView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: PlayerCardFilters
    var body: some View { NavigationStack { Form {
        Picker("Country", selection: $filters.country) { Text("Any").tag(String?.none); ForEach(Set(SeedData.players.map(\.nationality)).sorted(), id: \.self) { Text($0).tag(Optional($0)) } }
        Picker("Continent", selection: $filters.region) { Text("Any").tag(Region?.none); ForEach(Region.allCases) { Text($0.rawValue).tag(Optional($0)) } }
        Picker("League", selection: $filters.leagueID) { Text("Any").tag(String?.none); ForEach(SeedData.leagues) { Text($0.label).tag(Optional($0.id)) } }
        Picker("Club", selection: $filters.club) { Text("Any").tag(String?.none); ForEach(SeedData.teams, id: \.self) { Text($0).tag(Optional($0)) } }
        Picker("Decade", selection: $filters.decade) { Text("Any").tag(String?.none); ForEach(SeedData.decades, id: \.self) { Text($0).tag(Optional($0)) } }
        Picker("Position", selection: $filters.position) { Text("Any").tag(String?.none); ForEach(Set(SeedData.players.map(\.position)).sorted(), id: \.self) { Text($0).tag(Optional($0)) } }
        Picker("Rarity", selection: $filters.rarity) { Text("Any").tag(CardRarity?.none); ForEach(CardRarity.allCases) { Text("\($0.icon) \($0.label)").tag(Optional($0)) } }
        Picker("Status", selection: $filters.status) { ForEach(PlayerCardStatus.allCases) { Text($0.label).tag($0) } }
        Picker("Set", selection: $filters.collectionID) { Text("Any").tag(String?.none); ForEach(store.masteryEngine.collections.filter { $0.category == .special }) { Text($0.name).tag(Optional($0.id)) } }
    }.navigationTitle("Card Filters").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Reset") { filters = PlayerCardFilters() } }; ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } } } }
}

struct PlayerCardTile: View {
    let player: PlayerSeed; let record: MasteredPlayer?
    var body: some View {
        ZStack {
            LinearGradient(colors: record == nil ? [.gray.opacity(0.35), .black] : rarityColors(player.cardRarity), startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                HStack { Text(record == nil ? "?" : MasteryCatalogue.flag(player.nationality)); Spacer(); Text(record == nil ? "LOCKED" : player.cardRarity.label.uppercased()).font(.caption2.weight(.black)) }
                Spacer()
                Text(record == nil ? "?" : initials(player.name)).font(.system(size: 42, weight: .black, design: .rounded)).frame(width: 76, height: 76).background(.black.opacity(0.28), in: Circle())
                Text(record == nil ? "UNKNOWN PLAYER" : player.name.uppercased()).font(.caption.weight(.black)).multilineTextAlignment(.center).lineLimit(2)
                if let record { Text("\(record.bestScore) MASTERY").font(.headline.weight(.black)).foregroundStyle(.yellow); Text("\(player.position) · \(record.correctCount)x correct").font(.caption2).foregroundStyle(.white.opacity(0.7)); Text(cardBadges(record)).font(.caption2).lineLimit(1) } else { Text("\(player.difficulty.rawValue.capitalized) · \(careerEra(player))").font(.caption2).foregroundStyle(.white.opacity(0.65)) }
            }.padding(13)
        }.frame(height: 235).clipShape(RoundedRectangle(cornerRadius: 22)).overlay { RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.16)) }.accessibilityElement(children: .combine).accessibilityLabel(record == nil ? "Unknown player, \(player.difficulty.rawValue) difficulty" : "\(player.name), \(player.cardRarity.label), mastery score \(record!.bestScore)")
    }
}

struct PlayerCardDetailView: View {
    @EnvironmentObject private var store: GameStore
    let playerID: String
    private var player: PlayerSeed? { SeedData.players.first { $0.id == playerID } }
    private var record: MasteredPlayer? { store.profile.mastery.masteredPlayers[playerID] }
    var body: some View { ScrollView { if let player { VStack(spacing: 18) {
        PlayerCardTile(player: player, record: record).frame(maxWidth: 240)
        if let record {
            Text(player.name).font(.largeTitle.weight(.black)); Text("\(MasteryCatalogue.flag(player.nationality)) \(player.nationality) · \(player.position)").foregroundStyle(.secondary)
            HStack { MasterySummaryTile("Unlock score", "\(record.unlockScore)", "sparkles"); MasterySummaryTile("Best score", "\(record.bestScore)", "arrow.up.circle.fill") }
            if let stats = record.careerStats, stats.seniorAppearances != nil || stats.seniorGoals != nil {
                HStack {
                    if let appearances = stats.seniorAppearances { MasterySummaryTile("Senior apps", "\(appearances)", "figure.soccer") }
                    if let goals = stats.seniorGoals { MasterySummaryTile("Senior goals", "\(goals)", "soccerball") }
                }
                if let fees = stats.transferFees, !fees.isEmpty { VStack(alignment: .leading) { Text("VERIFIED TRANSFER FEES").font(.caption.weight(.black)); ForEach(fees) { fee in Link("\(fee.fromClub) → \(fee.toClub) · \(fee.amount)", destination: fee.sourceURL) } }.frame(maxWidth: .infinity, alignment: .leading) }
            }
            VStack(alignment: .leading, spacing: 8) { Text("YOUR WIKIBALL RECORD").font(.caption.weight(.black)); Text("First discovered: \(record.firstMasteredAt.formatted(date: .abbreviated, time: .omitted))"); Text("First result: attempt \(record.firstAttempts) · \(record.firstHintsUsed) hints"); Text("Times correctly identified: \(record.correctCount)"); Text("Best result: attempt \(record.bestAttempts) · \(record.lowestHints) hints") }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 8) { Text("CAREER").font(.caption.weight(.black)); ForEach(player.career) { Text("\($0.years) · \(GameRules.baseClubName($0.club))") } }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            Text("Appears in: \(store.masteryEngine.collections(containing: player.id).map { "\($0.icon) \($0.name)" }.joined(separator: " · "))").font(.footnote).foregroundStyle(.secondary)
            if let url = URL(string: "https://en.wikipedia.org/wiki/\(player.wikipediaTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? player.wikipediaTitle)") { Link("View Wikipedia Career ↗", destination: url).foregroundStyle(.mint) }
        } else { Text("UNKNOWN PLAYER").font(.largeTitle.weight(.black)); Text("\(player.difficulty.rawValue.capitalized) difficulty · \(careerEra(player))").foregroundStyle(.secondary); Button { if let collection = store.masteryEngine.collections(containing: player.id).first { Task { await store.startMasteryRound(collectionID: collection.id) } } } label: { Label("Play Missing", systemImage: "play.fill") }.buttonStyle(.borderedProminent).tint(.mint) }
    }.padding() } }.navigationTitle(record == nil ? "Locked Card" : player?.name ?? "Player Card").iOSInlineNavigationTitle() }
}

struct TrophyCabinetView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService
    private var theme: CabinetTheme { let selected = CabinetTheme(rawValue: store.profile.mastery.selectedCabinetThemeID) ?? .classic; return selected.requiresClub && !store.hasClubAccess(purchases.isClubMember) ? .classic : selected }
    var body: some View { ScrollView { VStack(spacing: 18) {
        VStack { Text("TROPHY CABINET").font(.largeTitle.weight(.black)); Text("\(store.profile.mastery.earnedAwards.count) rewards earned").foregroundStyle(.secondary) }.padding(.top)
        ForEach(CollectionCategory.allCases.filter { $0 != .global }) { category in cabinetSection(category) }
        if let globe = store.masteryProgress.first(where: { $0.collection.category == .global }) { cabinetCard(globe) }
    }.padding().background(cabinetBackground(theme).ignoresSafeArea()) }.navigationTitle(theme.name).iOSInlineNavigationTitle() }
    @ViewBuilder private func cabinetSection(_ category: CollectionCategory) -> some View { let values = store.masteryProgress.filter { $0.collection.category == category }; if !values.isEmpty { VStack(alignment: .leading) { Text(category.label.uppercased()).font(.caption.weight(.black)).foregroundStyle(.secondary); ForEach(values) { cabinetCard($0) } } } }
    private func cabinetCard(_ progress: MasteryProgress) -> some View { NavigationLink { TrophyDetailView(collectionID: progress.id) } label: { HStack { TrophyArtworkView(tier: progress.historicalTier, family: progress.collection.trophyFamily, size: 62); VStack(alignment: .leading) { Text(progress.collection.name).font(.headline.weight(.black)); Text(progress.historicalTier?.label ?? "Locked").foregroundStyle(.secondary); ProgressView(value: progress.fraction).tint(tierColor(progress.historicalTier)); Text("\(progress.percent)% · \(progress.mastered)/\(progress.total)").font(.caption) }; Spacer(); Image(systemName: "chevron.right") }.padding(14).background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 18)) }.buttonStyle(.plain) }
}

struct TrophyDetailView: View {
    @EnvironmentObject private var store: GameStore
    let collectionID: String
    private var collection: MasteryCollection? { store.collection(for: collectionID) }
    private var progress: MasteryProgress? { collection.map { store.masteryEngine.progress(for: $0, state: store.profile.mastery) } }
    private var highestAward: MasteryAwardRecord? { guard let collection else { return nil }; return MasteryTier.allCases.reversed().compactMap { store.profile.mastery.earnedAwards["\(collection.id).\($0.rawValue)"] }.first }
    var body: some View { ScrollView { if let collection, let progress { VStack(spacing: 18) {
        TrophyArtworkView(tier: progress.historicalTier, family: collection.trophyFamily, size: 160); Text(collection.name).font(.largeTitle.weight(.black)).multilineTextAlignment(.center); Text("\(progress.percent)% · \(progress.mastered) / \(progress.total)").font(.title2.weight(.black)); ProgressView(value: progress.fraction).tint(tierColor(progress.historicalTier)); Text(collection.description).foregroundStyle(.secondary).multilineTextAlignment(.center)
        ForEach(collection.milestones) { MilestoneRow(collection: collection, milestone: $0) }
        if let award = highestAward { Button(store.profile.mastery.featuredTrophyIDs.contains(award.id) ? "Remove from Profile" : "Feature on Profile") { store.toggleFeaturedTrophy(award.id) }.buttonStyle(.bordered); ShareLink(item: "🏆 WIKIBALL\n\nI earned \(collection.name) — \(award.tier.label).\n\n\(progress.percent)% mastery ⚽️") { Label("Share Trophy", systemImage: "square.and.arrow.up") }.buttonStyle(.bordered) }
        if collection.category != .global { Button { Task { await store.startMasteryRound(collectionID: collection.id) } } label: { Label("Continue Mastery", systemImage: "play.fill").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).tint(.mint) }
    }.padding() } }.navigationTitle(collection?.name ?? "Trophy").iOSInlineNavigationTitle() }
}

struct SetsView: View {
    @EnvironmentObject private var store: GameStore
    var body: some View { ScrollView { VStack(spacing: 14) { ForEach(store.masteryProgress.filter { $0.collection.category == .special }) { progress in NavigationLink { CollectionDetailView(collectionID: progress.id) } label: { MasteryProgressCard(progress: progress) }.buttonStyle(.plain) } }.padding() }.navigationTitle("Sets").iOSInlineNavigationTitle() }
}

struct LockerRoomView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService
    var body: some View {
        Form {
            Section("Cabinet theme") {
                ForEach(CabinetTheme.allCases) { theme in
                    Button { store.selectCabinetTheme(theme, clubActive: store.hasClubAccess(purchases.isClubMember)) } label: {
                        HStack {
                            Image(systemName: theme == .classic ? "cabinet.fill" : "sparkles")
                            VStack(alignment: .leading) {
                                Text(theme.name).fontWeight(.bold)
                                Text(theme.requiresClub ? "Wikiball Club presentation" : "Free for everyone").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if store.profile.mastery.selectedCabinetThemeID == theme.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint) }
                            else if theme.requiresClub && !store.hasClubAccess(purchases.isClubMember) { Image(systemName: "lock.fill").foregroundStyle(.secondary) }
                        }
                    }.buttonStyle(.plain)
                }
            }
            Section { Text("Club themes change presentation only. Trophies, cards and mastery can never be purchased.").font(.footnote).foregroundStyle(.secondary) }
        }.navigationTitle("Locker Room")
    }
}

struct TrophyUnlockCelebrationView: View {
    @EnvironmentObject private var store: GameStore
    let award: MasteryAwardRecord
    let onView: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    private var collection: MasteryCollection? { store.collection(for: award.collectionID) }
    var body: some View { ZStack { Color.black.opacity(0.88).ignoresSafeArea(); VStack(spacing: 14) { Text("TROPHY UNLOCKED").font(.caption.weight(.black)).tracking(2).foregroundStyle(.yellow); TrophyArtworkView(tier: award.tier, family: collection?.trophyFamily ?? "Trophy", size: 150).scaleEffect(revealed ? 1 : 0.6); Text(collection?.name ?? "Mastery Award").font(.largeTitle.weight(.black)).multilineTextAlignment(.center); Text(award.tier.label).font(.title2.weight(.black)).foregroundStyle(tierColor(award.tier)); Text(rewardText(award.reward)).foregroundStyle(.secondary); if store.additionalMasteryAwards > 0 { Text("+ \(store.additionalMasteryAwards) additional rewards earned").font(.headline).foregroundStyle(.mint) }; HStack { Button("View Trophy", action: onView).buttonStyle(.bordered); Button("Continue Playing") { store.dismissMasteryCelebration() }.buttonStyle(.borderedProminent).tint(.mint) } }.padding(28) }.onAppear { if reduceMotion { revealed = true } else { withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) { revealed = true } } }.accessibilityElement(children: .combine).accessibilityLabel("Trophy unlocked. \(collection?.name ?? "Mastery Award"), \(award.tier.label). \(rewardText(award.reward))") }
}

struct MasteryRoundFeedbackView: View {
    let player: PlayerSeed
    let update: MasteryUpdate
    private var deltas: [MasteryCollectionDelta] {
        let priority: [CollectionCategory] = [.country, .region, .league, .special]
        return update.collectionDeltas.sorted { priority.firstIndex(of: $0.category)! < priority.firstIndex(of: $1.category)! }.prefix(3).map { $0 }
    }
    var body: some View {
        VStack(spacing: 10) {
            Text(update.isNewPlayer ? "NEW PLAYER MASTERED" : "ALREADY MASTERED ✓").font(.caption.weight(.black)).tracking(1).foregroundStyle(.mint)
            HStack { Text(MasteryCatalogue.flag(player.nationality)).font(.title); VStack(alignment: .leading) { Text(player.name).font(.headline.weight(.black)); Text(update.scoreImproved ? "Best score improved to \(update.bestScore)" : "Mastery Score \(update.bestScore)").font(.caption).foregroundStyle(.secondary) }; Spacer() }
            if update.isNewPlayer { Text("Added to: \(update.collectionDeltas.prefix(4).map { "\($0.icon) \($0.name)" }.joined(separator: " · "))").font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading) }
            ForEach(deltas) { delta in HStack { Text(delta.icon); Text(delta.name).font(.caption.weight(.bold)); Spacer(); Text("\(delta.before) → \(delta.after) / \(delta.total)").font(.caption.monospacedDigit()).foregroundStyle(.mint) } }
            if update.collectionDeltas.count > 3 { Text("+ \(update.collectionDeltas.count - 3) more collections").font(.caption2).foregroundStyle(.secondary) }
        }.padding(14).background(.mint.opacity(0.08), in: RoundedRectangle(cornerRadius: 17))
    }
}

struct TrophyArtworkView: View {
    let tier: MasteryTier?; let family: String; let size: CGFloat
    var body: some View { ZStack { Circle().fill(tierColor(tier).opacity(tier == nil ? 0.08 : 0.17)); Image(systemName: family.contains("Shield") ? "shield.lefthalf.filled" : family.contains("Globe") ? "globe.americas.fill" : "trophy.fill").resizable().scaledToFit().padding(size * 0.2).foregroundStyle(tier == nil ? Color.gray.opacity(0.28) : tierColor(tier)).shadow(color: tierColor(tier).opacity(0.4), radius: tier == .master ? 12 : 4) }.frame(width: size, height: size).accessibilityLabel("\(family), \(tier?.label ?? "locked")") }
}

private func tierColor(_ tier: MasteryTier?) -> Color { switch tier { case .bronze: return Color(red: 0.72, green: 0.42, blue: 0.2); case .silver: return Color(red: 0.72, green: 0.8, blue: 0.88); case .gold: return .yellow; case .master: return .mint; case nil: return .gray } }
private func rarityColors(_ rarity: CardRarity) -> [Color] { switch rarity { case .common: return [.green.opacity(0.75), .black]; case .rare: return [.blue.opacity(0.85), .black]; case .elite: return [.purple.opacity(0.9), .black]; case .icon: return [.yellow.opacity(0.8), .black]; case .legend: return [.pink, .purple, .blue] } }
private func initials(_ name: String) -> String { name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased() }
private func careerEra(_ player: PlayerSeed) -> String { let years = player.career.compactMap { Int($0.years.prefix(4)) }; guard let year = years.min() else { return "Unknown era" }; return "\((year / 10) * 10)s" }
private func rewardText(_ reward: MasteryReward) -> String { var parts: [String] = []; if reward.xp > 0 { parts.append("+\(reward.xp) XP") }; if reward.coins > 0 { parts.append("+\(reward.coins) Wikicoins") }; if reward.cosmeticID != nil { parts.append("Cosmetic unlocked") }; return parts.isEmpty ? "Collectible unlocked" : parts.joined(separator: " · ") }
private func cardBadges(_ record: MasteredPlayer) -> String { var badges: [String] = []; if record.isFirstTouch { badges.append("🎯 First Touch") }; if record.isNoHints { badges.append("💡 No Hints") }; if record.isDailyEdition { badges.append("📅 Daily") }; if record.isPerfect { badges.append("✨ Perfect") }; return badges.joined(separator: " · ") }
private func cabinetBackground(_ theme: CabinetTheme) -> LinearGradient { switch theme { case .classic: return LinearGradient(colors: [.brown.opacity(0.28), .black], startPoint: .top, endPoint: .bottom); case .spectrum: return LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.35), .black], startPoint: .topLeading, endPoint: .bottomTrailing); case .midnight: return LinearGradient(colors: [.indigo.opacity(0.42), .black, .blue.opacity(0.18)], startPoint: .top, endPoint: .bottom) } }
