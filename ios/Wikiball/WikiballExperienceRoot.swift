import SwiftUI
import StoreKit

/// Progressive replacement shell for the legacy all-in-one ContentView.
///
/// When a round is active we deliberately delegate to the proven legacy game flow so this
/// branch can improve the branded dashboard without regressing guessing/reward logic. The
/// non-round experience is rebuilt as a responsive four-tab, asset-driven game UI.
struct WikiballExperienceRoot: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.round == nil {
                WBMainShell()
            } else {
                ContentView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { store.syncBackgroundMusic() }
        .onChange(of: store.round != nil) { _, _ in store.syncBackgroundMusic() }
        .onChange(of: scenePhase) { _, phase in store.setAppActive(phase == .active) }
    }
}

private struct WBMainShell: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService

    @State private var selectedTab: WBMainTab = .home
    @State private var showingShop = false
    @State private var showingLockerRoom = false

    var body: some View {
        ZStack {
            WBAppBackground()

            Group {
                switch selectedTab {
                case .home:
                    WBHomeDashboard(
                        selectedTab: $selectedTab,
                        showShop: { showingShop = true },
                        showLockerRoom: { showingLockerRoom = true }
                    )
                case .play:
                    WBPlayDashboard(
                        selectedTab: $selectedTab,
                        showShop: { showingShop = true },
                        showLockerRoom: { showingLockerRoom = true }
                    )
                case .collection:
                    WBCollectionDashboard(
                        showShop: { showingShop = true },
                        showLockerRoom: { showingLockerRoom = true }
                    )
                case .profile:
                    WBProfileDashboard(
                        showShop: { showingShop = true },
                        showLockerRoom: { showingLockerRoom = true }
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WBBottomTabBar(selectedTab: $selectedTab)
                .background(WBDesign.Palette.background.opacity(0.96))
        }
        .sheet(isPresented: $showingShop) {
            WBShopView()
        }
        .sheet(isPresented: $showingLockerRoom) {
            WBLockerRoomView()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selectedTab)
    }
}

private struct WBAppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.018, green: 0.025, blue: 0.082),
                    WBDesign.Palette.background,
                    Color(red: 0.065, green: 0.035, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [WBDesign.Palette.blue.opacity(0.13), Color.clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 360
            )
            .ignoresSafeArea()
        }
    }
}

private struct WBHomeDashboard: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService

    @Binding var selectedTab: WBMainTab
    let showShop: () -> Void
    let showLockerRoom: () -> Void

    private var dailyComplete: Bool {
        store.profile.rewardedDailyDates.contains(GameStore.dayKey()) && !store.hasTestingAccess
    }

    var body: some View {
        WBResponsiveContainer { metrics in
            VStack(spacing: metrics.majorSectionSpacing) {
                WBMainHUD(onCoins: showShop, onAvatar: showLockerRoom)
                    .padding(.top, 8)

                playHero(metrics: metrics)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        dailyCard
                        contextCard
                    }
                    VStack(spacing: 12) {
                        dailyCard
                        contextCard
                    }
                }

                careerCard
                collectionPrompt
            }
            .padding(.bottom, 22)
        }
    }

    private func playHero(metrics: WBResponsiveMetrics) -> some View {
        WBArtCard(
            artworkName: WBArtwork.Home.playHeroBackground,
            cornerRadius: WBDesign.Radius.hero,
            aspectRatio: metrics.isCompact ? nil : 1.76,
            fallbackColors: [Color(red: 0.07, green: 0.28, blue: 0.72), Color(red: 0.21, green: 0.11, blue: 0.55)]
        ) {
            ZStack(alignment: .trailing) {
                WBArtworkImage(name: WBArtwork.Home.playHeroFootball, contentMode: .fit)
                    .frame(maxWidth: metrics.contentWidth * 0.48)
                    .padding(.trailing, -8)
                    .opacity(WBAssetAvailability.has(WBArtwork.Home.playHeroFootball) ? 1 : 0)

                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PLAY\nWIKIBALL")
                            .font(WBDesign.Typography.hero(metrics.isCompact ? 31 : 38))
                            .tracking(0.4)
                            .foregroundStyle(.white)
                            .lineSpacing(-4)

                        Text("Test your football knowledge, build your collection and climb the ranks.")
                            .font(WBDesign.Typography.body(metrics.isCompact ? 13 : 14))
                            .foregroundStyle(.white.opacity(0.78))
                            .frame(maxWidth: metrics.contentWidth * 0.57, alignment: .leading)

                        Button {
                            selectedTab = .play
                        } label: {
                            HStack(spacing: 8) {
                                Text("PLAY")
                                Image(systemName: "arrow.right")
                            }
                            .font(WBDesign.Typography.label(13))
                            .foregroundStyle(Color(red: 0.05, green: 0.07, blue: 0.16))
                            .padding(.horizontal, 20)
                            .frame(minHeight: 44)
                            .background(WBDesign.Palette.yellow, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: metrics.contentWidth * 0.32)
                }
                .padding(metrics.isCompact ? 18 : 22)
            }
        }
        .frame(minHeight: metrics.isCompact ? 205 : 226)
        .accessibilityElement(children: .contain)
    }

    private var dailyCard: some View {
        WBArtCard(
            artworkName: WBArtwork.Home.dailyBackground,
            cornerRadius: 22,
            fallbackColors: [Color(red: 0.32, green: 0.11, blue: 0.62), Color(red: 0.16, green: 0.08, blue: 0.32)]
        ) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    WBSmallStatusPill(title: "Today", tint: WBDesign.Palette.purple)
                    Spacer()
                    Image(systemName: dailyComplete ? "checkmark.seal.fill" : "calendar.badge.clock")
                        .font(.title2.weight(.black))
                        .foregroundStyle(dailyComplete ? WBDesign.Palette.green : WBDesign.Palette.yellow)
                }

                Text("DAILY CHALLENGE")
                    .font(WBDesign.Typography.cardTitle(17))
                Text(dailyComplete ? "Completed today" : "One player. Same challenge for everyone.")
                    .font(WBDesign.Typography.body(12))
                    .foregroundStyle(WBDesign.Palette.textSecondary)
                    .lineLimit(2)

                Spacer(minLength: 4)

                Button {
                    Task { await store.startRound(daily: true) }
                } label: {
                    Text(dailyComplete ? "PLAY AGAIN" : "PLAY DAILY")
                        .font(WBDesign.Typography.label(10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 34)
                        .background(WBDesign.Palette.blue, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 156)
    }

    private var contextCard: some View {
        let target = store.nextMasteryTarget
        return WBArtCard(
            artworkName: WBArtwork.Home.careerBackground,
            cornerRadius: 22,
            fallbackColors: [Color(red: 0.08, green: 0.22, blue: 0.42), Color(red: 0.07, green: 0.10, blue: 0.25)]
        ) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    WBSmallStatusPill(title: "Next", tint: WBDesign.Palette.blue)
                    Spacer()
                    WBRankCrestView(tierName: store.currentTier.name, size: 32)
                }
                Text(target == nil ? "KEEP CLIMBING" : "NEXT TROPHY")
                    .font(WBDesign.Typography.cardTitle(17))
                Text(target.map { "\($0.collection.name) · \($0.playersToNext) player\($0.playersToNext == 1 ? "" : "s") to go" } ?? "Play more rounds to start a Career collection.")
                    .font(WBDesign.Typography.body(12))
                    .foregroundStyle(WBDesign.Palette.textSecondary)
                    .lineLimit(2)
                Spacer(minLength: 4)
                Button {
                    selectedTab = .profile
                } label: {
                    Text("VIEW CAREER")
                        .font(WBDesign.Typography.label(10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 34)
                        .background(WBDesign.Palette.purple, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 156)
    }

    private var careerCard: some View {
        let target = store.nextMasteryTarget
        let fraction = target?.fraction ?? store.tierProgress
        return WBArtCard(
            artworkName: WBArtwork.Home.careerBackground,
            cornerRadius: 24,
            fallbackColors: [Color(red: 0.06, green: 0.16, blue: 0.38), WBDesign.Palette.surface]
        ) {
            VStack(alignment: .leading, spacing: 13) {
                WBSectionHeader(title: "Your Career", actionTitle: "View all") {
                    selectedTab = .profile
                }

                HStack(spacing: 14) {
                    WBRankCrestView(tierName: store.currentTier.name, size: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(target?.collection.name ?? store.currentTier.name)
                            .font(WBDesign.Typography.cardTitle(19))
                        Text(target.map { "\($0.percent)% complete" } ?? "\(store.profile.xp) XP")
                            .font(WBDesign.Typography.body(13))
                            .foregroundStyle(WBDesign.Palette.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(target.map { "\($0.playersToNext)" } ?? "\(store.masteredPlayerCount)")
                            .font(WBDesign.Typography.number(24))
                            .foregroundStyle(WBDesign.Palette.yellow)
                        Text(target == nil ? "STICKERS" : "TO NEXT")
                            .font(WBDesign.Typography.label(9))
                            .foregroundStyle(WBDesign.Palette.textTertiary)
                    }
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(LinearGradient(colors: [WBDesign.Palette.cyan, WBDesign.Palette.green], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(9, proxy.size.width * fraction))
                    }
                }
                .frame(height: 10)

                Text(target.map { "Next reward: \($0.nextMilestone?.tier.label ?? "Master")" } ?? "Discover unique players to unlock Career trophies.")
                    .font(WBDesign.Typography.body(12))
                    .foregroundStyle(WBDesign.Palette.textSecondary)
            }
            .padding(18)
        }
        .frame(minHeight: 174)
    }

    private var collectionPrompt: some View {
        Button {
            selectedTab = .collection
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [WBDesign.Palette.yellow, WBDesign.Palette.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "rectangle.stack.fill")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color(red: 0.08, green: 0.07, blue: 0.14))
                }
                .frame(width: 52, height: 58)

                VStack(alignment: .leading, spacing: 3) {
                    Text("CONTINUE COLLECTING")
                        .font(WBDesign.Typography.cardTitle(15))
                    Text("\(store.masteredPlayerCount) unique player sticker\(store.masteredPlayerCount == 1 ? "" : "s") unlocked")
                        .font(WBDesign.Typography.body(12))
                        .foregroundStyle(WBDesign.Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.black))
                    .foregroundStyle(WBDesign.Palette.cyan)
            }
            .padding(15)
            .background(WBDesign.Palette.surfaceRaised.opacity(0.74), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }
}

private struct WBPlayDashboard: View {
    @EnvironmentObject private var store: GameStore

    @Binding var selectedTab: WBMainTab
    let showShop: () -> Void
    let showLockerRoom: () -> Void

    @State private var showingFilters = false
    @State private var showingVersusNote = false

    var body: some View {
        WBResponsiveContainer { metrics in
            VStack(spacing: metrics.majorSectionSpacing) {
                WBMainHUD(onCoins: showShop, onAvatar: showLockerRoom)
                    .padding(.top, 8)

                Text("PLAY")
                    .font(WBDesign.Typography.screenTitle(30))
                    .frame(maxWidth: .infinity)

                quickPlay(metrics: metrics)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        dailyMode
                        versusMode
                    }
                    VStack(spacing: 12) {
                        dailyMode
                        versusMode
                    }
                }

                customGame
                featuredLeagues
            }
            .padding(.bottom, 22)
        }
        .sheet(isPresented: $showingFilters) {
            WBCustomGameSheet()
        }
        .alert("Versus", isPresented: $showingVersusNote) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The visual shell is ready. Friend-challenge networking remains on the existing Versus implementation branch and should be wired here when that code is merged.")
        }
    }

    private func quickPlay(metrics: WBResponsiveMetrics) -> some View {
        WBArtCard(
            artworkName: WBArtwork.Play.quickPlayBackground,
            cornerRadius: WBDesign.Radius.hero,
            aspectRatio: metrics.isCompact ? nil : 1.9,
            fallbackColors: [Color(red: 0.04, green: 0.31, blue: 0.80), Color(red: 0.08, green: 0.12, blue: 0.42)]
        ) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.title.weight(.black))
                        .foregroundStyle(WBDesign.Palette.yellow)
                    Text("QUICK\nPLAY")
                        .font(WBDesign.Typography.hero(metrics.isCompact ? 29 : 35))
                        .lineSpacing(-4)
                    Text("Jump into a fast match and test your skills.")
                        .font(WBDesign.Typography.body(13))
                        .foregroundStyle(WBDesign.Palette.textSecondary)
                        .frame(maxWidth: 220, alignment: .leading)
                    Button {
                        Task { await store.startRound() }
                    } label: {
                        Text("PLAY NOW")
                            .font(WBDesign.Typography.label(12))
                            .foregroundStyle(Color(red: 0.05, green: 0.07, blue: 0.16))
                            .padding(.horizontal, 18)
                            .frame(minHeight: 42)
                            .background(WBDesign.Palette.yellow, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(store.filteredPlayers.isEmpty)
                }
                Spacer()
                Image(systemName: "soccerball")
                    .font(.system(size: metrics.isCompact ? 70 : 92, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
                    .rotationEffect(.degrees(-14))
                    .shadow(color: WBDesign.Palette.cyan.opacity(0.35), radius: 18)
            }
            .padding(20)
        }
        .frame(minHeight: metrics.isCompact ? 196 : 216)
    }

    private var dailyMode: some View {
        Button {
            Task { await store.startRound(daily: true) }
        } label: {
            WBModeCard(
                artwork: WBArtwork.Play.dailyBackground,
                title: "DAILY\nCHALLENGE",
                subtitle: "One shared player every day",
                systemImage: "calendar.badge.clock",
                tint: WBDesign.Palette.purple
            )
        }
        .buttonStyle(.plain)
    }

    private var versusMode: some View {
        Button { showingVersusNote = true } label: {
            WBModeCard(
                artwork: WBArtwork.Play.versusBackground,
                title: "VERSUS",
                subtitle: "Challenge a friend",
                systemImage: "person.2.fill",
                tint: WBDesign.Palette.orange
            )
        }
        .buttonStyle(.plain)
    }

    private var customGame: some View {
        WBArtCard(
            artworkName: WBArtwork.Play.customBackground,
            cornerRadius: 22,
            fallbackColors: [Color(red: 0.02, green: 0.34, blue: 0.22), Color(red: 0.04, green: 0.16, blue: 0.15)]
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CUSTOM GAME")
                            .font(WBDesign.Typography.cardTitle(20))
                        Text("Create a round with your own football filters.")
                            .font(WBDesign.Typography.body(12))
                            .foregroundStyle(WBDesign.Palette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2.weight(.black))
                        .foregroundStyle(WBDesign.Palette.green)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    WBFilterSummary(label: "Difficulty", value: store.filters.difficulty?.rawValue.capitalized ?? "Any")
                    WBFilterSummary(label: "League", value: store.selectedLeague?.league ?? "Any")
                    WBFilterSummary(label: "Era", value: store.filters.decade ?? "Any")
                    WBFilterSummary(label: "Club", value: store.filters.team ?? "Any")
                }

                HStack(spacing: 10) {
                    Button("EDIT RULES") { showingFilters = true }
                        .font(WBDesign.Typography.label(10))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(Color.white.opacity(0.10), in: Capsule())

                    Button("CREATE GAME") {
                        Task { await store.startRound() }
                    }
                    .font(WBDesign.Typography.label(10))
                    .foregroundStyle(Color(red: 0.05, green: 0.07, blue: 0.16))
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(WBDesign.Palette.yellow, in: Capsule())
                    .disabled(store.filteredPlayers.isEmpty)
                }
                .buttonStyle(.plain)
            }
            .padding(17)
        }
    }

    private var featuredLeagues: some View {
        VStack(alignment: .leading, spacing: 11) {
            WBSectionHeader(title: "Featured Leagues")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(SeedData.leagues.prefix(5))) { league in
                        Button {
                            store.filters.leagueID = league.id
                            Task { await store.startRound() }
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: "shield.fill")
                                    .font(.title2.weight(.black))
                                    .foregroundStyle(WBDesign.Palette.cyan)
                                Text(league.league)
                                    .font(WBDesign.Typography.label(10))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(width: 100, height: 88)
                            .background(WBDesign.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct WBModeCard: View {
    let artwork: String
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        WBArtCard(artworkName: artwork, cornerRadius: 22, fallbackColors: [tint.opacity(0.72), WBDesign.Palette.surface]) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.black))
                    .foregroundStyle(WBDesign.Palette.yellow)
                Text(title)
                    .font(WBDesign.Typography.cardTitle(17))
                    .lineSpacing(-2)
                Text(subtitle)
                    .font(WBDesign.Typography.body(11))
                    .foregroundStyle(WBDesign.Palette.textSecondary)
                    .lineLimit(2)
                Spacer(minLength: 0)
                HStack {
                    Text("PLAY")
                        .font(WBDesign.Typography.label(10))
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                }
                .foregroundStyle(.white)
            }
            .padding(15)
        }
        .frame(maxWidth: .infinity, minHeight: 158)
    }
}

private struct WBFilterSummary: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(WBDesign.Typography.label(8))
                .foregroundStyle(WBDesign.Palette.textTertiary)
            Text(value)
                .font(WBDesign.Typography.body(11))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct WBCustomGameSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    WBFilterPicker(title: "Difficulty", current: store.filters.difficulty?.rawValue.capitalized ?? "Any") {
                        Button("Any") { store.filters.difficulty = nil }
                        ForEach(Difficulty.allCases) { value in
                            Button(value.rawValue.capitalized) { store.filters.difficulty = value }
                        }
                    }
                    WBFilterPicker(title: "Era", current: store.filters.decade ?? "Any") {
                        Button("Any") { store.filters.decade = nil }
                        ForEach(SeedData.decades, id: \.self) { value in Button(value) { store.filters.decade = value } }
                    }
                    WBFilterPicker(title: "Region", current: store.filters.region?.rawValue ?? "Any") {
                        Button("Any") { store.filters.region = nil }
                        ForEach(Region.allCases) { value in Button(value.rawValue) { store.filters.region = value } }
                    }
                    WBFilterPicker(title: "League", current: store.selectedLeague?.league ?? "Any") {
                        Button("Any") { store.filters.leagueID = nil }
                        ForEach(SeedData.leagues) { value in Button(value.label) { store.filters.leagueID = value.id } }
                    }
                    WBFilterPicker(title: "Club", current: store.filters.team ?? "Any") {
                        Button("Any") { store.filters.team = nil }
                        ForEach(SeedData.teams, id: \.self) { value in Button(value) { store.filters.team = value } }
                    }

                    HStack {
                        Text("\(store.filteredPlayers.count) eligible players")
                            .font(WBDesign.Typography.body(13))
                            .foregroundStyle(store.filteredPlayers.isEmpty ? WBDesign.Palette.orange : WBDesign.Palette.green)
                        Spacer()
                        Button("RESET") { store.resetFilters() }
                            .font(WBDesign.Typography.label(10))
                    }
                    .padding(.top, 8)
                }
                .padding(18)
            }
            .background(WBDesign.Palette.background.ignoresSafeArea())
            .navigationTitle("Build Your Round")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct WBFilterPicker<Content: View>: View {
    let title: String
    let current: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu(content: content) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title.uppercased())
                        .font(WBDesign.Typography.label(9))
                        .foregroundStyle(WBDesign.Palette.textTertiary)
                    Text(current)
                        .font(WBDesign.Typography.cardTitle(16))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(WBDesign.Palette.cyan)
            }
            .padding(15)
            .background(WBDesign.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
        }
    }
}

private struct WBCollectionDashboard: View {
    @EnvironmentObject private var store: GameStore
    let showShop: () -> Void
    let showLockerRoom: () -> Void

    @State private var search = ""
    @State private var collectedOnly = false

    private var displayedPlayers: [PlayerSeed] {
        SeedData.players.filter { player in
            let matchesSearch = search.isEmpty || player.name.localizedCaseInsensitiveContains(search)
            let collected = store.profile.mastery.masteredPlayers[player.id] != nil
            return matchesSearch && (!collectedOnly || collected)
        }
    }

    var body: some View {
        WBResponsiveContainer { metrics in
            VStack(spacing: metrics.majorSectionSpacing) {
                WBMainHUD(onCoins: showShop, onAvatar: showLockerRoom)
                    .padding(.top, 8)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("PLAYER")
                            .font(WBDesign.Typography.screenTitle(24))
                        Text("COLLECTION")
                            .font(WBDesign.Typography.screenTitle(31))
                    }
                    Spacer()
                    Text("\(store.masteredPlayerCount) / \(SeedData.players.count)")
                        .font(WBDesign.Typography.number(18))
                        .foregroundStyle(WBDesign.Palette.yellow)
                }

                HStack(spacing: 9) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(WBDesign.Palette.textTertiary)
                        TextField("Search players…", text: $search)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 46)
                    .background(WBDesign.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                    Button {
                        collectedOnly.toggle()
                    } label: {
                        Image(systemName: collectedOnly ? "checkmark.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title2.weight(.black))
                            .foregroundStyle(collectedOnly ? WBDesign.Palette.green : .white)
                            .frame(width: 46, height: 46)
                            .background(WBDesign.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(displayedPlayers) { player in
                        WBCollectionSticker(player: player, collected: store.profile.mastery.masteredPlayers[player.id] != nil)
                    }
                }
            }
            .padding(.bottom, 22)
        }
    }
}

private struct WBCollectionSticker: View {
    let player: PlayerSeed
    let collected: Bool

    private var frameAsset: String {
        switch player.cardRarity {
        case .common: return "WBStickerStandard"
        case .rare: return "WBStickerSilver"
        case .elite: return "WBStickerGold"
        case .icon: return "WBStickerGold"
        case .legend: return "WBStickerSpectrum"
        }
    }

    var body: some View {
        ZStack {
            if WBAssetAvailability.has(collected ? frameAsset : "WBStickerMissing") {
                WBArtworkImage(name: collected ? frameAsset : "WBStickerMissing", contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(collected ? WBDesign.Palette.surfaceRaised : Color.white.opacity(0.05))
            }

            VStack(spacing: 6) {
                Spacer(minLength: 6)
                Image(systemName: collected ? "person.crop.circle.fill" : "questionmark")
                    .font(.system(size: 31, weight: .black))
                    .foregroundStyle(collected ? .white.opacity(0.9) : .white.opacity(0.36))
                Text(collected ? player.name : "???")
                    .font(WBDesign.Typography.label(9))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(collected ? player.position.uppercased() : "MISSING")
                    .font(WBDesign.Typography.label(7))
                    .foregroundStyle(WBDesign.Palette.textTertiary)
                Spacer(minLength: 5)
            }
            .padding(8)
        }
        .aspectRatio(0.72, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel(collected ? "\(player.name), collected" : "Missing player sticker")
    }
}

private struct WBProfileDashboard: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService

    let showShop: () -> Void
    let showLockerRoom: () -> Void

    private var accuracy: Int {
        guard store.profile.played > 0 else { return 0 }
        return Int((Double(store.profile.correct) / Double(store.profile.played) * 100).rounded())
    }

    var body: some View {
        WBResponsiveContainer { metrics in
            VStack(spacing: metrics.majorSectionSpacing) {
                WBMainHUD(onCoins: showShop, onAvatar: showLockerRoom)
                    .padding(.top, 8)

                Text("PROFILE")
                    .font(WBDesign.Typography.screenTitle(30))
                    .frame(maxWidth: .infinity)

                VStack(spacing: 9) {
                    ProfileAvatarView(profile: store.profile, size: 92)
                    Text(store.profile.displayName)
                        .font(WBDesign.Typography.screenTitle(25))
                    HStack(spacing: 6) {
                        WBRankCrestView(tierName: store.currentTier.name, size: 28)
                        Text(store.currentTier.name.uppercased())
                            .font(WBDesign.Typography.label(11))
                            .foregroundStyle(WBDesign.Palette.yellow)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    WBSectionHeader(title: "Your Career")
                    let progress = Array(store.masteryProgress.filter { $0.total > 0 }.prefix(4))
                    if progress.isEmpty {
                        Text("Start playing to unlock Career collections and trophies.")
                            .font(WBDesign.Typography.body(13))
                            .foregroundStyle(WBDesign.Palette.textSecondary)
                    } else {
                        ForEach(progress) { item in
                            HStack(spacing: 10) {
                                WBRankCrestView(tierName: item.historicalTier?.label ?? "Rookie", size: 34)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.collection.name)
                                            .font(WBDesign.Typography.body(13))
                                        Spacer()
                                        Text("\(item.percent)%")
                                            .font(WBDesign.Typography.number(13))
                                            .foregroundStyle(WBDesign.Palette.cyan)
                                    }
                                    ProgressView(value: item.fraction)
                                        .tint(WBDesign.Palette.green)
                                }
                            }
                        }
                    }
                }
                .padding(17)
                .background(WBDesign.Palette.surfaceRaised.opacity(0.75), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    WBProfileTile(title: "Stats", subtitle: "\(accuracy)% accuracy", systemImage: "chart.bar.fill", tint: WBDesign.Palette.blue) {}
                    WBProfileTile(title: "Achievements", subtitle: "\(store.profile.mastery.earnedAwards.count) trophies", systemImage: "trophy.fill", tint: WBDesign.Palette.yellow) {}
                    WBProfileTile(title: "Locker Room", subtitle: "Avatar & colours", systemImage: "tshirt.fill", tint: WBDesign.Palette.green, action: showLockerRoom)
                    WBProfileTile(title: "Season Ticket", subtitle: purchases.isClubMember ? "Active" : "Upgrade", systemImage: "ticket.fill", tint: WBDesign.Palette.purple, action: showShop)
                }

                Button(action: showShop) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.title2.weight(.black))
                            .foregroundStyle(WBDesign.Palette.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(purchases.isClubMember ? "SEASON TICKET ACTIVE" : "GET THE SEASON TICKET")
                                .font(WBDesign.Typography.cardTitle(15))
                            Text(purchases.isClubMember ? "Premium themes and member rewards unlocked" : "No forced ads · premium themes · recurring Wikicoins")
                                .font(WBDesign.Typography.body(11))
                                .foregroundStyle(WBDesign.Palette.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(WBDesign.Palette.yellow)
                    }
                    .padding(16)
                    .background(LinearGradient(colors: [WBDesign.Palette.purple.opacity(0.62), WBDesign.Palette.surfaceRaised], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 22)
        }
    }
}

private struct WBProfileTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.black))
                    .foregroundStyle(tint)
                Text(title.uppercased())
                    .font(WBDesign.Typography.cardTitle(14))
                Text(subtitle)
                    .font(WBDesign.Typography.body(10))
                    .foregroundStyle(WBDesign.Palette.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .padding(14)
            .background(WBDesign.Palette.surfaceRaised.opacity(0.78), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(tint.opacity(0.18), lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }
}

struct WBLockerRoomView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService
    @Environment(\.dismiss) private var dismiss

    @AppStorage(WBAvatarCatalog.storageKey) private var savedPresetID = WBAvatarCatalog.defaultPresetID
    @AppStorage(WBAvatarCatalog.backgroundKey) private var savedBackgroundID = "spectrum"

    @State private var draftPresetID = WBAvatarCatalog.defaultPresetID
    @State private var draftBackgroundID = "spectrum"
    @State private var displayName = ""

    var body: some View {
        NavigationStack {
            WBAppBackground()
                .overlay {
                    ScrollView {
                        VStack(spacing: 18) {
                            WBIllustratedAvatarView(presetID: draftPresetID, backgroundID: draftBackgroundID, size: 150)
                                .padding(.top, 8)

                            TextField("Player name", text: $displayName)
                                .font(WBDesign.Typography.cardTitle(18))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .frame(height: 48)
                                .background(WBDesign.Palette.surfaceRaised, in: Capsule())
                                .padding(.horizontal, 36)

                            VStack(alignment: .leading, spacing: 11) {
                                WBSectionHeader(title: "Avatar")
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 10)], spacing: 10) {
                                    ForEach(WBAvatarCatalog.presets) { preset in
                                        let locked = preset.access == .seasonTicket && !store.hasClubAccess(purchases.isClubMember)
                                        Button {
                                            if !locked { draftPresetID = preset.id }
                                        } label: {
                                            ZStack(alignment: .topTrailing) {
                                                WBIllustratedAvatarView(presetID: preset.id, backgroundID: draftBackgroundID, size: 78, showFrame: draftPresetID == preset.id)
                                                if locked {
                                                    Image(systemName: "lock.fill")
                                                        .font(.caption.weight(.black))
                                                        .foregroundStyle(WBDesign.Palette.yellow)
                                                        .padding(6)
                                                        .background(WBDesign.Palette.surface, in: Circle())
                                                }
                                            }
                                            .opacity(locked ? 0.62 : 1)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Avatar \(preset.displayName)\(locked ? ", Season Ticket required" : "")")
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 11) {
                                WBSectionHeader(title: "Colours")
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                                    ForEach(WBAvatarCatalog.backgrounds) { background in
                                        let locked = background.premium && !store.hasClubAccess(purchases.isClubMember)
                                        Button {
                                            if !locked { draftBackgroundID = background.id }
                                        } label: {
                                            VStack(spacing: 7) {
                                                Circle()
                                                    .fill(LinearGradient(colors: background.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                                    .frame(width: 46, height: 46)
                                                    .overlay {
                                                        Circle().stroke(draftBackgroundID == background.id ? Color.white : Color.white.opacity(0.18), lineWidth: draftBackgroundID == background.id ? 3 : 1)
                                                    }
                                                HStack(spacing: 3) {
                                                    Text(background.name)
                                                        .font(WBDesign.Typography.label(8))
                                                        .foregroundStyle(.white)
                                                        .lineLimit(1)
                                                    if locked { Image(systemName: "lock.fill").font(.caption2) }
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(10)
                                            .background(WBDesign.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            HStack(spacing: 10) {
                                Button("CANCEL") { dismiss() }
                                    .font(WBDesign.Typography.label(11))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(WBDesign.Palette.surfaceRaised, in: Capsule())

                                Button("SAVE PLAYER") {
                                    savedPresetID = draftPresetID
                                    savedBackgroundID = draftBackgroundID
                                    store.updateProfile(
                                        displayName: displayName,
                                        avatarEmoji: store.profile.avatarEmoji,
                                        avatarColor: store.profile.avatarColor,
                                        avatarUsesInitials: false,
                                        favoriteTeam: store.profile.favoriteTeam,
                                        favoritePlayer: store.profile.favoritePlayer
                                    )
                                    dismiss()
                                }
                                .font(WBDesign.Typography.label(11))
                                .foregroundStyle(Color(red: 0.05, green: 0.07, blue: 0.16))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(WBDesign.Palette.yellow, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(18)
                    }
                }
                .navigationTitle("Locker Room")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            draftPresetID = savedPresetID
            draftBackgroundID = savedBackgroundID
            displayName = store.profile.displayName
        }
    }
}

struct WBShopView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WBAppBackground()
                .overlay {
                    ScrollView {
                        VStack(spacing: 16) {
                            WBArtCard(
                                artworkName: WBArtwork.Shop.seasonTicketBackground,
                                cornerRadius: 28,
                                fallbackColors: [Color(red: 0.35, green: 0.10, blue: 0.55), Color(red: 0.10, green: 0.07, blue: 0.24)]
                            ) {
                                VStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 42, weight: .black))
                                        .foregroundStyle(WBDesign.Palette.yellow)
                                    Text("SEASON TICKET")
                                        .font(WBDesign.Typography.hero(30))
                                    Text(purchases.isClubMember ? "ACTIVE" : "THE ULTIMATE WIKIBALL PASS")
                                        .font(WBDesign.Typography.label(11))
                                        .foregroundStyle(WBDesign.Palette.yellow)
                                    Text("No forced ads · recurring Wikicoins · premium themes · member cosmetics")
                                        .font(WBDesign.Typography.body(13))
                                        .foregroundStyle(WBDesign.Palette.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 300)
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity)
                            }
                            .frame(minHeight: 230)

                            if purchases.subscriptions.isEmpty {
                                Text(purchases.isLoading ? "Loading Season Ticket options…" : "Season Ticket products are unavailable in this build.")
                                    .font(WBDesign.Typography.body(13))
                                    .foregroundStyle(WBDesign.Palette.textSecondary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity)
                                    .background(WBDesign.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            } else {
                                ForEach(purchases.subscriptions, id: \.id) { product in
                                    Button {
                                        Task { await purchases.purchase(product) }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(product.displayName.uppercased())
                                                    .font(WBDesign.Typography.cardTitle(16))
                                                Text(product.description)
                                                    .font(WBDesign.Typography.body(10))
                                                    .foregroundStyle(WBDesign.Palette.textSecondary)
                                                    .lineLimit(2)
                                            }
                                            Spacer()
                                            Text(product.displayPrice)
                                                .font(WBDesign.Typography.number(16))
                                                .foregroundStyle(WBDesign.Palette.yellow)
                                        }
                                        .padding(16)
                                        .background(WBDesign.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            WBSectionHeader(title: "Wikicoins")
                            ForEach(purchases.coinPacks, id: \.id) { product in
                                Button {
                                    Task { await purchases.purchase(product) }
                                } label: {
                                    HStack {
                                        WBIconAsset(asset: WBArtwork.coin, fallbackSystemImage: "circle.hexagongrid.fill", size: 28, tint: WBDesign.Palette.yellow)
                                        Text("\(PurchaseService.coinAmount(for: product.id) ?? 0) WIKICOINS")
                                            .font(WBDesign.Typography.cardTitle(15))
                                        Spacer()
                                        Text(product.displayPrice)
                                            .font(WBDesign.Typography.number(15))
                                            .foregroundStyle(WBDesign.Palette.yellow)
                                    }
                                    .padding(15)
                                    .background(WBDesign.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }

                            if let message = purchases.statusMessage {
                                Text(message)
                                    .font(WBDesign.Typography.body(12))
                                    .foregroundStyle(WBDesign.Palette.textSecondary)
                                    .multilineTextAlignment(.center)
                            }

                            Button("RESTORE PURCHASES") {
                                Task { await purchases.restorePurchases() }
                            }
                            .font(WBDesign.Typography.label(10))
                            .foregroundStyle(WBDesign.Palette.cyan)
                            .padding(.vertical, 10)
                        }
                        .padding(18)
                    }
                }
                .navigationTitle("Shop")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                }
        }
        .preferredColorScheme(.dark)
        .task { await purchases.prepare() }
    }
}
