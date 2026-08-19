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

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Text("WIKIBALL ⚽️").font(.system(size: 23, weight: .black, design: .rounded))
                    Spacer()
                    WalletPill(icon: "🔥", value: "\(store.profile.streak)")
                    WalletPill(icon: "🪙", value: "\(store.profile.coins)")
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
        .background(
            LinearGradient(colors: [.purple.opacity(0.9), .blue.opacity(0.72), .mint.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
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
                                    if round.hints >= 3 { Label("Starts with “\(round.seed.name.prefix(1))”", systemImage: "textformat") }
                                }
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.yellow)
                            }

                            HStack(spacing: 10) {
                                TextField("Type a player name…", text: $store.guess)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .submitLabel(.go)
                                    .focused($focused)
                                    .onSubmit { store.submitGuess() }
                                    .padding(14)
                                    .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
                                Button("Guess") { store.submitGuess() }
                                    .buttonStyle(FilledButtonStyle(tint: .mint))
                            }

                            HStack {
                                Button { store.buyHint() } label: { Label("Hint · 20", systemImage: "lightbulb.fill") }
                                    .buttonStyle(.bordered).tint(.yellow)
                                    .disabled(round.hints >= 3)
                                Spacer()
                                Button("Give up", role: .destructive) { store.giveUp() }
                            }
                        } else {
                            result(for: round)
                        }

                        HStack(spacing: 6) {
                            Circle().fill(round.usedLiveWikipedia ? Color.mint : Color.orange).frame(width: 7, height: 7)
                            Text(round.usedLiveWikipedia ? "Live career loaded from Wikipedia" : "Curated fallback career")
                        }
                        .font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(20)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 28))

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
}

private struct WalletPill: View {
    let icon: String
    let value: String
    var body: some View { Text("\(icon) \(value)").font(.caption.weight(.black)).padding(.horizontal, 10).padding(.vertical, 7).background(.white.opacity(0.09), in: Capsule()) }
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
