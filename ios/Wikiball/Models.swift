import Foundation

enum MatchFeedbackKind: Equatable {
    case goal
    case nearMiss
    case farMiss
    case hint
}

struct MatchMoment: Identifiable, Equatable {
    let id = UUID()
    let kind: MatchFeedbackKind
}

enum Difficulty: String, CaseIterable, Codable, Identifiable {
    case easy, medium, hard
    var id: String { rawValue }
    var label: String {
        switch self {
        case .easy: return "Easy · Icons"
        case .medium: return "Medium · Fans"
        case .hard: return "Hard · Sickos 😈"
        }
    }
}

enum Region: String, CaseIterable, Codable, Identifiable {
    case europe = "Europe"
    case southAmerica = "South America"
    case africa = "Africa"
    case northAmerica = "North America"
    case asiaPacific = "Asia-Pacific"
    var id: String { rawValue }
}

struct CareerStop: Hashable, Codable, Identifiable {
    let years: String
    let club: String
    var id: String { "\(years)-\(club)" }
}

struct PlayerSeed: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let aliases: [String]
    let wikipediaTitle: String
    let difficulty: Difficulty
    let nationality: String
    let region: Region
    let position: String
    let career: [CareerStop]
    var cardRarity: CardRarity { switch difficulty { case .easy: return .common; case .medium: return .rare; case .hard: return .elite } }
}

struct LeagueOption: Identifiable, Hashable {
    let id: String
    let country: String
    let league: String
    let clubs: Set<String>
    var label: String { "\(country) · \(league)" }
}

struct GameFilters: Equatable, Codable {
    var difficulty: Difficulty?
    var decade: String?
    var team: String?
    var region: Region?
    var leagueID: String?
}

struct PlayerProfile: Codable, Equatable {
    var displayName = "Player"
    var avatarEmoji = "⚽️"
    var avatarColor = "purple"
    var avatarUsesInitials = false
    var favoriteTeam: String?
    var favoritePlayer: String?
    var xp = 0
    var coins = 100
    var streak = 0
    var bestStreak = 0
    var correct = 0
    var played = 0
    var dailyCompleted = 0
    var easyCorrect = 0
    var mediumCorrect = 0
    var hardCorrect = 0
    var hintsUsed = 0
    var rewardedDailyDates: Set<String> = []
    var processedPurchaseIDs: Set<UInt64> = []
    var mastery = MasteryState.empty

    private enum CodingKeys: String, CodingKey {
        case displayName, avatarEmoji, avatarColor, avatarUsesInitials, favoriteTeam, favoritePlayer
        case xp, coins, streak, bestStreak, correct, played, dailyCompleted
        case easyCorrect, mediumCorrect, hardCorrect, hintsUsed, rewardedDailyDates, processedPurchaseIDs, mastery, lastDaily
    }

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try values.decodeIfPresent(String.self, forKey: .displayName) ?? "Player"
        avatarEmoji = try values.decodeIfPresent(String.self, forKey: .avatarEmoji) ?? "⚽️"
        avatarColor = try values.decodeIfPresent(String.self, forKey: .avatarColor) ?? "purple"
        avatarUsesInitials = try values.decodeIfPresent(Bool.self, forKey: .avatarUsesInitials) ?? false
        favoriteTeam = try values.decodeIfPresent(String.self, forKey: .favoriteTeam)
        favoritePlayer = try values.decodeIfPresent(String.self, forKey: .favoritePlayer)
        xp = try values.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        coins = try values.decodeIfPresent(Int.self, forKey: .coins) ?? 100
        streak = try values.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        bestStreak = try values.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        correct = try values.decodeIfPresent(Int.self, forKey: .correct) ?? 0
        played = try values.decodeIfPresent(Int.self, forKey: .played) ?? 0
        dailyCompleted = try values.decodeIfPresent(Int.self, forKey: .dailyCompleted) ?? 0
        easyCorrect = try values.decodeIfPresent(Int.self, forKey: .easyCorrect) ?? 0
        mediumCorrect = try values.decodeIfPresent(Int.self, forKey: .mediumCorrect) ?? 0
        hardCorrect = try values.decodeIfPresent(Int.self, forKey: .hardCorrect) ?? 0
        hintsUsed = try values.decodeIfPresent(Int.self, forKey: .hintsUsed) ?? 0
        rewardedDailyDates = try values.decodeIfPresent(Set<String>.self, forKey: .rewardedDailyDates) ?? []
        processedPurchaseIDs = try values.decodeIfPresent(Set<UInt64>.self, forKey: .processedPurchaseIDs) ?? []
        mastery = (try? values.decodeIfPresent(MasteryState.self, forKey: .mastery)) ?? .empty
        if let legacyDate = try values.decodeIfPresent(String.self, forKey: .lastDaily) {
            rewardedDailyDates.insert(legacyDate)
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(displayName, forKey: .displayName)
        try values.encode(avatarEmoji, forKey: .avatarEmoji)
        try values.encode(avatarColor, forKey: .avatarColor)
        try values.encode(avatarUsesInitials, forKey: .avatarUsesInitials)
        try values.encodeIfPresent(favoriteTeam, forKey: .favoriteTeam)
        try values.encodeIfPresent(favoritePlayer, forKey: .favoritePlayer)
        try values.encode(xp, forKey: .xp)
        try values.encode(coins, forKey: .coins)
        try values.encode(streak, forKey: .streak)
        try values.encode(bestStreak, forKey: .bestStreak)
        try values.encode(correct, forKey: .correct)
        try values.encode(played, forKey: .played)
        try values.encode(dailyCompleted, forKey: .dailyCompleted)
        try values.encode(easyCorrect, forKey: .easyCorrect)
        try values.encode(mediumCorrect, forKey: .mediumCorrect)
        try values.encode(hardCorrect, forKey: .hardCorrect)
        try values.encode(hintsUsed, forKey: .hintsUsed)
        try values.encode(rewardedDailyDates, forKey: .rewardedDailyDates)
        try values.encode(processedPurchaseIDs, forKey: .processedPurchaseIDs)
        try values.encode(mastery, forKey: .mastery)
    }
}

struct Tier: Identifiable {
    let name: String
    let minimumXP: Int
    let icon: String
    var id: String { name }
}

enum SeedData {
    static let tiers = [
        Tier(name: "Rookie", minimumXP: 0, icon: "🌱"),
        Tier(name: "Prospect", minimumXP: 350, icon: "🟢"),
        Tier(name: "Pro", minimumXP: 900, icon: "🔵"),
        Tier(name: "Star", minimumXP: 1800, icon: "⭐"),
        Tier(name: "World Class", minimumXP: 3200, icon: "🌍"),
        Tier(name: "Legend", minimumXP: 5200, icon: "👑")
    ]

    static let decades = ["1990s", "2000s", "2010s", "2020s"]

    static let leagues = [
        LeagueOption(id: "england-premier-league", country: "England", league: "Premier League", clubs: ["Manchester United", "Arsenal", "Liverpool", "Chelsea", "Manchester City", "Tottenham Hotspur", "Everton", "Fulham", "Southampton"]),
        LeagueOption(id: "spain-la-liga", country: "Spain", league: "La Liga", clubs: ["Real Madrid", "Barcelona", "Atlético Madrid", "Mallorca", "Espanyol"]),
        LeagueOption(id: "italy-serie-a", country: "Italy", league: "Serie A", clubs: ["Juventus", "Inter Milan", "AC Milan", "Sampdoria"]),
        LeagueOption(id: "germany-bundesliga", country: "Germany", league: "Bundesliga", clubs: ["Bayern Munich", "Borussia Dortmund", "Bayer Leverkusen", "RB Leipzig", "Schalke 04", "Werder Bremen", "Hamburger SV", "VfL Wolfsburg"]),
        LeagueOption(id: "france-ligue-1", country: "France", league: "Ligue 1", clubs: ["Paris Saint-Germain", "Monaco", "Marseille"]),
        LeagueOption(id: "usa-canada-mls", country: "USA / Canada", league: "MLS", clubs: ["LA Galaxy", "New York Red Bulls", "Inter Miami", "Los Angeles FC", "Montreal Impact", "Seattle Sounders FC", "New England Revolution"])
    ]

    static let players: [PlayerSeed] = [
        PlayerSeed(id: "cristiano-ronaldo", name: "Cristiano Ronaldo", aliases: ["Ronaldo", "CR7"], wikipediaTitle: "Cristiano Ronaldo", difficulty: .easy, nationality: "Portugal", region: .europe, position: "Forward", career: [CareerStop(years: "2002–2003", club: "Sporting CP B"), CareerStop(years: "2002–2003", club: "Sporting CP"), CareerStop(years: "2003–2009", club: "Manchester United"), CareerStop(years: "2009–2018", club: "Real Madrid"), CareerStop(years: "2018–2021", club: "Juventus"), CareerStop(years: "2021–2022", club: "Manchester United"), CareerStop(years: "2023–", club: "Al-Nassr")]),
        PlayerSeed(id: "lionel-messi", name: "Lionel Messi", aliases: ["Messi", "Leo Messi"], wikipediaTitle: "Lionel Messi", difficulty: .easy, nationality: "Argentina", region: .southAmerica, position: "Forward", career: [CareerStop(years: "2003–2004", club: "Barcelona C"), CareerStop(years: "2004–2005", club: "Barcelona B"), CareerStop(years: "2004–2021", club: "Barcelona"), CareerStop(years: "2021–2023", club: "Paris Saint-Germain"), CareerStop(years: "2023–", club: "Inter Miami")]),
        PlayerSeed(id: "david-beckham", name: "David Beckham", aliases: ["Beckham"], wikipediaTitle: "David Beckham", difficulty: .easy, nationality: "England", region: .europe, position: "Midfielder", career: [CareerStop(years: "1992–2003", club: "Manchester United"), CareerStop(years: "1995", club: "Preston North End (loan)"), CareerStop(years: "2003–2007", club: "Real Madrid"), CareerStop(years: "2007–2012", club: "LA Galaxy"), CareerStop(years: "2009", club: "AC Milan (loan)"), CareerStop(years: "2010", club: "AC Milan (loan)"), CareerStop(years: "2013", club: "Paris Saint-Germain")]),
        PlayerSeed(id: "neymar", name: "Neymar", aliases: ["Neymar Jr", "Neymar Jr."], wikipediaTitle: "Neymar", difficulty: .easy, nationality: "Brazil", region: .southAmerica, position: "Forward", career: [CareerStop(years: "2009–2013", club: "Santos"), CareerStop(years: "2013–2017", club: "Barcelona"), CareerStop(years: "2017–2023", club: "Paris Saint-Germain"), CareerStop(years: "2023–2025", club: "Al Hilal"), CareerStop(years: "2025–", club: "Santos")]),
        PlayerSeed(id: "thierry-henry", name: "Thierry Henry", aliases: ["Henry"], wikipediaTitle: "Thierry Henry", difficulty: .easy, nationality: "France", region: .europe, position: "Forward", career: [CareerStop(years: "1994–1995", club: "Monaco B"), CareerStop(years: "1994–1999", club: "Monaco"), CareerStop(years: "1999", club: "Juventus"), CareerStop(years: "1999–2007", club: "Arsenal"), CareerStop(years: "2007–2010", club: "Barcelona"), CareerStop(years: "2010–2014", club: "New York Red Bulls"), CareerStop(years: "2012", club: "Arsenal (loan)")]),
        PlayerSeed(id: "fernando-torres", name: "Fernando Torres", aliases: ["Torres", "El Niño"], wikipediaTitle: "Fernando Torres", difficulty: .medium, nationality: "Spain", region: .europe, position: "Striker", career: [CareerStop(years: "2001–2007", club: "Atlético Madrid"), CareerStop(years: "2007–2011", club: "Liverpool"), CareerStop(years: "2011–2015", club: "Chelsea"), CareerStop(years: "2014–2015", club: "AC Milan (loan)"), CareerStop(years: "2015–2016", club: "AC Milan"), CareerStop(years: "2015–2016", club: "Atlético Madrid (loan)"), CareerStop(years: "2016–2018", club: "Atlético Madrid"), CareerStop(years: "2018–2019", club: "Sagan Tosu")]),
        PlayerSeed(id: "luis-suarez", name: "Luis Suárez", aliases: ["Luis Suarez", "Suarez", "Suárez"], wikipediaTitle: "Luis Suárez", difficulty: .medium, nationality: "Uruguay", region: .southAmerica, position: "Striker", career: [CareerStop(years: "2005–2006", club: "Nacional"), CareerStop(years: "2006–2007", club: "Groningen"), CareerStop(years: "2007–2011", club: "Ajax"), CareerStop(years: "2011–2014", club: "Liverpool"), CareerStop(years: "2014–2020", club: "Barcelona"), CareerStop(years: "2020–2022", club: "Atlético Madrid"), CareerStop(years: "2022–2023", club: "Nacional"), CareerStop(years: "2023–2024", club: "Grêmio"), CareerStop(years: "2024–", club: "Inter Miami")]),
        PlayerSeed(id: "didier-drogba", name: "Didier Drogba", aliases: ["Drogba"], wikipediaTitle: "Didier Drogba", difficulty: .medium, nationality: "Ivory Coast", region: .africa, position: "Striker", career: [CareerStop(years: "1998–2002", club: "Le Mans"), CareerStop(years: "2002–2003", club: "Guingamp"), CareerStop(years: "2003–2004", club: "Marseille"), CareerStop(years: "2004–2012", club: "Chelsea"), CareerStop(years: "2012–2013", club: "Shanghai Shenhua"), CareerStop(years: "2013–2014", club: "Galatasaray"), CareerStop(years: "2014–2015", club: "Chelsea"), CareerStop(years: "2015–2016", club: "Montreal Impact"), CareerStop(years: "2017–2018", club: "Phoenix Rising")]),
        PlayerSeed(id: "tim-cahill", name: "Tim Cahill", aliases: ["Cahill"], wikipediaTitle: "Tim Cahill", difficulty: .hard, nationality: "Australia", region: .asiaPacific, position: "Attacking midfielder", career: [CareerStop(years: "1997", club: "Sydney United"), CareerStop(years: "1997–2004", club: "Millwall"), CareerStop(years: "2004–2012", club: "Everton"), CareerStop(years: "2012–2015", club: "New York Red Bulls"), CareerStop(years: "2015–2016", club: "Shanghai Shenhua"), CareerStop(years: "2016", club: "Hangzhou Greentown"), CareerStop(years: "2016–2017", club: "Melbourne City"), CareerStop(years: "2018", club: "Millwall"), CareerStop(years: "2018–2019", club: "Jamshedpur")]),
        PlayerSeed(id: "clint-dempsey", name: "Clint Dempsey", aliases: ["Dempsey"], wikipediaTitle: "Clint Dempsey", difficulty: .hard, nationality: "United States", region: .northAmerica, position: "Forward", career: [CareerStop(years: "2004–2006", club: "New England Revolution"), CareerStop(years: "2007–2012", club: "Fulham"), CareerStop(years: "2012–2013", club: "Tottenham Hotspur"), CareerStop(years: "2013–2018", club: "Seattle Sounders FC"), CareerStop(years: "2014", club: "Fulham (loan)")])
    ]

    static var teams: [String] {
        Array(Set(players.flatMap { $0.career.map { baseClubName($0.club) } })).sorted()
    }

    static func baseClubName(_ club: String) -> String {
        GameRules.baseClubName(club)
    }
}
