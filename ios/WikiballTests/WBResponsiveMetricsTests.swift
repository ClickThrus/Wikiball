import XCTest
@testable import Wikiball

final class WBResponsiveMetricsTests: XCTestCase {
    func testCompactBreakpointUsesCompactMargins() {
        let compact = WBResponsiveMetrics(availableWidth: 360)
        XCTAssertTrue(compact.isCompact)
        XCTAssertEqual(compact.horizontalMargin, WBDesign.Layout.compactHorizontalMargin)

        let regular = WBResponsiveMetrics(availableWidth: 393)
        XCTAssertFalse(regular.isCompact)
        XCTAssertEqual(regular.horizontalMargin, WBDesign.Layout.regularHorizontalMargin)
    }

    func testContentNeverExceedsReadableMaximum() {
        for width in [320.0, 360.0, 375.0, 393.0, 402.0, 430.0, 440.0, 520.0, 700.0] {
            let metrics = WBResponsiveMetrics(availableWidth: width)
            XCTAssertLessThanOrEqual(metrics.contentWidth, WBDesign.Layout.maxReadableWidth)
            XCTAssertLessThanOrEqual(metrics.contentWidth + metrics.horizontalMargin * 2, width + 0.001)
            XCTAssertGreaterThanOrEqual(metrics.contentWidth, 0)
        }
    }

    func testArtworkScaleStaysInsideSafeBounds() {
        for width in [320.0, 360.0, 393.0, 430.0, 440.0, 520.0, 700.0] {
            let metrics = WBResponsiveMetrics(availableWidth: width)
            XCTAssertGreaterThanOrEqual(metrics.artScale, 0.88)
            XCTAssertLessThanOrEqual(metrics.artScale, 1.08)
        }
    }

    func testReferenceWidthProducesNearUnitArtworkScale() {
        let metrics = WBResponsiveMetrics(availableWidth: WBDesign.Layout.referenceWidth)
        XCTAssertEqual(metrics.artScale, 1.0, accuracy: 0.02)
    }
}
