import SwiftUI

struct WBOriginalTrophyView: View {
    let family: CollectionCategory
    let tier: MasteryTier?
    var size: CGFloat = 120

    private var assetName: String {
        switch family {
        case .league: return "WBTrophyLeague"
        case .country: return "WBTrophyNational"
        case .region: return "WBTrophyContinental"
        case .special, .global: return "WBTrophyGlobal"
        }
    }

    private var tierTint: Color {
        switch tier {
        case .bronze: return Color(red: 0.74, green: 0.42, blue: 0.24)
        case .silver: return Color(red: 0.76, green: 0.83, blue: 0.92)
        case .gold: return WBDesign.Palette.yellow
        case .master: return WBDesign.Palette.cyan
        case nil: return Color.white.opacity(0.28)
        }
    }

    var body: some View {
        ZStack {
            if WBAssetAvailability.has(assetName) {
                WBArtworkImage(name: assetName, contentMode: .fit)
                    .saturation(tier == nil ? 0 : 1)
                    .opacity(tier == nil ? 0.28 : 1)
            } else {
                Image(systemName: tier == nil ? "trophy" : "trophy.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(tierTint)
                    .padding(size * 0.18)
            }

            if tier == .master {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [WBDesign.Palette.purple, WBDesign.Palette.pink, WBDesign.Palette.orange, WBDesign.Palette.yellow, WBDesign.Palette.green, WBDesign.Palette.cyan, WBDesign.Palette.purple],
                            center: .center
                        ),
                        lineWidth: max(2, size * 0.028)
                    )
                    .padding(size * 0.025)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: tierTint.opacity(tier == nil ? 0 : 0.30), radius: size * 0.10, y: size * 0.045)
        .accessibilityLabel("\(tier?.label ?? "Locked") \(family.label) trophy")
    }
}

struct WBTrophyProgressCard: View {
    let progress: MasteryProgress

    var body: some View {
        VStack(spacing: 9) {
            WBOriginalTrophyView(family: progress.collection.category, tier: progress.historicalTier, size: 82)

            Text(progress.collection.name)
                .font(WBDesign.Typography.cardTitle(12))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(progress.historicalTier?.label.uppercased() ?? "LOCKED")
                .font(WBDesign.Typography.label(8))
                .foregroundStyle(progress.historicalTier == nil ? WBDesign.Palette.textTertiary : WBDesign.Palette.yellow)

            ProgressView(value: progress.fraction)
                .tint(progress.historicalTier == .master ? WBDesign.Palette.cyan : WBDesign.Palette.green)

            Text("\(progress.percent)%")
                .font(WBDesign.Typography.number(11))
                .foregroundStyle(WBDesign.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(WBDesign.Palette.surfaceRaised.opacity(0.80), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
    }
}

struct WBTrophyCabinetView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    private var earnedCount: Int { store.profile.mastery.earnedAwards.count }
    private var totalMilestones: Int {
        store.masteryEngine.collections.reduce(0) { $0 + $1.milestones.count }
    }
    private var completion: Int {
        guard totalMilestones > 0 else { return 0 }
        return Int((Double(earnedCount) / Double(totalMilestones) * 100).rounded())
    }

    var body: some View {
        NavigationStack {
            WBAppBackgroundForCabinet()
                .overlay {
                    ScrollView {
                        VStack(spacing: 18) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(earnedCount) / \(totalMilestones)")
                                        .font(WBDesign.Typography.hero(31))
                                        .foregroundStyle(WBDesign.Palette.yellow)
                                    Text("REWARDS EARNED")
                                        .font(WBDesign.Typography.label(9))
                                        .foregroundStyle(WBDesign.Palette.textTertiary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(completion)%")
                                        .font(WBDesign.Typography.hero(31))
                                        .foregroundStyle(WBDesign.Palette.cyan)
                                    Text("CABINET COMPLETE")
                                        .font(WBDesign.Typography.label(9))
                                        .foregroundStyle(WBDesign.Palette.textTertiary)
                                }
                            }
                            .padding(17)
                            .background(WBDesign.Palette.surfaceRaised.opacity(0.80), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                            cabinetSection("League Trophies", category: .league)
                            cabinetSection("National Trophies", category: .country)
                            cabinetSection("Continental Trophies", category: .region)
                            cabinetSection("Global Trophies", categories: [.special, .global])
                        }
                        .padding(18)
                    }
                }
                .navigationTitle("Trophy Cabinet")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func cabinetSection(_ title: String, category: CollectionCategory) -> some View {
        cabinetSection(title, categories: [category])
    }

    @ViewBuilder
    private func cabinetSection(_ title: String, categories: Set<CollectionCategory>) -> some View {
        let items = store.masteryProgress.filter { categories.contains($0.collection.category) }
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 11) {
                WBSectionHeader(title: title)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(items) { progress in
                        WBTrophyProgressCard(progress: progress)
                    }
                }
            }
        }
    }
}

private struct WBAppBackgroundForCabinet: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.04, blue: 0.11), Color(red: 0.07, green: 0.05, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            RadialGradient(colors: [WBDesign.Palette.purple.opacity(0.13), Color.clear], center: .topTrailing, startRadius: 0, endRadius: 420).ignoresSafeArea()
        }
    }
}
