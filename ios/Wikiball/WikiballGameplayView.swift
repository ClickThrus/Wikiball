import SwiftUI

struct WBGameplayView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService
    @FocusState private var guessFocused: Bool
    @State private var showingShop = false
    @State private var viewedAward: MasteryAwardRecord?

    var body: some View {
        ZStack {
            WBGameplayBackground()

            if let round = store.round {
                if round.resolved {
                    WBResultView(round: round, showShop: { showingShop = true })
                } else {
                    gameplay(round)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingShop) { WBShopView() }
        .sheet(item: $viewedAward) { award in
            WBTrophyDetailSheet(award: award)
        }
        .overlay {
            if let moment = store.matchMoment {
                WBMatchMomentOverlay(moment: moment, playerName: store.round?.seed.name)
                    .id(moment.id)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if let award = store.masteryCelebration {
                WBMasteryCelebration(award: award) {
                    viewedAward = award
                    store.dismissMasteryCelebration()
                }
            }
        }
        .onChange(of: store.round?.resolved) { _, resolved in
            if resolved == true { guessFocused = false }
        }
    }

    private func gameplay(_ round: GameStore.RoundState) -> some View {
        GeometryReader { proxy in
            let metrics = WBResponsiveMetrics(availableWidth: proxy.size.width)
            ScrollView {
                VStack(spacing: metrics.majorSectionSpacing) {
                    WBGameplayHUD(round: round, showShop: { showingShop = true }) {
                        guessFocused = false
                        store.closeRound()
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("GUESS THE PLAYER")
                                    .font(WBDesign.Typography.screenTitle(metrics.isCompact ? 24 : 28))
                                Text("CLUB JOURNEY")
                                    .font(WBDesign.Typography.label(11))
                                    .tracking(1.4)
                                    .foregroundStyle(WBDesign.Palette.cyan)
                            }
                            Spacer()
                            WBSmallStatusPill(title: round.seed.difficulty.rawValue, tint: difficultyTint(round.seed.difficulty))
                        }

                        WBClubJourneyTimeline(stops: round.career, compact: metrics.isCompact)

                        if round.hints > 0 || round.profileHintRevealed {
                            WBHintStack(round: round)
                        }

                        VStack(spacing: 10) {
                            HStack(spacing: 9) {
                                TextField("Type player name…", text: $store.guess)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .submitLabel(.go)
                                    .focused($guessFocused)
                                    .onSubmit { submitGuess() }
                                    .padding(.horizontal, 15)
                                    .frame(minHeight: 50)
                                    .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                    .overlay { RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color.white.opacity(0.11), lineWidth: 1) }

                                Button(action: submitGuess) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 34, weight: .black))
                                        .foregroundStyle(store.guess.nilIfBlank == nil ? WBDesign.Palette.textTertiary : WBDesign.Palette.green)
                                        .frame(width: 50, height: 50)
                                }
                                .buttonStyle(.plain)
                                .disabled(store.guess.nilIfBlank == nil)
                                .accessibilityLabel("Submit guess")
                            }

                            if !suggestions.isEmpty && guessFocused {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 7) {
                                        ForEach(suggestions, id: \.id) { player in
                                            Button(player.name) {
                                                store.guess = player.name
                                            }
                                            .font(WBDesign.Typography.body(11))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 11)
                                            .frame(minHeight: 34)
                                            .background(WBDesign.Palette.surfaceRaised, in: Capsule())
                                        }
                                    }
                                }
                            }

                            HStack(spacing: 10) {
                                Button {
                                    store.buyHint()
                                } label: {
                                    Label("HINT · \(store.hintCostLabel)", systemImage: "lightbulb.fill")
                                        .font(WBDesign.Typography.label(10))
                                        .foregroundStyle(Color(red: 0.06, green: 0.07, blue: 0.15))
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(WBDesign.Palette.yellow, in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .disabled(round.hints >= 3)

                                Button(role: .destructive) {
                                    guessFocused = false
                                    store.giveUp()
                                } label: {
                                    Text("GIVE UP")
                                        .font(WBDesign.Typography.label(10))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(WBDesign.Palette.red.opacity(0.72), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }

                            if round.profileHint != nil && !round.profileHintRevealed {
                                Button {
                                    store.buyProfileHint()
                                } label: {
                                    Label("MY PROFILE HINT · \(store.hintCostLabel)", systemImage: "person.crop.circle.badge.questionmark")
                                        .font(WBDesign.Typography.label(10))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, minHeight: 42)
                                        .background(WBDesign.Palette.blue.opacity(0.70), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if !store.message.isEmpty {
                            Text(store.message)
                                .font(WBDesign.Typography.body(12))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.black.opacity(0.23), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(metrics.isCompact ? 16 : 19)
                    .background(
                        LinearGradient(
                            colors: [difficultyTint(round.seed.difficulty).opacity(0.18), WBDesign.Palette.surface.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                    )
                    .overlay { RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
                }
                .frame(maxWidth: metrics.contentWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, metrics.horizontalMargin)
                .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 18))
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var suggestions: [PlayerSeed] {
        let query = store.guess.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return [] }
        return SeedData.players
            .filter { $0.name.localizedCaseInsensitiveContains(query) }
            .prefix(5)
            .map { $0 }
    }

    private func submitGuess() {
        let hadText = store.guess.nilIfBlank != nil
        guard hadText else { return }
        store.submitGuess()
        if store.round?.resolved == false {
            Task { @MainActor in guessFocused = true }
        }
    }

    private func difficultyTint(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return WBDesign.Palette.blue
        case .medium: return WBDesign.Palette.purple
        case .hard: return WBDesign.Palette.orange
        }
    }
}

private struct WBGameplayBackground: View {
    var body: some View {
        ZStack {
            WBDesign.Palette.background.ignoresSafeArea()
            RadialGradient(colors: [WBDesign.Palette.blue.opacity(0.13), Color.clear], center: .top, startRadius: 0, endRadius: 500).ignoresSafeArea()
        }
    }
}

private struct WBGameplayHUD: View {
    @EnvironmentObject private var store: GameStore
    let round: GameStore.RoundState
    let showShop: () -> Void
    let back: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.black))
                    .frame(width: 40, height: 40)
                    .background(WBDesign.Palette.surfaceRaised, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to Play")

            ProfileAvatarView(profile: store.profile, size: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("STREAK")
                    .font(WBDesign.Typography.label(8))
                    .foregroundStyle(WBDesign.Palette.textTertiary)
                HStack(spacing: 4) {
                    WBIconAsset(asset: WBArtwork.streak, fallbackSystemImage: "flame.fill", size: 14, tint: WBDesign.Palette.orange)
                    Text("\(store.profile.streak)")
                        .font(WBDesign.Typography.number(13))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("ATTEMPTS LEFT")
                    .font(WBDesign.Typography.label(8))
                    .foregroundStyle(WBDesign.Palette.textTertiary)
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "soccerball")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(index < round.attempts ? .white : .white.opacity(0.18))
                    }
                    Text("\(round.attempts)")
                        .font(WBDesign.Typography.number(14))
                        .padding(.leading, 2)
                }
            }

            Button(action: showShop) {
                WBWalletBadge(asset: WBArtwork.coin, fallbackSystemImage: "circle.hexagongrid.fill", value: store.coinBalanceLabel)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(WBDesign.Palette.surface.opacity(0.93), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
    }
}

private struct WBClubJourneyTimeline: View {
    let stops: [CareerStop]
    let compact: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                HStack(alignment: .top, spacing: compact ? 8 : 11) {
                    Text(stop.years)
                        .font(WBDesign.Typography.label(compact ? 8 : 9))
                        .foregroundStyle(WBDesign.Palette.textTertiary)
                        .frame(width: compact ? 72 : 82, alignment: .trailing)
                        .padding(.top, 16)

                    VStack(spacing: 0) {
                        Circle()
                            .fill(index == stops.count - 1 ? WBDesign.Palette.green : WBDesign.Palette.cyan)
                            .frame(width: 12, height: 12)
                            .overlay { Circle().stroke(.white.opacity(0.35), lineWidth: 2) }
                            .padding(.top, 18)
                        if index < stops.count - 1 {
                            Rectangle()
                                .fill(LinearGradient(colors: [WBDesign.Palette.cyan.opacity(0.55), Color.white.opacity(0.10)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 3, minHeight: 48)
                        }
                    }

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(WBDesign.Palette.surfaceRaised)
                            Image(systemName: "shield.fill")
                                .font(.headline.weight(.black))
                                .foregroundStyle(index == stops.count - 1 ? WBDesign.Palette.green : WBDesign.Palette.cyan)
                        }
                        .frame(width: 38, height: 38)

                        Text(stop.club)
                            .font(WBDesign.Typography.body(compact ? 12 : 13))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 50)
                    .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .environment(\.colorScheme, .light)
                    .padding(.bottom, index < stops.count - 1 ? 8 : 0)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct WBHintStack: View {
    let round: GameStore.RoundState

    var body: some View {
        VStack(spacing: 8) {
            if round.hints >= 1 { hint("NATIONALITY", value: round.seed.nationality, icon: "globe.europe.africa.fill", tint: WBDesign.Palette.blue) }
            if round.hints >= 2 { hint("POSITION", value: round.seed.position, icon: "figure.soccer", tint: WBDesign.Palette.purple) }
            if round.hints >= 3 { hint("NAME CLUE", value: surnameInitial, icon: "textformat", tint: WBDesign.Palette.orange) }
            if round.profileHintRevealed, let profileHint = round.profileHint { hint("MY PROFILE", value: profileHint, icon: "person.crop.circle.fill", tint: WBDesign.Palette.green) }
        }
    }

    private var surnameInitial: String {
        let letter = round.seed.name.split(separator: " ").last?.first.map(String.init) ?? String(round.seed.name.prefix(1))
        return "Surname starts with \(letter.uppercased())"
    }

    private func hint(_ title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WBDesign.Typography.label(8))
                    .foregroundStyle(WBDesign.Palette.textTertiary)
                Text(value)
                    .font(WBDesign.Typography.body(12))
            }
            Spacer()
        }
        .padding(11)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(tint.opacity(0.18), lineWidth: 1) }
    }
}

private struct WBResultView: View {
    @EnvironmentObject private var store: GameStore
    let round: GameStore.RoundState
    let showShop: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let metrics = WBResponsiveMetrics(availableWidth: proxy.size.width)
            ScrollView {
                VStack(spacing: metrics.majorSectionSpacing) {
                    HStack {
                        Button { store.closeRound() } label: {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.black))
                                .frame(width: 40, height: 40)
                                .background(WBDesign.Palette.surfaceRaised, in: Circle())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        WBLogoView(compact: true)
                        Spacer()
                        Button(action: showShop) {
                            WBWalletBadge(asset: WBArtwork.coin, fallbackSystemImage: "circle.hexagongrid.fill", value: store.coinBalanceLabel)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)

                    ZStack {
                        if round.won {
                            WBArtworkImage(name: WBArtwork.Result.correctBurst, contentMode: .fit)
                                .frame(width: min(metrics.contentWidth, 390), height: 330)
                        }

                        VStack(spacing: 8) {
                            Text(round.won ? "CORRECT!" : "FULL TIME")
                                .font(WBDesign.Typography.hero(metrics.isCompact ? 40 : 48))
                                .foregroundStyle(round.won ? WBDesign.Palette.green : WBDesign.Palette.orange)
                                .shadow(color: (round.won ? WBDesign.Palette.green : WBDesign.Palette.orange).opacity(0.28), radius: 16)

                            Text(round.won ? "THE PLAYER WAS" : "THE ANSWER WAS")
                                .font(WBDesign.Typography.label(10))
                                .tracking(1.4)
                                .foregroundStyle(WBDesign.Palette.textSecondary)

                            Text(round.seed.name.uppercased())
                                .font(WBDesign.Typography.screenTitle(metrics.isCompact ? 25 : 30))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(WBDesign.Palette.purple.opacity(0.78), in: Capsule())

                            WBPlayerStickerHero(round: round)
                                .frame(maxWidth: metrics.isCompact ? 230 : 260)
                                .padding(.top, 6)
                        }
                    }

                    if round.won {
                        WBRewardStrip(round: round)
                    }

                    if let update = round.masteryUpdate {
                        WBCareerResultCard(update: update)
                    }

                    if round.usedLiveWikipedia {
                        HStack(spacing: 6) {
                            Circle().fill(WBDesign.Palette.green).frame(width: 7, height: 7)
                            Text("Career verified from Wikipedia for this round")
                                .font(WBDesign.Typography.body(10))
                                .foregroundStyle(WBDesign.Palette.textTertiary)
                        }
                    }

                    VStack(spacing: 10) {
                        Button {
                            Task { await store.startNextRound() }
                        } label: {
                            Label("NEXT PLAYER", systemImage: "arrow.right")
                                .font(WBDesign.Typography.label(12))
                                .foregroundStyle(Color(red: 0.05, green: 0.07, blue: 0.15))
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(WBDesign.Palette.green, in: Capsule())
                        }
                        .buttonStyle(.plain)

                        if let share = store.shareText() {
                            ShareLink(item: share) {
                                Label("SHARE RESULT", systemImage: "square.and.arrow.up")
                                    .font(WBDesign.Typography.label(11))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 46)
                                    .background(WBDesign.Palette.blue, in: Capsule())
                            }
                        }

                        Button("BACK TO PLAY") { store.closeRound() }
                            .font(WBDesign.Typography.label(10))
                            .foregroundStyle(WBDesign.Palette.textSecondary)
                            .padding(.vertical, 8)
                    }
                }
                .frame(maxWidth: metrics.contentWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, metrics.horizontalMargin)
                .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 18))
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct WBPlayerStickerHero: View {
    let round: GameStore.RoundState
    @EnvironmentObject private var store: GameStore

    private var frameAsset: String {
        switch round.seed.cardRarity {
        case .common: return "WBStickerStandard"
        case .rare: return "WBStickerSilver"
        case .elite, .icon: return "WBStickerGold"
        case .legend: return "WBStickerSpectrum"
        }
    }

    var body: some View {
        ZStack {
            WBArtworkImage(name: frameAsset, contentMode: .fit)
            VStack(spacing: 6) {
                Spacer(minLength: 20)
                if let playerImage = store.successPlayerImage {
                    Image(decorative: playerImage, scale: 1)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 190)
                        .shadow(color: Color.black.opacity(0.35), radius: 10, y: 6)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 92, weight: .black))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer(minLength: 2)
                Text(round.seed.name.uppercased())
                    .font(WBDesign.Typography.cardTitle(14))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, 20)
                Text("\(round.seed.nationality.uppercased()) · \(round.seed.position.uppercased())")
                    .font(WBDesign.Typography.label(7))
                    .foregroundStyle(WBDesign.Palette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 18)
                Spacer(minLength: 18)
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .accessibilityElement(children: .combine)
    }
}

private struct WBRewardStrip: View {
    let round: GameStore.RoundState

    var body: some View {
        HStack(spacing: 8) {
            reward(icon: "sparkles", value: "+\(round.reward.xp)", label: "XP", tint: WBDesign.Palette.cyan)
            reward(icon: "circle.hexagongrid.fill", value: "+\(round.reward.coins)", label: "COINS", tint: WBDesign.Palette.yellow)
            reward(icon: "rectangle.stack.fill", value: round.masteryUpdate?.isNewPlayer == true ? "NEW" : "✓", label: "STICKER", tint: WBDesign.Palette.green)
        }
    }

    private func reward(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value).font(WBDesign.Typography.number(16))
            Text(label).font(WBDesign.Typography.label(8)).foregroundStyle(WBDesign.Palette.textTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(WBDesign.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(tint.opacity(0.18), lineWidth: 1) }
    }
}

private struct WBCareerResultCard: View {
    let update: MasteryUpdate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WBSectionHeader(title: "Career Progress")
            ForEach(Array(update.collectionDeltas.prefix(3))) { delta in
                HStack {
                    Text("\(delta.icon) \(delta.name)")
                        .font(WBDesign.Typography.body(12))
                    Spacer()
                    Text("\(delta.after) / \(delta.total)")
                        .font(WBDesign.Typography.number(12))
                        .foregroundStyle(WBDesign.Palette.cyan)
                }
            }
            if !update.newAwards.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill").foregroundStyle(WBDesign.Palette.yellow)
                    Text("\(update.newAwards.count) new Career trophy reward\(update.newAwards.count == 1 ? "" : "s")")
                        .font(WBDesign.Typography.body(11))
                }
            }
        }
        .padding(16)
        .background(WBDesign.Palette.surfaceRaised.opacity(0.76), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
    }
}

private struct WBMatchMomentOverlay: View {
    let moment: MatchMoment
    let playerName: String?
    @State private var revealed = false

    private var title: String {
        switch moment.kind {
        case .goal: return "GOAL!"
        case .nearMiss: return "JUST WIDE"
        case .farMiss: return "ROW Z"
        case .hint: return "CLUE UNLOCKED"
        }
    }

    private var tint: Color {
        switch moment.kind {
        case .goal: return WBDesign.Palette.green
        case .nearMiss: return WBDesign.Palette.orange
        case .farMiss: return WBDesign.Palette.red
        case .hint: return WBDesign.Palette.yellow
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(revealed ? 0.72 : 0).ignoresSafeArea()
            if moment.kind == .goal {
                WBArtworkImage(name: WBArtwork.Result.correctBurst, contentMode: .fit)
                    .padding(28)
                    .scaleEffect(revealed ? 1 : 0.45)
            }
            VStack(spacing: 8) {
                Image(systemName: moment.kind == .goal ? "soccerball" : "figure.soccer")
                    .font(.system(size: 66, weight: .black))
                    .foregroundStyle(tint)
                Text(title)
                    .font(WBDesign.Typography.hero(42))
                    .foregroundStyle(.white)
                if moment.kind == .goal, let playerName {
                    Text(playerName)
                        .font(WBDesign.Typography.cardTitle(20))
                        .foregroundStyle(tint)
                }
            }
            .scaleEffect(revealed ? 1 : 0.65)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) { revealed = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)\(playerName.map { ". \($0)" } ?? "")")
    }
}

private struct WBMasteryCelebration: View {
    @EnvironmentObject private var store: GameStore
    let award: MasteryAwardRecord
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()
            VStack(spacing: 14) {
                WBOriginalTrophyView(family: store.collection(for: award.collectionID)?.category ?? .global, tier: award.tier, size: 150)
                Text("TROPHY UNLOCKED")
                    .font(WBDesign.Typography.hero(30))
                    .foregroundStyle(WBDesign.Palette.yellow)
                Text(store.collection(for: award.collectionID)?.name ?? "Career Trophy")
                    .font(WBDesign.Typography.cardTitle(19))
                Text(award.tier.label.uppercased())
                    .font(WBDesign.Typography.label(11))
                    .foregroundStyle(WBDesign.Palette.textSecondary)
                Button("VIEW TROPHY", action: action)
                    .font(WBDesign.Typography.label(11))
                    .foregroundStyle(Color(red: 0.05, green: 0.07, blue: 0.15))
                    .padding(.horizontal, 24)
                    .frame(minHeight: 46)
                    .background(WBDesign.Palette.yellow, in: Capsule())
            }
            .padding(28)
            .background(WBDesign.Palette.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(WBDesign.Palette.yellow.opacity(0.28), lineWidth: 1) }
            .padding(28)
        }
    }
}

struct WBTrophyDetailSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let award: MasteryAwardRecord

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                let collection = store.collection(for: award.collectionID)
                WBOriginalTrophyView(family: collection?.category ?? .global, tier: award.tier, size: 180)
                Text(collection?.name ?? "Career Trophy")
                    .font(WBDesign.Typography.screenTitle(26))
                    .multilineTextAlignment(.center)
                Text(award.tier.label.uppercased())
                    .font(WBDesign.Typography.label(11))
                    .foregroundStyle(WBDesign.Palette.yellow)
                Text("Earned \(award.earnedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(WBDesign.Typography.body(12))
                    .foregroundStyle(WBDesign.Palette.textSecondary)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WBDesign.Palette.background.ignoresSafeArea())
            .navigationTitle("Trophy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
