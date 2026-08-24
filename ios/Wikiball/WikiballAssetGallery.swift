import SwiftUI

#if DEBUG
/// Debug-only visual QA surface for spotting alignment drift, missing SVGs and inconsistent
/// artwork before comparing full-screen simulator captures with the approved references.
struct WBAssetGalleryView: View {
    private let shared = [
        "WBLogoFull", "WBCoin", "WBStreakFlame", "WBXPCrest", "WBAvatarFrame"
    ]

    private let ranks = [
        "WBRankRookie", "WBRankProspect", "WBRankPro", "WBRankStar", "WBRankWorldClass", "WBRankLegend"
    ]

    private let avatars = (1...12).map { String(format: "WBAvatar%02d", $0) }

    private let stickers = [
        "WBStickerStandard", "WBStickerBronze", "WBStickerSilver", "WBStickerGold", "WBStickerSpectrum", "WBStickerMissing"
    ]

    private let trophies = [
        "WBTrophyLeague", "WBTrophyNational", "WBTrophyContinental", "WBTrophyGlobal"
    ]

    private let surfaces = [
        "WBHomePlayHeroBackground", "WBHomePlayHeroFootball", "WBHomeDailyBackground", "WBHomeCareerBackground",
        "WBPlayQuickBackground", "WBPlayDailyBackground", "WBPlayVersusBackground", "WBPlayCustomBackground",
        "WBShopSeasonTicketBackground", "WBLoadingStadiumBackground", "WBResultCorrectBurst", "WBVersusShield"
    ]

    private let coinPacks = [
        "WBShopCoinPackSmall", "WBShopCoinPackMedium", "WBShopCoinPackLarge"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    gallerySection("Shared", assets: shared, ratio: 1)
                    gallerySection("Rank Crests", assets: ranks, ratio: 1)
                    gallerySection("Avatars", assets: avatars, ratio: 1)
                    gallerySection("Sticker Frames", assets: stickers, ratio: 0.72)
                    gallerySection("Trophies", assets: trophies, ratio: 0.84)
                    gallerySection("Coin Packs", assets: coinPacks, ratio: 1.15)
                    gallerySection("Surfaces", assets: surfaces, ratio: 1.65)
                }
                .padding(16)
            }
            .background(WBDesign.Palette.background.ignoresSafeArea())
            .navigationTitle("Wikiball Art QA")
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func gallerySection(_ title: String, assets: [String], ratio: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            WBSectionHeader(title: title)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                ForEach(assets, id: \.self) { asset in
                    VStack(spacing: 7) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(WBDesign.Palette.surfaceRaised)
                            if WBAssetAvailability.has(asset) {
                                WBArtworkImage(name: asset, contentMode: .fit)
                                    .padding(7)
                            } else {
                                VStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(WBDesign.Palette.orange)
                                    Text("MISSING")
                                        .font(WBDesign.Typography.label(8))
                                }
                            }
                        }
                        .aspectRatio(ratio, contentMode: .fit)
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(WBDesign.Palette.border, lineWidth: 1)
                        }

                        Text(asset)
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundStyle(WBDesign.Palette.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
        }
    }
}

#Preview("Wikiball Art QA") {
    WBAssetGalleryView()
}
#endif
