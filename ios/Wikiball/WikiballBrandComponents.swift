import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum WBMainTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case play = "Play"
    case collection = "Collection"
    case profile = "Profile"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .play: return "play.fill"
        case .collection: return "rectangle.stack.fill"
        case .profile: return "person.fill"
        }
    }
}

struct WBLogoView: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            if WBAssetAvailability.has(WBArtwork.logo) {
                WBArtworkImage(name: WBArtwork.logo, contentMode: .fit)
                    .frame(width: compact ? 30 : 42, height: compact ? 30 : 42)
            } else {
                Image("BrandMark")
                    .resizable().scaledToFit()
                    .frame(width: compact ? 30 : 42, height: compact ? 30 : 42)
                    .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 11, style: .continuous))
            }

            Text("WIKIBALL")
                .font(WBDesign.Typography.cardTitle(compact ? 18 : 24))
                .tracking(compact ? 0.5 : 0.8)
                .foregroundStyle(WBDesign.Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Wikiball")
    }
}

struct WBIconAsset: View {
    let asset: String
    let fallbackSystemImage: String
    var size: CGFloat = 24
    var tint: Color = .white

    var body: some View {
        Group {
            if WBAssetAvailability.has(asset) {
                WBArtworkImage(name: asset, contentMode: .fit)
            } else {
                Image(systemName: fallbackSystemImage)
                    .resizable().scaledToFit()
                    .foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct WBWalletBadge: View {
    let asset: String
    let fallbackSystemImage: String
    let value: String
    var accent: Color = WBDesign.Palette.yellow

    var body: some View {
        HStack(spacing: 6) {
            WBIconAsset(asset: asset, fallbackSystemImage: fallbackSystemImage, size: 19, tint: accent)
            Text(value)
                .font(WBDesign.Typography.number(14))
                .monospacedDigit()
                .foregroundStyle(WBDesign.Palette.textPrimary)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 34)
        .background(WBDesign.Palette.surfaceRaised.opacity(0.96), in: Capsule())
        .overlay { Capsule().stroke(accent.opacity(0.22), lineWidth: 1) }
    }
}

struct WBRankCrestView: View {
    let tierName: String
    var size: CGFloat = 38

    private var accent: Color {
        switch tierName.lowercased() {
        case "rookie": return WBDesign.Palette.green
        case "prospect": return WBDesign.Palette.cyan
        case "pro": return WBDesign.Palette.blue
        case "star": return WBDesign.Palette.yellow
        case "world class": return WBDesign.Palette.purple
        case "legend": return WBDesign.Palette.orange
        default: return WBDesign.Palette.blue
        }
    }

    private var rankAsset: String {
        switch tierName.lowercased() {
        case "rookie": return "WBRankRookie"
        case "prospect": return "WBRankProspect"
        case "pro": return "WBRankPro"
        case "star": return "WBRankStar"
        case "world class": return "WBRankWorldClass"
        case "legend": return "WBRankLegend"
        default: return WBArtwork.xpCrest
        }
    }

    var body: some View {
        Group {
            if WBAssetAvailability.has(rankAsset) {
                WBArtworkImage(name: rankAsset, contentMode: .fit)
            } else if WBAssetAvailability.has(WBArtwork.xpCrest) {
                WBArtworkImage(name: WBArtwork.xpCrest, contentMode: .fit)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                        .fill(LinearGradient(colors: [accent, accent.opacity(0.45)], startPoint: .top, endPoint: .bottom))
                        .rotationEffect(.degrees(45))
                        .frame(width: size * 0.72, height: size * 0.72)
                    Image(systemName: tierName.lowercased() == "legend" ? "crown.fill" : "star.fill")
                        .font(.system(size: size * 0.32, weight: .black))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(tierName) rank")
    }
}

struct WBMainHUD: View {
    @EnvironmentObject private var store: GameStore
    let onCoins: () -> Void
    let onAvatar: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            regular
            compact
        }
    }

    private var regular: some View {
        HStack(spacing: 12) {
            Button(action: onAvatar) {
                ZStack(alignment: .bottomTrailing) {
                    ProfileAvatarView(profile: store.profile, size: 56)
                    Text("\(levelNumber)")
                        .font(WBDesign.Typography.label(10))
                        .foregroundStyle(.white)
                        .frame(minWidth: 24, minHeight: 20)
                        .background(WBDesign.Palette.green, in: Capsule())
                        .overlay { Capsule().stroke(Color.white.opacity(0.45), lineWidth: 1) }
                        .offset(x: 3, y: 3)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open profile")

            VStack(alignment: .leading, spacing: 5) {
                WBLogoView(compact: true)
                HStack(spacing: 8) {
                    Text("ROAD TO \(store.nextTier?.name.uppercased() ?? "LEGEND")")
                        .font(WBDesign.Typography.label(9))
                        .tracking(0.7)
                        .foregroundStyle(WBDesign.Palette.textSecondary)
                    Spacer(minLength: 0)
                    Text("\(store.profile.xp) XP")
                        .font(WBDesign.Typography.label(9))
                        .foregroundStyle(WBDesign.Palette.textSecondary)
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(LinearGradient(colors: [WBDesign.Palette.green, WBDesign.Palette.cyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, proxy.size.width * store.tierProgress))
                    }
                }
                .frame(height: 7)
            }
            .frame(maxWidth: .infinity)

            WBRankCrestView(tierName: store.currentTier.name, size: 42)

            VStack(alignment: .trailing, spacing: 6) {
                Button(action: onCoins) {
                    WBWalletBadge(asset: WBArtwork.coin, fallbackSystemImage: "circle.hexagongrid.fill", value: store.coinBalanceLabel, accent: WBDesign.Palette.yellow)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open shop. \(store.coinBalanceLabel) Wikicoins")

                HStack(spacing: 5) {
                    WBIconAsset(asset: WBArtwork.streak, fallbackSystemImage: "flame.fill", size: 15, tint: WBDesign.Palette.orange)
                    Text("\(store.profile.streak)")
                        .font(WBDesign.Typography.number(13))
                    Text("DAY STREAK")
                        .font(WBDesign.Typography.label(8))
                        .foregroundStyle(WBDesign.Palette.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(WBDesign.Palette.surface.opacity(0.90), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
    }

    private var compact: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: onAvatar) { ProfileAvatarView(profile: store.profile, size: 44) }
                    .buttonStyle(.plain)
                WBLogoView(compact: true)
                Spacer()
                Button(action: onCoins) {
                    WBWalletBadge(asset: WBArtwork.coin, fallbackSystemImage: "circle.hexagongrid.fill", value: store.coinBalanceLabel)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                WBRankCrestView(tierName: store.currentTier.name, size: 30)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(WBDesign.Palette.green).frame(width: max(8, proxy.size.width * store.tierProgress))
                    }
                }
                .frame(height: 7)
                HStack(spacing: 4) {
                    WBIconAsset(asset: WBArtwork.streak, fallbackSystemImage: "flame.fill", size: 14, tint: WBDesign.Palette.orange)
                    Text("\(store.profile.streak)").font(WBDesign.Typography.number(12))
                }
            }
        }
        .padding(12)
        .background(WBDesign.Palette.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
    }

    private var levelNumber: Int {
        max(1, Int(store.profile.xp / 150) + 1)
    }
}

struct WBBottomTabBar: View {
    @Binding var selectedTab: WBMainTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(WBMainTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .black))
                        Text(tab.rawValue.uppercased())
                            .font(WBDesign.Typography.label(9))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedTab == tab ? .white : WBDesign.Palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        selectedTab == tab ? WBDesign.Palette.blue : Color.clear,
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue)
                .accessibilityValue(selectedTab == tab ? "Selected" : "")
            }
        }
        .padding(8)
        .background(WBDesign.Palette.surface.opacity(0.98), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(WBDesign.Palette.border, lineWidth: 1) }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}

struct WBSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(WBDesign.Typography.cardTitle(16))
                .tracking(0.8)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle.uppercased(), action: action)
                    .font(WBDesign.Typography.label(10))
                    .foregroundStyle(WBDesign.Palette.cyan)
            }
        }
    }
}

struct WBSmallStatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title.uppercased())
            .font(WBDesign.Typography.label(9))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(tint.opacity(0.9), in: Capsule())
    }
}

enum WBAssetAvailability {
    static func has(_ name: String) -> Bool {
        #if canImport(UIKit)
        UIImage(named: name) != nil
        #else
        true
        #endif
    }
}
