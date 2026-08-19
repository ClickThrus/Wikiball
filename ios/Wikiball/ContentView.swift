import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.055, green: 0.06, blue: 0.14), Color(red: 0.09, green: 0.07, blue: 0.19)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            if store.round == nil { HomeView() } else { GameView() }
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .medium), trigger: store.feedbackPulse)
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
    }
}

private struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showingProfile = false

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
                    WalletPill(icon: "🪙", value: "\(store.profile.coins)")
                    Button { showingProfile = true } label: {
                        Image(systemName: "person.crop.circle.fill").font(.title2)
                    }
                    .accessibilityLabel("Open player profile")
                }
                .padding(.top, 8)

                hero
                tierCard
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
    @FocusState private var focused: Bool

    var body: some View {
        if let round = store.round {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button { store.closeRound() } label: { Label("Wikiball", systemImage: "chevron.left") }
                            .font(.headline.weight(.black)).foregroundStyle(.white)
                        Spacer()
                        WalletPill(icon: "🔥", value: "\(store.profile.streak)")
                        WalletPill(icon: "🪙", value: "\(store.profile.coins)")
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
                            if round.hints > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    if round.hints >= 1 { Label(round.seed.nationality, systemImage: "globe") }
                                    if round.hints >= 2 { Label(round.seed.position, systemImage: "figure.soccer") }
                                    if round.hints >= 3 { Label("Surname starts with “\(surnameInitial(for: round.seed.name))”", systemImage: "textformat") }
                                }
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.yellow)
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
                            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white.opacity(0.07))
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
            }

            if let source = URL(string: "https://en.wikipedia.org/wiki/\(round.seed.wikipediaTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? round.seed.wikipediaTitle)") {
                Link(destination: source) { Label("Wikipedia source", systemImage: "arrow.up.right.square") }
                    .font(.subheadline.weight(.bold)).foregroundStyle(.mint)
            }

            if let share = store.shareText() {
                ShareLink(item: share) { Label("Share result", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.bordered).tint(.white)
            }

            Button("Next player") { Task { await store.startRound() } }
                .buttonStyle(FilledButtonStyle(tint: .mint)).frame(maxWidth: .infinity)
            Button("Back to modes") { store.closeRound() }.foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func surnameInitial(for name: String) -> String {
        name.split(separator: " ").last.map { String($0.prefix(1)).uppercased() } ?? String(name.prefix(1)).uppercased()
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
    @Environment(\.dismiss) private var dismiss

    private var accuracy: Int {
        guard store.profile.played > 0 else { return 0 }
        return Int((Double(store.profile.correct) / Double(store.profile.played) * 100).rounded())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        Text(store.currentTier.icon).font(.system(size: 64))
                        Text(store.currentTier.name).font(.largeTitle.weight(.black))
                        Text("\(store.profile.xp) XP · 🪙 \(store.profile.coins)").foregroundStyle(.secondary)
                        ProgressView(value: store.tierProgress).tint(.yellow)
                    }
                    .padding(22).frame(maxWidth: .infinity)
                    .background(.purple.opacity(0.18), in: RoundedRectangle(cornerRadius: 24))

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
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
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

private extension View {
    @ViewBuilder
    func guessInputTraits() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.words).autocorrectionDisabled().submitLabel(.go)
        #else
        self
        #endif
    }
}
