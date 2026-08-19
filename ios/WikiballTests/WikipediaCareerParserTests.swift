import XCTest
@testable import Wikiball

final class WikipediaCareerParserTests: XCTestCase {
    func testParsesChronologicalSeniorCareerAndCleansMarkup() {
        let source = #"""
        {{Infobox football biography
        | youthyears1 = 1998–2000
        | youthclubs1 = Example Academy
        | years1 = 2001–2004<ref name="one">Citation</ref>
        | clubs1 = [[Amsterdamsche Football Club Ajax|Ajax]]
        | years2 = 2004–2006
        | clubs2 = {{nowrap|[[Juventus FC|Juventus]]}}
        | years3 = 2006
        | clubs3 = [[AC Milan]] {{loan}}
        | nationalyears1 = 2002–2015
        | nationalteam1 = Sweden
        }}
        """#

        XCTAssertEqual(WikipediaCareerParser.parse(source), [
            CareerStop(years: "2001–2004", club: "Ajax"),
            CareerStop(years: "2004–2006", club: "Juventus"),
            CareerStop(years: "2006", club: "AC Milan (loan)")
        ])
    }

    func testRemovesMultilineReferencesAndHtml() {
        let source = #"""
        | years1 = 1998&ndash;2002<ref>
        multiline citation
        </ref>
        | clubs1 = '''[[Paris Saint-Germain F.C.|Paris Saint-Germain]]'''<br />First team
        | years2 = 2002–2004
        | clubs2 = [[Chelsea F.C.|Chelsea]]
        """#
        let result = WikipediaCareerParser.parse(source)
        XCTAssertEqual(result.first?.years, "1998–2002")
        XCTAssertEqual(result.first?.club, "Paris Saint-Germain / First team")
    }

    func testParsesCompleteSeniorAppearancesAndGoals() {
        let source = #"""
        | years1 = 2001–2004
        | clubs1 = Ajax
        | caps1 = 100
        | goals1 = 42
        | years2 = 2004–2008
        | clubs2 = Juventus
        | caps2 = 120
        | goals2 = 51
        """#
        let result = WikipediaCareerParser.parseData(source)
        XCTAssertEqual(result.stats?.seniorAppearances, 220)
        XCTAssertEqual(result.stats?.seniorGoals, 93)
        XCTAssertNil(result.stats?.transferFees)
    }

    func testHidesIncompleteAggregateStats() {
        let source = #"""
        | years1 = 2001–2004
        | clubs1 = Ajax
        | caps1 = 100
        | goals1 = 42
        | years2 = 2004–2008
        | clubs2 = Juventus
        """#
        XCTAssertNil(WikipediaCareerParser.parseData(source).stats)
    }
}
