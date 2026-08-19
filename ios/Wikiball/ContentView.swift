import SwiftUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewedMasteryAward: MasteryAwardRecord?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.055, green: 0.06, blue: 0.14), Color(red: 0.09, green: 0.07, blue: 0.19)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            if store.round == nil { HomeView() } else { GameView() }
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .medium), trigger: store.feedbackPulse)
        .sensoryFeedback(.success, trigger: store.successPulse)
        .sensoryFeedback(.warning, trigger: store.warningPulse)
        .overlay {
            if store.isLoading {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView().controlSize(.large).tint(.white)
                        Text("Loading career…").font(.headline)
                    }
                    .padding(28)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                }
            }
        }
        .overlay {
            if let moment = store.matchMoment {
                MatchMomentView(moment: moment, playerImage: store.successPlayerImage, playerName: store.round?.seed.name)
                    .id(moment.id)
                    .transition(.opacity.combined(with: .scale(scale: 1.12)))
            }
        }
        .overlay {
            if let award = store.masteryCelebration {
                TrophyUnlockCelebrationView(award: award) {
                    viewedMasteryAward = award
                    store.dismissMasteryCelebration()
                }
            }
        }
        .sheet(item: $viewedMasteryAward) { award in NavigationStack { TrophyDetailView(collectionID: award.collectionID) } }
        .animation(.spring(response: 0.34, dampingFraction: 0.76), value: store.matchMoment)
        .onAppear { store.syncBackgroundMusic() }
        .onChange(of: store.round != nil) { _, _ in store.syncBackgroundMusic() }
        .onChange(of: scenePhase) { _, phase in store.setAppActive(phase == .active) }
    }
}

private struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService
    @State private var showingProfile = false
    @State private var showingShop = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Image("BrandMark")
                        .resizable().scaledToFit().frame(width: 34, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityHidden(true)
                    Text("WIKIBALL").font(.system(size: 23, weight: .black, design: .rounded))
                    Spacer()
                    WalletPill(icon: "🔥", value: "\(store.profile.streak)")
                    Button { showingShop = true } label: { WalletPill(icon: "🪙", value: "\(store.profile.coins)") }
                        .buttonStyle(.plain).accessibilityLabel("Open shop. \(store.profile.coins) Wikicoins")
                    Button { showingProfile = true } label: {
                        ProfileAvatarView(profile: store.profile, size: 34)
                            .frame(width: 32, height: 32).background(.white.opacity(0.09), in: Circle())
                    }
                    .accessibilityLabel("Open \(store.profile.displayName) profile")
                }
                .padding(.top, 8)

                hero
                tierCard
                if let target = store.nextMasteryTarget { nextMasteryCard(target) }
                clubCard
                modes
                filters
                stats

                Text("Career data fetched from Wikipedia when available")
                    .font(.caption2).foregroundStyle(.white.opacity(0.42)).padding(.top, 2)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 34)
        }
        .sheet(isPresented: $showingProfile) { ProfileView() }
        .sheet(isPresented: $showingShop) { WikiballStoreView() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THE FOOTBALL CAREER GUESSING GAME")
                .font(.caption2.weight(.black)).tracking(1.2).foregroundStyle(.mint)
            Text("Know the journey.\nName the player.")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .minimumScaleFactor(0.75)
            Text("Follow the clubs, read the eras and climb from Rookie to Legend.")
                .font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background {
            ZStack {
                LinearGradient(colors: [.indigo.opacity(0.95), .blue.opacity(0.74), .purple.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                FootballBackdrop(density: .hero)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private var tierCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(store.currentTier.icon).font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT TIER").font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.5))
                    Text(store.currentTier.name).font(.title3.weight(.black))
                }
                Spacer()
                Text("\(store.profile.xp) XP").font(.headline.weight(.black)).foregroundStyle(.yellow)
            }
            ProgressView(value: store.tierProgress).tint(.yellow).scaleEffect(x: 1, y: 1.7)
            if let next = store.nextTier {
                HStack {
                    Text("\(store.currentTier.minimumXP) XP")
                    Spacer()
                    Text("\(next.name) · \(next.minimumXP) XP")
                }
                .font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
    }

    private func nextMasteryCard(_ progress: MasteryProgress) -> some View {
        Button { Task { await store.startMasteryRound(collectionID: progress.id) } } label: {
            HStack(spacing: 14) {
                TrophyArtworkView(tier: progress.historicalTier, family: progress.collection.trophyFamily, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT TROPHY").font(.caption2.weight(.black)).tracking(1).foregroundStyle(.yellow)
                    Text("\(progress.collection.icon) \(progress.collection.name) · \(progress.nextMilestone?.tier.label ?? "Master")").font(.headline.weight(.black))
                    Text("\(progress.percent)% · \(progress.playersToNext) player\(progress.playersToNext == 1 ? "" : "s") to go").font(.caption).foregroundStyle(.white.opacity(0.65))
                }
                Spacer(); Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(.mint)
            }.padding(16).background(.yellow.opacity(0.07), in: RoundedRectangle(cornerRadius: 20)).overlay { RoundedRectangle(cornerRadius: 20).stroke(.yellow.opacity(0.16)) }
        }.buttonStyle(.plain)
    }

    private var modes: some View {
        VStack(spacing: 12) {
            ModeButton(icon: "calendar.badge.clock", title: "Daily Challenge", subtitle: "One shared player every day · bonus XP", tint: .orange) {
                Task { await store.startRound(daily: true) }
            }
            ModeButton(icon: "bolt.fill", title: "Quick Play", subtitle: "\(store.filteredPlayers.count) players match your filters", tint: .mint, disabled: store.filteredPlayers.isEmpty) {
                Task { await store.startRound() }
            }
            ModeButton(icon: "shuffle", title: "Surprise Me", subtitle: "Reset filters and kick off instantly", tint: .cyan) {
                Task { await store.surpriseMe() }
            }
        }
    }

    private var clubCard: some View {
        Button { showingShop = true } label: {
            HStack(spacing: 14) {
                Image(systemName: purchases.isClubMember ? "crown.fill" : "crown")
                    .font(.title2.weight(.black)).foregroundStyle(.yellow)
                    .frame(width: 42, height: 42).background(.yellow.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 3) {
                    Text(purchases.isClubMember ? "WIKIBALL CLUB ACTIVE" : "JOIN WIKIBALL CLUB")
                        .font(.caption.weight(.black)).tracking(0.8).foregroundStyle(.yellow)
                    Text(purchases.isClubMember ? "Member badge · recurring Wikicoins" : "Support Wikiball and receive recurring Wikicoins")
                        .font(.caption).foregroundStyle(.white.opacity(0.62)).multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.5))
            }
            .padding(16).background(.yellow.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).stroke(.yellow.opacity(0.18)) }
        }
        .buttonStyle(.plain)
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("BUILD YOUR ROUND").font(.caption2.weight(.black)).tracking(1).foregroundStyle(.pink)
                    Text("Play your football era").font(.title2.weight(.black))
                }
                Spacer()
                Button("Reset") { store.resetFilters() }.buttonStyle(.borderless).foregroundStyle(.white.opacity(0.65))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                FilterMenu(icon: "scope", title: store.filters.difficulty?.label ?? "Any difficulty") {
                    Button("Any difficulty") { store.filters.difficulty = nil }
                    ForEach(Difficulty.allCases) { value in Button(value.label) { store.filters.difficulty = value } }
                }
                FilterMenu(icon: "calendar", title: store.filters.decade ?? "Any decade") {
                    Button("Any decade") { store.filters.decade = nil }
                    ForEach(SeedData.decades, id: \.self) { value in Button(value) { store.filters.decade = value } }
                }
                FilterMenu(icon: "shield.fill", title: store.filters.team ?? "Any club") {
                    Button("Any club") { store.filters.team = nil }
                    ForEach(SeedData.teams, id: \.self) { value in Button(value) { store.filters.team = value } }
                }
                FilterMenu(icon: "globe.europe.africa.fill", title: store.filters.region?.rawValue ?? "Any region") {
                    Button("Any region") { store.filters.region = nil }
                    ForEach(Region.allCases) { value in Button(value.rawValue) { store.filters.region = value } }
                }
                FilterMenu(icon: "trophy.fill", title: store.selectedLeague?.label ?? "Any league / country") {
                    Button("Any league / country") { store.filters.leagueID = nil }
                    ForEach(SeedData.leagues) { value in Button(value.label) { store.filters.leagueID = value.id } }
                }
                .gridCellColumns(2)
            }

            if store.filters != GameFilters() {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let value = store.filters.difficulty { ActiveFilterChip(value.label) { store.filters.difficulty = nil } }
                        if let value = store.filters.decade { ActiveFilterChip(value) { store.filters.decade = nil } }
                        if let value = store.filters.team { ActiveFilterChip(value) { store.filters.team = nil } }
                        if let value = store.filters.region { ActiveFilterChip(value.rawValue) { store.filters.region = nil } }
                        if let value = store.selectedLeague { ActiveFilterChip(value.label) { store.filters.leagueID = nil } }
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: store.filteredPlayers.isEmpty ? "exclamationmark.triangle.fill" : "sparkles")
                if store.filteredPlayers.isEmpty {
                    Text("No players match yet. Remove a filter.")
                } else {
                    Text("\(store.filteredPlayers.count) possible players with this combination")
                }
            }
            .font(.footnote.weight(.bold))
            .foregroundStyle(store.filteredPlayers.isEmpty ? .orange : .mint)
            .padding(.top, 2)
            if store.filteredPlayers.isEmpty {
                Button("Reset filters") { store.resetFilters() }
                    .buttonStyle(.borderedProminent).tint(.orange)
            }
        }
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
    }

    private var stats: some View {
        HStack(spacing: 8) {
            StatBox(icon: "checkmark.circle.fill", value: "\(store.profile.correct)", label: "Correct")
            StatBox(icon: "gamecontroller.fill", value: "\(store.profile.played)", label: "Played")
            StatBox(icon: "flame.fill", value: "\(store.profile.bestStreak)", label: "Best")
            let accuracy = store.profile.played == 0 ? 0 : Int((Double(store.profile.correct) / Double(store.profile.played) * 100).rounded())
            StatBox(icon: "trophy.fill", value: "\(accuracy)%", label: "Accuracy")
        }
    }
}

private struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService
    @FocusState private var focused: Bool
    @State private var showingShop = false

    var body: some View {
        if let round = store.round {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button { store.closeRound() } label: { Label("Wikiball", systemImage: "chevron.left") }
                            .font(.headline.weight(.black)).foregroundStyle(.white)
                        Spacer()
                        WalletPill(icon: "🔥", value: "\(store.profile.streak)")
                        if purchases.isClubMember { Image(systemName: "crown.fill").foregroundStyle(.yellow).accessibilityLabel("Wikiball Club member") }
                        Button { showingShop = true } label: { WalletPill(icon: "🪙", value: "\(store.profile.coins)") }
                            .buttonStyle(.plain).accessibilityLabel("Open shop. \(store.profile.coins) Wikicoins")
                    }
                    .padding(.top, 8)

                    HStack {
                        Text(round.seed.difficulty.rawValue.uppercased())
                            .font(.caption2.weight(.black)).padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.purple.opacity(0.55), in: Capsule())
                        if round.daily { Text("DAILY").font(.caption2.weight(.black)).padding(.horizontal, 10).padding(.vertical, 6).background(.orange.opacity(0.7), in: Capsule()) }
                        Spacer()
                        HStack(spacing: 5) {
                            ForEach(0..<3, id: \.self) { index in Text("⚽️").opacity(index < round.attempts ? 1 : 0.2) }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(round.attempts) attempts remaining")
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        Text("WHO AM I?").font(.caption2.weight(.black)).tracking(1.2).foregroundStyle(.mint)
                        Text("Guess the player from their career")
                            .font(.system(size: 29, weight: .black, design: .rounded))

                        VStack(spacing: 0) {
                            ForEach(Array(round.career.enumerated()), id: \.offset) { index, stop in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(stop.years).font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.52)).frame(width: 82, alignment: .trailing)
                                    VStack(spacing: 0) {
                                        Circle().fill(index == round.career.count - 1 ? Color.mint : Color.purple).frame(width: 11, height: 11)
                                        if index < round.career.count - 1 { Rectangle().fill(.white.opacity(0.14)).frame(width: 2, height: 38) }
                                    }
                                    Text(stop.club).font(.body.weight(.bold)).frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        if !round.resolved {
                            if round.hints > 0 || round.profileHintRevealed {
                                VStack(alignment: .leading, spacing: 8) {
                                    if round.hints >= 1 {
                                        HintRevealCard(icon: "globe.americas.fill", eyebrow: "NATIONALITY", value: round.seed.nationality, colors: [.blue, .cyan])
                                            .transition(.move(edge: .trailing).combined(with: .opacity))
                                    }
                                    if round.hints >= 2 {
                                        HintRevealCard(icon: "figure.soccer", eyebrow: "POSITION", value: round.seed.position, colors: [.purple, .pink])
                                            .transition(.move(edge: .trailing).combined(with: .opacity))
                                    }
                                    if round.hints >= 3 {
                                        HintRevealCard(icon: "textformat", eyebrow: "NAME CLUE", value: "Surname starts with “\(surnameInitial(for: round.seed.name))”", colors: [.orange, .yellow])
                                            .transition(.move(edge: .trailing).combined(with: .opacity))
                                    }
                                    if round.profileHintRevealed, let hint = round.profileHint {
                                        HintRevealCard(icon: "person.crop.circle.fill", eyebrow: "MY PROFILE CONNECTION", value: hint, colors: [.mint, .blue])
                                            .transition(.move(edge: .trailing).combined(with: .opacity))
                                    }
                                }
                                .animation(.spring(response: 0.42, dampingFraction: 0.76), value: round.hints + (round.profileHintRevealed ? 10 : 0))
                            }

                            HStack(spacing: 10) {
                                TextField("Type a player name…", text: $store.guess)
                                    .guessInputTraits()
                                    .focused($focused)
                                    .onSubmit { store.submitGuess() }
                                    .padding(14)
                                    .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
                                Button("Guess") { store.submitGuess() }
                                    .buttonStyle(FilledButtonStyle(tint: .mint))
                            }

                            HStack {
                                Button { store.buyHint() } label: { Label("Hint · \(GameRules.hintCost)", systemImage: "lightbulb.fill") }
                                    .buttonStyle(.bordered).tint(.yellow)
                                    .disabled(round.hints >= 3)
                                Spacer()
                                Button("Give up", role: .destructive) { store.giveUp() }
                            }
                            if round.profileHint != nil && !round.profileHintRevealed {
                                Button { store.buyProfileHint() } label: {
                                    Label("My Profile Hint · \(GameRules.hintCost)", systemImage: "person.crop.circle.badge.questionmark")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered).tint(.cyan)
                            }
                        } else {
                            result(for: round)
                        }

                        if round.resolved {
                            HStack(spacing: 6) {
                                Circle().fill(round.usedLiveWikipedia ? Color.mint : Color.orange).frame(width: 7, height: 7)
                                Text(round.usedLiveWikipedia ? "Live career loaded from Wikipedia" : "Curated fallback career")
                            }
                            .font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.45))
                        }
                    }
                    .padding(20)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(LinearGradient(colors: [roundAccent(round).opacity(0.18), .white.opacity(0.055)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            FootballBackdrop(density: .career)
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                    }

                    if !store.message.isEmpty {
                        Text(store.message).font(.subheadline.weight(.bold)).foregroundStyle(.white).padding(14).frame(maxWidth: .infinity).background(.black.opacity(0.28), in: Capsule())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 34)
            }
            .onAppear { focused = !round.resolved }
            .sheet(isPresented: $showingShop) { WikiballStoreView() }
        }
    }

    @ViewBuilder
    private func result(for round: GameStore.RoundState) -> some View {
        VStack(spacing: 10) {
            Text(round.won ? "🎉" : "🫣").font(.system(size: 48))
            Text(round.seed.name).font(.title.weight(.black))
            Text("\(round.seed.nationality) · \(round.seed.position)").foregroundStyle(.white.opacity(0.65))
            if round.won {
                HStack(spacing: 18) {
                    Label("+\(round.reward.xp) XP", systemImage: "sparkles")
                    Label("+\(round.reward.coins)", systemImage: "circle.hexagongrid.fill")
                }
                .font(.headline.weight(.black)).foregroundStyle(.yellow)
                if let update = round.masteryUpdate { MasteryRoundFeedbackView(player: round.seed, update: update) }
            }

            if let source = URL(string: "https://en.wikipedia.org/wiki/\(round.seed.wikipediaTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? round.seed.wikipediaTitle)") {
                Link(destination: source) { Label("Wikipedia source", systemImage: "arrow.up.right.square") }
                    .font(.subheadline.weight(.bold)).foregroundStyle(.mint)
            }

            if let share = store.shareText() {
                ShareLink(item: share) { Label("Share result", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.bordered).tint(.white)
            }

            Button("Next player") { Task { await store.startNextRound() } }
                .buttonStyle(FilledButtonStyle(tint: .mint)).frame(maxWidth: .infinity)
            Button("Back to modes") { store.closeRound() }.foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func surnameInitial(for name: String) -> String {
        name.split(separator: " ").last.map { String($0.prefix(1)).uppercased() } ?? String(name.prefix(1)).uppercased()
    }

    private func roundAccent(_ round: GameStore.RoundState) -> Color {
        switch round.seed.difficulty {
        case .easy: return .blue
        case .medium: return .purple
        case .hard: return .orange
        }
    }
}

private struct HintRevealCard: View {
    let icon: String
    let eyebrow: String
    let value: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title2.weight(.bold)).frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow).font(.caption2.weight(.black)).tracking(0.9).foregroundStyle(.white.opacity(0.58))
                Text(value).font(.subheadline.weight(.black))
            }
            Spacer()
        }
        .padding(13)
        .background {
            ZStack(alignment: .trailing) {
                LinearGradient(colors: colors.map { $0.opacity(0.34) }, startPoint: .leading, endPoint: .trailing)
                Image(systemName: icon).font(.system(size: 68, weight: .black)).foregroundStyle(.white.opacity(0.07)).offset(x: 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MatchMomentView: View {
    let moment: MatchMoment
    let playerImage: CGImage?
    let playerName: String?
    @State private var revealed = false

    private var title: String {
        switch moment.kind {
        case .goal: return "GOAL!"
        case .nearMiss: return "JUST WIDE"
        case .farMiss: return "INTO THE CROWD"
        case .hint: return "CLUE UNLOCKED"
        }
    }

    private var subtitle: String {
        switch moment.kind {
        case .goal: return "Top bins. You know your football."
        case .nearMiss: return "That was agonisingly close."
        case .farMiss: return "Row Z. Reset and go again."
        case .hint: return "A little help from the touchline."
        }
    }

    private var tint: Color {
        switch moment.kind {
        case .goal: return .mint
        case .nearMiss: return .orange
        case .farMiss: return .red
        case .hint: return .yellow
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(revealed ? 0.72 : 0).ignoresSafeArea()
            Canvas { context, size in
                let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                for index in 0..<18 {
                    let angle = Double(index) / 18 * 2 * Double.pi
                    var ray = Path()
                    ray.move(to: centre)
                    ray.addLine(to: CGPoint(x: centre.x + cos(angle) * size.width, y: centre.y + sin(angle) * size.width))
                    context.stroke(ray, with: .color(tint.opacity(0.13)), lineWidth: index.isMultiple(of: 2) ? 3 : 1)
                }
            }
            .scaleEffect(revealed ? 1 : 0.2)

            VStack(spacing: 12) {
                if moment.kind == .goal, let playerImage {
                    Image(decorative: playerImage, scale: 1)
                        .resizable().scaledToFit().frame(maxWidth: 290, maxHeight: 270)
                        .shadow(color: tint.opacity(0.5), radius: 24, y: 12)
                        .transition(.scale(scale: 0.72).combined(with: .opacity))
                } else {
                    Image(systemName: moment.kind == .goal ? "soccerball" : "figure.soccer")
                        .font(.system(size: 72, weight: .black)).foregroundStyle(tint)
                        .rotationEffect(.degrees(revealed ? (moment.kind == .goal ? 360 : -12) : 0))
                        .offset(x: revealed ? 0 : (moment.kind == .nearMiss ? 120 : -100), y: revealed ? 0 : 90)
                }
                Text(title).font(.system(size: 43, weight: .black, design: .rounded)).foregroundStyle(.white)
                    .minimumScaleFactor(0.7).lineLimit(1)
                if moment.kind == .goal, let playerName {
                    Text(playerName).font(.title2.weight(.black)).foregroundStyle(tint)
                }
                Text(subtitle).font(.headline).foregroundStyle(.white.opacity(0.76)).multilineTextAlignment(.center)
                if moment.kind == .goal, playerImage != nil {
                    Text("Player image · Wikipedia / Wikimedia Commons")
                        .font(.caption2).foregroundStyle(.white.opacity(0.48))
                }
            }
            .padding(28)
            .scaleEffect(revealed ? 1 : 0.58)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.66)) { revealed = true }
        }
    }
}

private struct ActiveFilterChip: View {
    let label: String
    let action: () -> Void
    init(_ label: String, action: @escaping () -> Void) { self.label = label; self.action = action }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) { Text(label); Image(systemName: "xmark.circle.fill") }
                .font(.caption.weight(.bold)).padding(.horizontal, 10).padding(.vertical, 7)
                .background(.purple.opacity(0.38), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(label) filter")
    }
}

private struct ProfileView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService
    @Environment(\.dismiss) private var dismiss
    @State private var showingShop = false
    @State private var editingProfile = false

    private var accuracy: Int {
        guard store.profile.played > 0 else { return 0 }
        return Int((Double(store.profile.correct) / Double(store.profile.played) * 100).rounded())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        ProfileAvatarView(profile: store.profile, size: 92)
                        Text(store.profile.displayName).font(.largeTitle.weight(.black))
                        Text("\(store.currentTier.icon) \(store.currentTier.name)").font(.headline.weight(.black)).foregroundStyle(.yellow)
                        Text("\(store.profile.xp) XP · 🪙 \(store.profile.coins)").foregroundStyle(.secondary)
                        ProgressView(value: store.tierProgress).tint(.yellow)
                        Button(purchases.isClubMember ? "Wikiball Club · Active" : "Join Wikiball Club") { showingShop = true }
                            .buttonStyle(.borderedProminent).tint(purchases.isClubMember ? .yellow : .purple)
                    }
                    .padding(22).frame(maxWidth: .infinity)
                    .background(.purple.opacity(0.18), in: RoundedRectangle(cornerRadius: 24))

                    Toggle(isOn: $store.soundEnabled) {
                        Label("Music & sound effects", systemImage: store.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.headline)
                    }
                    .padding(16).background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

                    HStack(spacing: 12) {
                        ProfileFavouriteCard(icon: "shield.fill", label: "Favourite club", value: store.profile.favoriteTeam ?? "Not set")
                        ProfileFavouriteCard(icon: "person.fill", label: "Favourite player", value: store.profile.favoritePlayer ?? "Not set")
                    }

                    NavigationLink { ClubhouseView() } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "sportscourt.fill").font(.title2.weight(.black)).foregroundStyle(.mint).frame(width: 46, height: 46).background(.mint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 3) { Text("THE CLUBHOUSE").font(.headline.weight(.black)); Text("Mastery · Trophies · Player Cards · Sets").font(.caption).foregroundStyle(.secondary) }
                            Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }.padding(16).background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)

                    if !store.profile.mastery.featuredTrophyIDs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("FEATURED TROPHIES").font(.caption.weight(.black)).foregroundStyle(.secondary)
                            HStack { ForEach(store.profile.mastery.featuredTrophyIDs, id: \.self) { id in if let award = store.profile.mastery.earnedAwards[id], let collection = store.collection(for: award.collectionID) { VStack { TrophyArtworkView(tier: award.tier, family: collection.trophyFamily, size: 62); Text(collection.name).font(.caption2.weight(.bold)).lineLimit(2).multilineTextAlignment(.center) }.frame(maxWidth: .infinity) } } }
                        }.padding(16).background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ProfileStat("Games", "\(store.profile.played)")
                        ProfileStat("Accuracy", "\(accuracy)%")
                        ProfileStat("Correct", "\(store.profile.correct)")
                        ProfileStat("Best streak", "\(store.profile.bestStreak)")
                        ProfileStat("Daily wins", "\(store.profile.dailyCompleted)")
                        ProfileStat("Hints used", "\(store.profile.hintsUsed)")
                        ProfileStat("Easy correct", "\(store.profile.easyCorrect)")
                        ProfileStat("Medium correct", "\(store.profile.mediumCorrect)")
                        ProfileStat("Hard correct", "\(store.profile.hardCorrect)")
                    }
                }
                .padding()
            }
            .navigationTitle("Player Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Edit") { editingProfile = true } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showingShop) { WikiballStoreView() }
            .sheet(isPresented: $editingProfile) { ProfileEditorView() }
            .onChange(of: store.round != nil) { _, playing in if playing { dismiss() } }
        }
    }
}

private struct ProfileFavouriteCard: View {
    let icon: String
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.cyan)
            Text(label).font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.black)).lineLimit(2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .padding(12).background(.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct ProfileEditorView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var avatarEmoji = "⚽️"
    @State private var avatarColor = "purple"
    @State private var avatarUsesInitials = false
    @State private var favoriteTeam = ""
    @State private var favoritePlayer = ""

    private let avatars = ["⚽️", "🧤", "🎯", "🏆", "🦁", "🌍", "🔥", "⭐️"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Your profile") {
                    HStack(spacing: 18) {
                        ProfileAvatarView(
                            displayName: displayName,
                            emoji: avatarEmoji,
                            colorID: avatarColor,
                            usesInitials: avatarUsesInitials,
                            size: 76
                        )
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Preview").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                            Text(displayName.nilIfBlank ?? "Player")
                                .font(.title3.weight(.black)).lineLimit(1)
                        }
                    }
                    .padding(.vertical, 8)

                    TextField("Enter your name", text: $displayName)
                        .profileNameInputTraits()
                    Text("Up to 24 characters").font(.caption).foregroundStyle(.secondary)

                    Picker("Avatar style", selection: $avatarUsesInitials) {
                        Text("Emoji").tag(false)
                        Text("Initials").tag(true)
                    }
                    .pickerStyle(.segmented)

                    if !avatarUsesInitials {
                        TextField("Type any emoji", text: $avatarEmoji)
                            .onChange(of: avatarEmoji) { _, newValue in
                                if newValue.count > 1 { avatarEmoji = String(newValue.suffix(1)) }
                            }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(avatars, id: \.self) { avatar in
                                Button { avatarEmoji = avatar } label: {
                                    Text(avatar).font(.system(size: 32)).frame(maxWidth: .infinity).padding(8)
                                        .background(avatarEmoji == avatar ? Color.purple.opacity(0.28) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                                        .overlay { RoundedRectangle(cornerRadius: 12).stroke(avatarEmoji == avatar ? .purple : .clear, lineWidth: 2) }
                                }
                                .buttonStyle(.plain).accessibilityLabel("Use \(avatar) profile badge")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Badge colour").font(.subheadline.weight(.semibold))
                        HStack(spacing: 12) {
                            ForEach(ProfileAvatarPalette.ids, id: \.self) { colorID in
                                Button { avatarColor = colorID } label: {
                                    Circle().fill(ProfileAvatarPalette.color(for: colorID)).frame(width: 34, height: 34)
                                        .overlay { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white).opacity(avatarColor == colorID ? 1 : 0) }
                                        .overlay { Circle().stroke(.white.opacity(avatarColor == colorID ? 0.9 : 0), lineWidth: 2) }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Use \(colorID) badge colour")
                            }
                        }
                    }
                }

                Section("Football favourites") {
                    Picker("Favourite club", selection: $favoriteTeam) {
                        Text("Not set").tag("")
                        ForEach(SeedData.teams, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Favourite player", text: $favoritePlayer)
                        .profileNameInputTraits()
                }

                Section {
                    Text("Your favourites can unlock optional personal connection hints during a round. They never change which guesses count as correct.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Customise Profile")
            .iOSInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateProfile(displayName: displayName, avatarEmoji: avatarEmoji, avatarColor: avatarColor, avatarUsesInitials: avatarUsesInitials, favoriteTeam: favoriteTeam, favoritePlayer: favoritePlayer)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                displayName = store.profile.displayName
                avatarEmoji = store.profile.avatarEmoji
                avatarColor = store.profile.avatarColor
                avatarUsesInitials = store.profile.avatarUsesInitials
                favoriteTeam = store.profile.favoriteTeam ?? ""
                favoritePlayer = store.profile.favoritePlayer ?? ""
            }
        }
    }
}

private struct WikiballStoreView: View {
    @EnvironmentObject private var purchases: PurchaseService
    @Environment(\.dismiss) private var dismiss
    @State private var showingSubscriptionManager = false

    var body: some View {
        managedSubscriptions(content)
    }

    private var content: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: purchases.isClubMember ? "crown.fill" : "crown")
                            .font(.system(size: 48, weight: .black)).foregroundStyle(.yellow)
                        Text("Wikiball Club").font(.largeTitle.weight(.black))
                        Text(purchases.isClubMember ? "Your membership is active" : "Back the game. Build your coin balance.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)

                    if !purchases.isClubMember {
                        StoreSection(title: "MEMBERSHIP", subtitle: "Monthly members receive 100 Wikicoins per renewal; annual members receive 1,200.") {
                            ForEach(purchases.subscriptions) { product in StoreProductRow(product: product) }
                        }
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill").font(.title).foregroundStyle(.yellow)
                            VStack(alignment: .leading) {
                                Text("Club membership active").font(.headline.weight(.black))
                                Text("Your badge and renewal coins are enabled.").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(18).background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
                    }

                    StoreSection(title: "WIKICOIN TOP-UPS", subtitle: "Wikicoins never expire and hints always remain earnable through play.") {
                        ForEach(purchases.coinPacks) { product in StoreProductRow(product: product) }
                    }

                    if purchases.isLoading {
                        ProgressView("Contacting the App Store…").padding()
                    } else if purchases.products.isEmpty {
                        Button("Retry loading products") { Task { await purchases.prepare() } }
                            .buttonStyle(.borderedProminent)
                    }

                    if let message = purchases.statusMessage {
                        Text(message).font(.footnote.weight(.semibold)).multilineTextAlignment(.center)
                            .padding(12).frame(maxWidth: .infinity).background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(spacing: 10) {
                        Button("Restore Purchases") { Task { await purchases.restorePurchases() } }
                        if purchases.isClubMember {
                            Button("Manage Subscription") { showingSubscriptionManager = true }
                        }
                        Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the billing period. Payment is charged through your Apple Account. Prices shown are localized by the App Store.")
                            .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Link("Apple Standard EULA", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .font(.caption)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .background(Color(red: 0.055, green: 0.06, blue: 0.14).ignoresSafeArea())
            .navigationTitle("Shop")
            .iOSInlineNavigationTitle()
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { await purchases.prepare() }
        }
    }

    @ViewBuilder
    private func managedSubscriptions<Content: View>(_ content: Content) -> some View {
        #if os(iOS)
        content.manageSubscriptionsSheet(isPresented: $showingSubscriptionManager)
        #else
        content
        #endif
    }
}

private struct StoreSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.subtitle = subtitle; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.caption.weight(.black)).tracking(1).foregroundStyle(.purple)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StoreProductRow: View {
    @EnvironmentObject private var purchases: PurchaseService
    let product: Product

    private var benefit: String {
        if let coins = PurchaseService.coinAmount(for: product.id) { return "\(coins) Wikicoins" }
        if product.id == PurchaseService.ProductID.clubAnnual { return "1,200 coins each year · best value" }
        return "100 coins every month"
    }

    var body: some View {
        Button { Task { await purchases.purchase(product) } } label: {
            HStack(spacing: 14) {
                Image(systemName: product.type == .autoRenewable ? "crown.fill" : "circle.hexagongrid.fill")
                    .font(.title2).foregroundStyle(product.type == .autoRenewable ? .yellow : .orange)
                    .frame(width: 42, height: 42).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName).font(.headline.weight(.black))
                    Text(benefit).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if purchases.purchasingProductID == product.id {
                    ProgressView()
                } else {
                    Text(product.displayPrice).font(.headline.weight(.black)).foregroundStyle(.white)
                }
            }
            .padding(16).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(purchases.purchasingProductID != nil)
        .accessibilityLabel("\(product.displayName), \(benefit), \(product.displayPrice)")
    }
}

private struct ProfileStat: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }
    var body: some View {
        VStack(spacing: 5) {
            Text(value).font(.title2.weight(.black))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct WalletPill: View {
    let icon: String
    let value: String
    var body: some View { Text("\(icon) \(value)").font(.caption.weight(.black)).padding(.horizontal, 10).padding(.vertical, 7).background(.white.opacity(0.09), in: Capsule()) }
}

private struct FootballBackdrop: View {
    enum Density { case hero, career }
    let density: Density

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Canvas { context, size in
                    var route = Path()
                    route.move(to: CGPoint(x: size.width * 0.02, y: size.height * 0.82))
                    route.addCurve(
                        to: CGPoint(x: size.width * 0.94, y: size.height * 0.18),
                        control1: CGPoint(x: size.width * 0.28, y: size.height * 0.25),
                        control2: CGPoint(x: size.width * 0.66, y: size.height * 0.92)
                    )
                    context.stroke(route, with: .color(.white.opacity(0.12)), style: StrokeStyle(lineWidth: 1.5, dash: [7, 8]))

                    for progress in [0.18, 0.46, 0.74] {
                        let point = CGPoint(x: size.width * progress, y: size.height * (0.72 - progress * 0.38))
                        context.fill(Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)), with: .color(.white.opacity(0.14)))
                    }
                }

                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: density == .hero ? 104 : 126, weight: .thin))
                    .position(x: proxy.size.width * 0.84, y: proxy.size.height * 0.66)
                Image(systemName: "soccerball")
                    .font(.system(size: density == .hero ? 42 : 58, weight: .thin))
                    .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.23)
                Image(systemName: "flag.checkered")
                    .font(.system(size: density == .hero ? 28 : 36, weight: .light))
                    .position(x: proxy.size.width * 0.69, y: proxy.size.height * 0.18)
                if density == .career {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 86, weight: .thin))
                        .position(x: proxy.size.width * 0.82, y: proxy.size.height * 0.88)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 34, weight: .light))
                        .position(x: proxy.size.width * 0.18, y: proxy.size.height * 0.76)
                }
            }
            .foregroundStyle(.white.opacity(density == .hero ? 0.09 : 0.045))
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }
}

private struct ModeButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.title2.weight(.black)).foregroundStyle(tint).frame(width: 38, height: 38).background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline.weight(.black)); Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.55)) }
                Spacer(); Image(systemName: "arrow.right").font(.headline.weight(.black))
            }
            .padding(17).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 21))
        }
        .buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.45 : 1)
    }
}

private struct FilterMenu<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content
    init(icon: String, title: String, @ViewBuilder content: () -> Content) { self.icon = icon; self.title = title; self.content = content() }
    var body: some View {
        Menu { content } label: {
            HStack(spacing: 8) { Image(systemName: icon).foregroundStyle(.mint); Text(title).lineLimit(1); Spacer(); Image(systemName: "chevron.down").font(.caption2) }
                .font(.caption.weight(.bold)).foregroundStyle(.white).padding(12).background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) { Image(systemName: icon).foregroundStyle(.mint); Text(value).font(.headline.weight(.black)); Text(label).font(.caption2).foregroundStyle(.white.opacity(0.46)) }
            .frame(maxWidth: .infinity).padding(.vertical, 13).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct FilledButtonStyle: ButtonStyle {
    let tint: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.weight(.black)).foregroundStyle(.black).padding(.horizontal, 17).padding(.vertical, 13).background(tint.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 14)).scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

extension View {
    @ViewBuilder
    func guessInputTraits() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.words).autocorrectionDisabled().submitLabel(.go)
        #else
        self
        #endif
    }

    @ViewBuilder
    func iOSInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func profileNameInputTraits() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.words).autocorrectionDisabled()
        #else
        self
        #endif
    }
}
