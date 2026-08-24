import SwiftUI

struct WBAvatarPreset: Identifiable, Hashable, Codable {
    let id: String
    let assetName: String
    let displayName: String
    let access: WBAvatarAccess
}

enum WBAvatarAccess: String, Codable {
    case free
    case seasonTicket
}

enum WBAvatarCatalog {
    static let defaultPresetID = "captain-blue"
    static let storageKey = "wikiball.avatar.preset.v2"
    static let backgroundKey = "wikiball.avatar.background.v2"
    static let frameKey = "wikiball.avatar.frame.v2"

    static let presets: [WBAvatarPreset] = [
        .init(id: "captain-blue", assetName: "WBAvatar01", displayName: "Captain", access: .free),
        .init(id: "curl-green", assetName: "WBAvatar02", displayName: "Playmaker", access: .free),
        .init(id: "braid-purple", assetName: "WBAvatar03", displayName: "Maestro", access: .free),
        .init(id: "crop-red", assetName: "WBAvatar04", displayName: "Finisher", access: .free),
        .init(id: "sweep-gold", assetName: "WBAvatar05", displayName: "Creator", access: .free),
        .init(id: "buzz-cyan", assetName: "WBAvatar06", displayName: "Engine", access: .free),
        .init(id: "long-indigo", assetName: "WBAvatar07", displayName: "Artist", access: .seasonTicket),
        .init(id: "fade-orange", assetName: "WBAvatar08", displayName: "Striker", access: .seasonTicket),
        .init(id: "wave-blue", assetName: "WBAvatar09", displayName: "Winger", access: .seasonTicket),
        .init(id: "short-green", assetName: "WBAvatar10", displayName: "Anchor", access: .seasonTicket),
        .init(id: "curly-gold", assetName: "WBAvatar11", displayName: "Legend", access: .seasonTicket),
        .init(id: "shaved-purple", assetName: "WBAvatar12", displayName: "Boss", access: .seasonTicket)
    ]

    static func preset(id: String) -> WBAvatarPreset {
        presets.first(where: { $0.id == id }) ?? presets[0]
    }

    static let backgrounds: [WBAvatarBackground] = [
        .init(id: "spectrum", name: "Spectrum", colors: [WBDesign.Palette.purple, WBDesign.Palette.blue, WBDesign.Palette.green], premium: false),
        .init(id: "navy", name: "Classic Navy", colors: [WBDesign.Palette.surfaceRaised, WBDesign.Palette.blue.opacity(0.65)], premium: false),
        .init(id: "pitch", name: "Pitch", colors: [Color(red: 0.02, green: 0.23, blue: 0.14), WBDesign.Palette.green.opacity(0.72)], premium: false),
        .init(id: "violet", name: "Ultra Violet", colors: [Color(red: 0.22, green: 0.06, blue: 0.38), WBDesign.Palette.purple], premium: true),
        .init(id: "midnightGold", name: "Midnight Gold", colors: [Color(red: 0.035, green: 0.035, blue: 0.08), Color(red: 0.48, green: 0.32, blue: 0.03)], premium: true)
    ]

    static func background(id: String) -> WBAvatarBackground {
        backgrounds.first(where: { $0.id == id }) ?? backgrounds[0]
    }
}

struct WBAvatarBackground: Identifiable, Hashable {
    let id: String
    let name: String
    let colors: [Color]
    let premium: Bool

    static func == (lhs: WBAvatarBackground, rhs: WBAvatarBackground) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct WBIllustratedAvatarView: View {
    let presetID: String
    let backgroundID: String
    var size: CGFloat
    var showFrame = true

    private var preset: WBAvatarPreset { WBAvatarCatalog.preset(id: presetID) }
    private var background: WBAvatarBackground { WBAvatarCatalog.background(id: backgroundID) }

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: background.colors, startPoint: .topLeading, endPoint: .bottomTrailing))

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.18), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.75
                    )
                )

            if WBAssetAvailability.has(preset.assetName) {
                WBArtworkImage(name: preset.assetName, contentMode: .fit)
                    .padding(size * 0.035)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(size * 0.18)
            }

            if showFrame {
                if WBAssetAvailability.has(WBArtwork.avatarFrame) {
                    WBArtworkImage(name: WBArtwork.avatarFrame, contentMode: .fit)
                } else {
                    Circle().stroke(
                        LinearGradient(colors: [WBDesign.Palette.green, WBDesign.Palette.cyan, Color.white.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: max(2, size * 0.045)
                    )
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: WBDesign.Palette.blue.opacity(0.32), radius: size * 0.12, y: size * 0.055)
        .accessibilityLabel("Wikiball avatar, \(preset.displayName)")
    }
}
