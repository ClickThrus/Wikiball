import SwiftUI

enum ProfileAvatarPalette {
    static let ids = ["purple", "navy", "blue", "red", "orange", "green"]

    static func color(for id: String) -> Color {
        switch id {
        case "navy": return Color(red: 0.08, green: 0.14, blue: 0.28)
        case "blue": return Color(red: 0.08, green: 0.42, blue: 0.78)
        case "red": return Color(red: 0.72, green: 0.10, blue: 0.18)
        case "orange": return Color(red: 0.92, green: 0.38, blue: 0.08)
        case "green": return Color(red: 0.06, green: 0.48, blue: 0.31)
        default: return Color(red: 0.40, green: 0.18, blue: 0.68)
        }
    }
}

/// Canonical profile avatar used throughout Wikiball.
///
/// Legacy emoji/initial fields remain in the initializer for source compatibility with
/// existing profile code, but the production renderer now uses a reviewed illustrated
/// portrait preset from the asset catalogue. The preset/background are persisted separately
/// so older PlayerProfile payloads migrate without destructive schema changes.
struct ProfileAvatarView: View {
    let displayName: String
    let legacyEmoji: String
    let legacyColorID: String
    let legacyUsesInitials: Bool
    let size: CGFloat

    @AppStorage(WBAvatarCatalog.storageKey) private var presetID = WBAvatarCatalog.defaultPresetID
    @AppStorage(WBAvatarCatalog.backgroundKey) private var backgroundID = "spectrum"

    init(profile: PlayerProfile, size: CGFloat) {
        displayName = profile.displayName
        legacyEmoji = profile.avatarEmoji
        legacyColorID = profile.avatarColor
        legacyUsesInitials = profile.avatarUsesInitials
        self.size = size
    }

    init(displayName: String, emoji: String, colorID: String, usesInitials: Bool, size: CGFloat) {
        self.displayName = displayName
        legacyEmoji = emoji
        legacyColorID = colorID
        legacyUsesInitials = usesInitials
        self.size = size
    }

    var body: some View {
        WBIllustratedAvatarView(
            presetID: presetID,
            backgroundID: backgroundID,
            size: size,
            showFrame: true
        )
        .accessibilityLabel("\(displayName.nilIfBlank ?? "Player") avatar")
    }
}
