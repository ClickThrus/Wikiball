import Foundation

actor WikipediaService {
    enum WikiError: Error { case invalidURL, missingPage, parsingFailed }
    private var cache: [String: WikipediaCareerData] = [:]

    func career(for title: String) async throws -> [CareerStop] {
        try await careerData(for: title).career
    }

    func careerData(for title: String) async throws -> WikipediaCareerData {
        if let cached = cache[title] { return cached }
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "parse"),
            URLQueryItem(name: "page", value: title),
            URLQueryItem(name: "prop", value: "wikitext"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "origin", value: "*")
        ]
        guard let url = components?.url else { throw WikiError.invalidURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Wikiball-iOS/1.0 (football trivia; Wikipedia attribution in app)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw WikiError.missingPage }
        let root = try JSONDecoder().decode(ParseResponse.self, from: data)
        let parsed = WikipediaCareerParser.parseData(root.parse.wikitext.text)
        guard parsed.career.count >= 2 else { throw WikiError.parsingFailed }
        cache[title] = parsed
        return parsed
    }
}

struct WikipediaCareerData: Equatable {
    let career: [CareerStop]
    let stats: PlayerCareerStats?
}

enum WikipediaCareerParser {
    static func parse(_ source: String) -> [CareerStop] {
        parseData(source).career
    }

    static func parseData(_ source: String) -> WikipediaCareerData {
        var years: [Int:String] = [:]
        var clubs: [Int:String] = [:]
        var caps: [Int:Int] = [:]
        var goals: [Int:Int] = [:]
        for rawLine in source.split(separator: "\n") {
            let line = String(rawLine)
            guard let equals = line.firstIndex(of: "=") else { continue }
            let key = line[..<equals].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "|")))
            let value = line[line.index(after: equals)...].trimmingCharacters(in: .whitespacesAndNewlines)
            if key.hasPrefix("years"), let index = Int(key.dropFirst(5)) { years[index] = clean(value) }
            if key.hasPrefix("clubs"), let index = Int(key.dropFirst(5)) { clubs[index] = clean(value) }
            if key.hasPrefix("caps"), let index = Int(key.dropFirst(4)), let number = parseNumber(value) { caps[index] = number }
            if key.hasPrefix("goals"), let index = Int(key.dropFirst(5)), let number = parseNumber(value) { goals[index] = number }
        }
        let validIndices = years.keys.sorted().filter { clubs[$0] != nil }
        let career: [CareerStop] = validIndices.compactMap { index in
            guard let year = years[index], let club = clubs[index], !year.isEmpty, !club.isEmpty else { return nil }
            return CareerStop(years: year, club: club)
        }
        let appearances = validIndices.allSatisfy { caps[$0] != nil } ? validIndices.compactMap { caps[$0] }.reduce(0, +) : nil
        let seniorGoals = validIndices.allSatisfy { goals[$0] != nil } ? validIndices.compactMap { goals[$0] }.reduce(0, +) : nil
        let stats = appearances == nil && seniorGoals == nil ? nil : PlayerCareerStats(seniorAppearances: appearances, seniorGoals: seniorGoals, transferFees: nil)
        return WikipediaCareerData(career: career, stats: stats)
    }

    private static func parseNumber(_ raw: String) -> Int? {
        let cleaned = clean(raw).replacingOccurrences(of: ",", with: "")
        guard let range = cleaned.range(of: #"\d+"#, options: .regularExpression) else { return nil }
        return Int(cleaned[range])
    }

    static func clean(_ raw: String) -> String {
        var value = raw
        value = value.replacingOccurrences(of: #"^\s*(?:→|&rarr;)\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
        value = value.replacingOccurrences(of: #"(?i)<ref\b.*$"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"<!--.*?-->"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\{\{\s*(?:on loan|loan)\s*\}\}"#, with: "(loan)", options: [.regularExpression, .caseInsensitive])
        for _ in 0..<4 {
            value = value.replacingOccurrences(of: #"\{\{\s*(?:nowrap|nobreak|small)\s*\|([^{}]*)\}\}"#, with: "$1", options: [.regularExpression, .caseInsensitive])
        }
        value = value.replacingOccurrences(of: "'''", with: "").replacingOccurrences(of: "''", with: "")
        value = value.replacingOccurrences(of: #"\[\[([^\]|]+)\|([^\]]+)\]\]"#, with: "$2", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\[\[([^\]]+)\]\]"#, with: "$1", options: .regularExpression)
        value = value.replacingOccurrences(of: #"<br\s*/?>"#, with: " / ", options: [.regularExpression, .caseInsensitive])
        value = value.replacingOccurrences(of: #"\{\{[^{}]*\}\}"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: "&nbsp;", with: " ")
        value = value.replacingOccurrences(of: "&ndash;", with: "–")
        value = value.replacingOccurrences(of: "&amp;", with: "&")
        value = value.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ParseResponse: Decodable {
    let parse: ParseBody
    struct ParseBody: Decodable {
        let wikitext: WikiText
    }
    struct WikiText: Decodable {
        let text: String
        enum CodingKeys: String, CodingKey { case text = "*" }
    }
}
