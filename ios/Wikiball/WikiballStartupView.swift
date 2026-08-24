import SwiftUI

/// Lightweight startup gate that keeps the native app responsive while presenting the
/// branded loading experience. Only local, deterministic work gates entry; StoreKit refresh
/// continues independently so network/service delays cannot strand the player at launch.
struct WBStartupGate<Content: View>: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var purchases: PurchaseService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: Double = 0.06
    @State private var status = "Preparing Wikiball…"
    @State private var isReady = false
    @State private var started = false

    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            content()
                .opacity(isReady ? 1 : 0)
                .allowsHitTesting(isReady)

            if !isReady {
                WBStartupLoadingView(progress: progress, status: status)
                    .transition(.opacity)
            }
        }
        .task {
            guard !started else { return }
            started = true
            await bootstrap()
        }
    }

    @MainActor
    private func bootstrap() async {
        let clock = ContinuousClock()
        let startedAt = clock.now

        status = "Restoring your profile…"
        withAnimation(.easeOut(duration: 0.2)) { progress = 0.25 }
        _ = store.profile.displayName
        await Task.yield()

        status = "Loading football database…"
        withAnimation(.easeOut(duration: 0.2)) { progress = 0.52 }
        _ = SeedData.players.count
        _ = SeedData.leagues.count
        await Task.yield()

        status = "Preparing your collection…"
        withAnimation(.easeOut(duration: 0.2)) { progress = 0.76 }
        _ = store.masteryProgress.count
        _ = store.masteredPlayerCount
        await Task.yield()

        status = "Preparing your next match…"
        withAnimation(.easeOut(duration: 0.2)) { progress = 0.94 }

        // Non-critical StoreKit preparation continues independently and never gates launch.
        Task { await purchases.prepare() }

        let minimumVisible = Duration.milliseconds(520)
        let elapsed = startedAt.duration(to: clock.now)
        if elapsed < minimumVisible {
            try? await Task.sleep(for: minimumVisible - elapsed)
        }

        withAnimation(.easeOut(duration: 0.18)) { progress = 1 }
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 70 : 160))
        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.32)) {
            isReady = true
        }
    }
}

struct WBStartupLoadingView: View {
    let progress: Double
    let status: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lightSweep = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if WBAssetAvailability.has("WBLoadingStadiumBackground") {
                    WBArtworkImage(name: "WBLoadingStadiumBackground", contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.02, green: 0.04, blue: 0.12), Color(red: 0.03, green: 0.08, blue: 0.19), Color.black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }

                if !reduceMotion {
                    LinearGradient(
                        colors: [Color.clear, WBDesign.Palette.cyan.opacity(0.12), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .rotationEffect(.degrees(-16))
                    .offset(x: lightSweep ? proxy.size.width * 0.72 : -proxy.size.width * 0.72)
                    .blendMode(.screen)
                    .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    Spacer(minLength: proxy.size.height * 0.20)

                    VStack(spacing: 16) {
                        WBLogoView(compact: false)
                            .scaleEffect(1.18)

                        WBRankCrestView(tierName: "Legend", size: 72)

                        Text("ROAD TO LEGEND")
                            .font(WBDesign.Typography.label(11))
                            .tracking(1.6)
                            .foregroundStyle(.white.opacity(0.70))
                    }

                    Spacer()

                    VStack(spacing: 13) {
                        GeometryReader { bar in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.12))
                                Capsule()
                                    .fill(LinearGradient(colors: [WBDesign.Palette.blue, WBDesign.Palette.cyan], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(10, bar.size.width * min(max(progress, 0), 1)))
                            }
                        }
                        .frame(height: 12)

                        HStack {
                            Text(status)
                                .font(WBDesign.Typography.body(13))
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Spacer()
                            Text("\(Int((progress * 100).rounded()))%")
                                .font(WBDesign.Typography.number(12))
                                .foregroundStyle(WBDesign.Palette.cyan)
                                .monospacedDigit()
                        }
                    }
                    .frame(maxWidth: min(proxy.size.width - 48, 430))
                    .padding(.bottom, max(38, proxy.safeAreaInsets.bottom + 24))
                }
                .padding(.horizontal, 24)
            }
        }
        .background(WBDesign.Palette.background)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Wikiball loading. \(status). \(Int((progress * 100).rounded())) percent.")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
                lightSweep = true
            }
        }
    }
}
