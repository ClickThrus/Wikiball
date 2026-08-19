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

struct ProfileAvatarView: View {
    let displayName: String
    let emoji: String
    let colorID: String
    let usesInitials: Bool
    let size: CGFloat

    init(profile: PlayerProfile, size: CGFloat) {
        displayName = profile.displayName
        emoji = profile.avatarEmoji
        colorID = profile.avatarColor
        usesInitials = profile.avatarUsesInitials
        self.size = size
    }

    init(displayName: String, emoji: String, colorID: String, usesInitials: Bool, size: CGFloat) {
        self.displayName = displayName
        self.emoji = emoji
        self.colorID = colorID
        self.usesInitials = usesInitials
        self.size = size
    }

    private var initials: String {
        let words = displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace })
        if words.count > 1 {
            return words.prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
        }
        return words.first.map { String($0.prefix(2)).uppercased() } ?? "P"
    }

    private var visibleBadge: String {
        if usesInitials { return initials }
        let trimmed = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "⚽️" : String(trimmed.prefix(1))
    }

    var body: some View {
        Text(visibleBadge)
            .font(usesInitials ? .system(size: size * 0.34, weight: .black, design: .rounded) : .system(size: size * 0.48))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [ProfileAvatarPalette.color(for: colorID), ProfileAvatarPalette.color(for: colorID).opacity(0.68)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Circle()
            )
            .overlay { Circle().stroke(.white.opacity(0.22), lineWidth: max(1, size * 0.025)) }
            .shadow(color: ProfileAvatarPalette.color(for: colorID).opacity(0.35), radius: size * 0.12, y: size * 0.06)
            .accessibilityLabel("\(displayName.nilIfBlank ?? "Player") avatar")
    }
}
