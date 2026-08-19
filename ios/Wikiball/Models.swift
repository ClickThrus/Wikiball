import Foundation

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
    let name: String
    let aliases: [String]
    let wikipediaTitle: String
    let difficulty: Difficulty
    let nationality: String
    let region: Region
    let position: String
    let career: [CareerStop]
    var id: String { wikipediaTitle }
}

struct LeagueOption: Identifiable, Hashable {
    let id: String
    let country: String
    let league: String
    let clubs: Set<String>
    var label: String { "\(country) · \(league)" }
}

struct GameFilters: Equatable {
    var difficulty: Difficulty?
    var decade: String?
    var team: String?
    var region: Region?
    var leagueID: String?
}

struct PlayerProfile: Codable {
    var xp = 0
    var coins = 100
    var streak = 0
    var bestStreak = 0
    var correct = 0
    var played = 0
    var lastDaily: String?
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
        LeagueOption(id: "france-ligue-1", country: "France", league: "Ligue 1", clubs: ["Paris Saint-Germain", "Monaco", "Marseille"]),
        LeagueOption(id: "usa-canada-mls", country: "USA / Canada", league: "MLS", clubs: ["LA Galaxy", "New York Red Bulls", "Inter Miami", "Los Angeles FC", "Montreal Impact", "Seattle Sounders FC", "New England Revolution"])
    ]

    static let players: [PlayerSeed] = [
        PlayerSeed(name: "Cristiano Ronaldo", aliases: ["Ronaldo", "CR7"], wikipediaTitle: "Cristiano Ronaldo", difficulty: .easy, nationality: "Portugal", region: .europe, position: "Forward", career: [CareerStop(years: "2002–2003", club: "Sporting CP"), CareerStop(years: "2003–2009", club: "Manchester United"), CareerStop(years: "2009–2018", club: "Real Madrid"), CareerStop(years: "2018–2021", club: "Juventus"), CareerStop(years: "2021–2022", club: "Manchester United"), CareerStop(years: "2023–", club: "Al Nassr")]),
        PlayerSeed(name: "Lionel Messi", aliases: ["Messi", "Leo Messi"], wikipediaTitle: "Lionel Messi", difficulty: .easy, nationality: "Argentina", region: .southAmerica, position: "Forward", career: [CareerStop(years: "2004–2021", club: "Barcelona"), CareerStop(years: "2021–2023", club: "Paris Saint-Germain"), CareerStop(years: "2023–", club: "Inter Miami")]),
        PlayerSeed(name: "David Beckham", aliases: ["Beckham"], wikipediaTitle: "David Beckham", difficulty: .easy, nationality: "England", region: .europe, position: "Midfielder", career: [CareerStop(years: "1992–2003", club: "Manchester United"), CareerStop(years: "2003–2007", club: "Real Madrid"), CareerStop(years: "2007–2012", club: "LA Galaxy"), CareerStop(years: "2009", club: "AC Milan (loan)"), CareerStop(years: "2010", club: "AC Milan (loan)"), CareerStop(years: "2013", club: "Paris Saint-Germain")]),
        PlayerSeed(name: "Neymar", aliases: ["Neymar Jr", "Neymar Jr."], wikipediaTitle: "Neymar", difficulty: .easy, nationality: "Brazil", region: .southAmerica, position: "Forward", career: [CareerStop(years: "2009–2013", club: "Santos"), CareerStop(years: "2013–2017", club: "Barcelona"), CareerStop(years: "2017–2023", club: "Paris Saint-Germain"), CareerStop(years: "2023–2025", club: "Al Hilal"), CareerStop(years: "2025–", club: "Santos")]),
        PlayerSeed(name: "Thierry Henry", aliases: ["Henry"], wikipediaTitle: "Thierry Henry", difficulty: .easy, nationality: "France", region: .europe, position: "Forward", career: [CareerStop(years: "1994–1999", club: "Monaco"), CareerStop(years: "1999", club: "Juventus"), CareerStop(years: "1999–2007", club: "Arsenal"), CareerStop(years: "2007–2010", club: "Barcelona"), CareerStop(years: "2010–2014", club: "New York Red Bulls")]),
        PlayerSeed(name: "Fernando Torres", aliases: ["Torres"], wikipediaTitle: "Fernando Torres", difficulty: .medium, nationality: "Spain", region: .europe, position: "Striker", career: [CareerStop(years: "2001–2007", club: "Atlético Madrid"), CareerStop(years: "2007–2011", club: "Liverpool"), CareerStop(years: "2011–2015", club: "Chelsea"), CareerStop(years: "2014–2016", club: "AC Milan"), CareerStop(years: "2015–2018", club: "Atlético Madrid"), CareerStop(years: "2018–2019", club: "Sagan Tosu")]),
        PlayerSeed(name: "Luis Suárez", aliases: ["Luis Suarez", "Suarez", "Suárez"], wikipediaTitle: "Luis Suárez", difficulty: .medium, nationality: "Uruguay", region: .southAmerica, position: "Striker", career: [CareerStop(years: "2005–2006", club: "Nacional"), CareerStop(years: "2006–2007", club: "Groningen"), CareerStop(years: "2007–2011", club: "Ajax"), CareerStop(years: "2011–2014", club: "Liverpool"), CareerStop(years: "2014–2020", club: "Barcelona"), CareerStop(years: "2020–2022", club: "Atlético Madrid"), CareerStop(years: "2024–", club: "Inter Miami")]),
        PlayerSeed(name: "Didier Drogba", aliases: ["Drogba"], wikipediaTitle: "Didier Drogba", difficulty: .medium, nationality: "Ivory Coast", region: .africa, position: "Striker", career: [CareerStop(years: "1998–2002", club: "Le Mans"), CareerStop(years: "2002–2003", club: "Guingamp"), CareerStop(years: "2003–2004", club: "Marseille"), CareerStop(years: "2004–2012", club: "Chelsea"), CareerStop(years: "2013–2014", club: "Galatasaray"), CareerStop(years: "2014–2015", club: "Chelsea"), CareerStop(years: "2015–2016", club: "Montreal Impact")]),
        PlayerSeed(name: "Tim Cahill", aliases: ["Cahill"], wikipediaTitle: "Tim Cahill", difficulty: .hard, nationality: "Australia", region: .asiaPacific, position: "Attacking midfielder", career: [CareerStop(years: "1998–2004", club: "Millwall"), CareerStop(years: "2004–2012", club: "Everton"), CareerStop(years: "2012–2015", club: "New York Red Bulls"), CareerStop(years: "2015–2016", club: "Shanghai Shenhua"), CareerStop(years: "2016–2017", club: "Melbourne City")]),
        PlayerSeed(name: "Clint Dempsey", aliases: ["Dempsey"], wikipediaTitle: "Clint Dempsey", difficulty: .hard, nationality: "United States", region: .northAmerica, position: "Forward", career: [CareerStop(years: "2004–2006", club: "New England Revolution"), CareerStop(years: "2007–2012", club: "Fulham"), CareerStop(years: "2012–2013", club: "Tottenham Hotspur"), CareerStop(years: "2013–2018", club: "Seattle Sounders FC")])
    ]

    static var teams: [String] {
        Array(Set(players.flatMap { $0.career.map { baseClubName($0.club) } })).sorted()
    }

    static func baseClubName(_ club: String) -> String {
        club.replacingOccurrences(of: " (loan)", with: "")
    }
}
