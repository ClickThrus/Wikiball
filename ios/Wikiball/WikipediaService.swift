import Foundation

actor WikipediaService {
    enum WikiError: Error { case invalidURL, missingPage, parsingFailed }

    func career(for title: String) async throws -> [CareerStop] {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "parse"),
            URLQueryItem(name: "page", value: title),
            URLQueryItem(name: "prop", value: "wikitext"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "origin", value: "*")
        ]
        guard let url = components?.url else { throw WikiError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw WikiError.missingPage }
        let root = try JSONDecoder().decode(ParseResponse.self, from: data)
        let stops = parseCareer(from: root.parse.wikitext.text)
        guard stops.count >= 2 else { throw WikiError.parsingFailed }
        return stops
    }

    private func parseCareer(from source: String) -> [CareerStop] {
        var years: [Int:String] = [:]
        var clubs: [Int:String] = [:]
        for rawLine in source.split(separator: "\n") {
            let line = String(rawLine)
            guard let equals = line.firstIndex(of: "=") else { continue }
            let key = line[..<equals].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = line[line.index(after: equals)...].trimmingCharacters(in: .whitespacesAndNewlines)
            if key.hasPrefix("years"), let index = Int(key.dropFirst(5)) { years[index] = clean(value) }
            if key.hasPrefix("clubs"), let index = Int(key.dropFirst(5)) { clubs[index] = clean(value) }
        }
        return years.keys.sorted().compactMap { index in
            guard let year = years[index], let club = clubs[index], !year.isEmpty, !club.isEmpty else { return nil }
            return CareerStop(years: year, club: club)
        }
    }

    private func clean(_ raw: String) -> String {
        var value = raw
        value = value.replacingOccurrences(of: "'''", with: "").replacingOccurrences(of: "''", with: "")
        value = value.replacingOccurrences(of: #"\[\[([^\]|]+)\|([^\]]+)\]\]"#, with: "$2", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\[\[([^\]]+)\]\]"#, with: "$1", options: .regularExpression)
        value = value.replacingOccurrences(of: #"<ref[^>]*>.*?</ref>"#, with: "", options: [.regularExpression, .caseInsensitive])
        value = value.replacingOccurrences(of: #"<ref[^>]*/>"#, with: "", options: [.regularExpression, .caseInsensitive])
        value = value.replacingOccurrences(of: #"\{\{[^{}]*\}\}"#, with: "", options: .regularExpression)
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
