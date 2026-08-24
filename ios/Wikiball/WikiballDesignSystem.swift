import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Canonical visual tokens for the native Wikiball app.
///
/// The design system deliberately separates branded artwork from layout/behaviour:
/// SwiftUI owns responsive structure and interaction, while complex visual treatments
/// should come from reviewed assets in Assets.xcassets.
enum WBDesign {
    enum Palette {
        static let background = Color(red: 0.035, green: 0.039, blue: 0.105)
        static let surface = Color(red: 0.063, green: 0.071, blue: 0.176)
        static let surfaceRaised = Color(red: 0.094, green: 0.106, blue: 0.235)
        static let blue = Color(red: 0.110, green: 0.420, blue: 0.930)
        static let cyan = Color(red: 0.100, green: 0.690, blue: 0.980)
        static let green = Color(red: 0.175, green: 0.760, blue: 0.390)
        static let yellow = Color(red: 0.980, green: 0.820, blue: 0.180)
        static let orange = Color(red: 0.960, green: 0.430, blue: 0.130)
        static let red = Color(red: 0.890, green: 0.210, blue: 0.220)
        static let purple = Color(red: 0.475, green: 0.210, blue: 0.790)
        static let pink = Color(red: 0.790, green: 0.210, blue: 0.565)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.70)
        static let textTertiary = Color.white.opacity(0.48)
        static let border = Color.white.opacity(0.12)
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 18
        static let card: CGFloat = 24
        static let hero: CGFloat = 28
        static let pill: CGFloat = 999
    }

    enum Shadow {
        static let cardColor = Color.black.opacity(0.30)
        static let cardRadius: CGFloat = 18
        static let cardY: CGFloat = 8
        static let glowRadius: CGFloat = 16
    }

    enum Typography {
        /// Temporary system-font mapping until the licensed Wikiball display font is bundled.
        /// Screens should use these roles instead of choosing ad-hoc font sizes.
        static func hero(_ size: CGFloat = 36) -> Font {
            .system(size: size, weight: .black, design: .rounded)
        }

        static func screenTitle(_ size: CGFloat = 28) -> Font {
            .system(size: size, weight: .black, design: .rounded)
        }

        static func cardTitle(_ size: CGFloat = 18) -> Font {
            .system(size: size, weight: .black, design: .rounded)
        }

        static func body(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }

        static func label(_ size: CGFloat = 12) -> Font {
            .system(size: size, weight: .black, design: .rounded)
        }

        static func number(_ size: CGFloat = 20) -> Font {
            .system(size: size, weight: .black, design: .rounded)
        }
    }

    enum Layout {
        /// Used only as an art-direction baseline. Entire screens should not be blindly scaled.
        static let referenceWidth: CGFloat = 430
        static let compactBreakpoint: CGFloat = 375
        static let regularHorizontalMargin: CGFloat = 16
        static let compactHorizontalMargin: CGFloat = 12
        static let maxReadableWidth: CGFloat = 520
        static let minimumTapTarget: CGFloat = 44
    }
}

/// Centralised asset names. Complex branded artwork should be exported from the approved
/// design source and referenced here rather than redrawn independently per screen.
enum WBArtwork {
    static let logo = "WBLogoFull"
    static let coin = "WBCoin"
    static let streak = "WBStreakFlame"
    static let xpCrest = "WBXPCrest"
    static let avatarFrame = "WBAvatarFrame"

    enum Home {
        static let playHeroBackground = "WBHomePlayHeroBackground"
        static let playHeroFootball = "WBHomePlayHeroFootball"
        static let dailyBackground = "WBHomeDailyBackground"
        static let careerBackground = "WBHomeCareerBackground"
    }

    enum Play {
        static let quickPlayBackground = "WBPlayQuickBackground"
        static let dailyBackground = "WBPlayDailyBackground"
        static let versusBackground = "WBPlayVersusBackground"
        static let customBackground = "WBPlayCustomBackground"
    }

    enum Result {
        static let correctBurst = "WBResultCorrectBurst"
    }

    enum Versus {
        static let shield = "WBVersusShield"
    }

    enum Shop {
        static let seasonTicketBackground = "WBShopSeasonTicketBackground"
    }
}

/// Metrics derived from available width. Decorative panels preserve their composition,
/// while functional content remains genuinely adaptive and scrollable.
struct WBResponsiveMetrics {
    let availableWidth: CGFloat

    var isCompact: Bool { availableWidth < WBDesign.Layout.compactBreakpoint }
    var horizontalMargin: CGFloat {
        isCompact ? WBDesign.Layout.compactHorizontalMargin : WBDesign.Layout.regularHorizontalMargin
    }
    var contentWidth: CGFloat {
        min(max(0, availableWidth - (horizontalMargin * 2)), WBDesign.Layout.maxReadableWidth)
    }
    var artScale: CGFloat {
        let raw = contentWidth / (WBDesign.Layout.referenceWidth - (WBDesign.Layout.regularHorizontalMargin * 2))
        return min(max(raw, 0.88), 1.08)
    }
    var majorSectionSpacing: CGFloat { isCompact ? 14 : 18 }
}

/// A safe replacement for hand-tuned per-screen width calculations.
/// It centres the primary phone layout on wider devices and leaves vertical adaptation to the screen.
struct WBResponsiveContainer<Content: View>: View {
    @ViewBuilder var content: (WBResponsiveMetrics) -> Content

    var body: some View {
        GeometryReader { proxy in
            let metrics = WBResponsiveMetrics(availableWidth: proxy.size.width)
            ScrollView {
                content(metrics)
                    .frame(maxWidth: metrics.contentWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, metrics.horizontalMargin)
            }
            .scrollIndicators(.hidden)
        }
    }
}

/// Loads a reviewed artwork asset if present. Missing assets degrade to `Color.clear`
/// so new code can land before the final binary art pack without crashing.
struct WBArtworkImage: View {
    let name: String
    var contentMode: ContentMode = .fill

    var body: some View {
        #if canImport(UIKit)
        if let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .accessibilityHidden(true)
        } else {
            Color.clear.accessibilityHidden(true)
        }
        #else
        Image(name)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .accessibilityHidden(true)
        #endif
    }
}

/// Asset-backed card shell for branded panels.
/// Use artwork for texture/illustration and SwiftUI for live labels, progress and controls.
struct WBArtCard<Overlay: View>: View {
    let artworkName: String
    let cornerRadius: CGFloat
    let aspectRatio: CGFloat?
    let fallbackColors: [Color]
    @ViewBuilder let overlay: () -> Overlay

    init(
        artworkName: String,
        cornerRadius: CGFloat = WBDesign.Radius.card,
        aspectRatio: CGFloat? = nil,
        fallbackColors: [Color] = [WBDesign.Palette.surfaceRaised, WBDesign.Palette.surface],
        @ViewBuilder overlay: @escaping () -> Overlay
    ) {
        self.artworkName = artworkName
        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.fallbackColors = fallbackColors
        self.overlay = overlay
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: fallbackColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            WBArtworkImage(name: artworkName, contentMode: .fill)

            overlay()
        }
        .ifLet(aspectRatio) { view, ratio in
            view.aspectRatio(ratio, contentMode: .fit)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(WBDesign.Palette.border, lineWidth: 1)
        }
        .shadow(
            color: WBDesign.Shadow.cardColor,
            radius: WBDesign.Shadow.cardRadius,
            y: WBDesign.Shadow.cardY
        )
    }
}

/// Standard primary game button. The label remains live/accessibility-safe while artwork
/// and colour treatments stay consistent across screens.
struct WBPrimaryButton: View {
    let title: String
    var tint: Color = WBDesign.Palette.yellow
    var foreground: Color = Color(red: 0.06, green: 0.07, blue: 0.15)
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(WBDesign.Typography.label(14))
                .tracking(0.6)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(minHeight: WBDesign.Layout.minimumTapTarget)
                .padding(.horizontal, WBDesign.Spacing.md)
                .background(tint, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

private extension View {
    @ViewBuilder
    func ifLet<Value, Transformed: View>(_ value: Value?, transform: (Self, Value) -> Transformed) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}
