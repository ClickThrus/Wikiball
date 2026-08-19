import Foundation

actor WikipediaService {
    enum WikiError: Error { case invalidURL, missingPage, parsingFailed }
    private var cache: [String: [CareerStop]] = [:]

    func career(for title: String) async throws -> [CareerStop] {
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
        let stops = WikipediaCareerParser.parse(root.parse.wikitext.text)
        guard stops.count >= 2 else { throw WikiError.parsingFailed }
        cache[title] = stops
        return stops
    }
}

enum WikipediaCareerParser {
    static func parse(_ source: String) -> [CareerStop] {
        var years: [Int:String] = [:]
        var clubs: [Int:String] = [:]
        for rawLine in source.split(separator: "\n") {
            let line = String(rawLine)
            guard let equals = line.firstIndex(of: "=") else { continue }
            let key = line[..<equals].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "|")))
            let value = line[line.index(after: equals)...].trimmingCharacters(in: .whitespacesAndNewlines)
            if key.hasPrefix("years"), let index = Int(key.dropFirst(5)) { years[index] = clean(value) }
            if key.hasPrefix("clubs"), let index = Int(key.dropFirst(5)) { clubs[index] = clean(value) }
        }
        return years.keys.sorted().compactMap { index in
            guard let year = years[index], let club = clubs[index], !year.isEmpty, !club.isEmpty else { return nil }
            return CareerStop(years: year, club: club)
        }
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
