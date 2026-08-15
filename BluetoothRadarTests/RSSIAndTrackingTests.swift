import XCTest
@testable import BluetoothRadar

final class RSSIAndTrackingTests: XCTestCase {
    func testNormalizationBoundariesAndClamping() {
        XCTAssertEqual(RSSIMapper.normalized(-100), 0)
        XCTAssertEqual(RSSIMapper.normalized(-90), 0.2, accuracy: 0.0001)
        XCTAssertEqual(RSSIMapper.normalized(-80), 0.4, accuracy: 0.0001)
        XCTAssertEqual(RSSIMapper.normalized(-70), 0.6, accuracy: 0.0001)
        XCTAssertEqual(RSSIMapper.normalized(-60), 0.8, accuracy: 0.0001)
        XCTAssertEqual(RSSIMapper.normalized(-50), 1)
        XCTAssertEqual(RSSIMapper.normalized(-120), 0)
        XCTAssertEqual(RSSIMapper.normalized(-20), 1)
        XCTAssertTrue(RSSIMapper.normalized(.nan).isFinite)
        XCTAssertTrue(RSSIMapper.normalized(.infinity).isFinite)
    }

    func testEMAFiltering() {
        var filter = RSSIFilter(alpha: 0.25)
        XCTAssertEqual(filter.update(with: -80), -80)
        XCTAssertEqual(filter.update(with: -60), -75, accuracy: 0.0001)
        XCTAssertEqual(filter.update(with: -60), -71.25, accuracy: 0.0001)
    }

    func testSignalClassification() {
        XCTAssertEqual(RSSIMapper.signalLevel(for: -100), .veryWeak)
        XCTAssertEqual(RSSIMapper.signalLevel(for: -90), .weak)
        XCTAssertEqual(RSSIMapper.signalLevel(for: -80), .medium)
        XCTAssertEqual(RSSIMapper.signalLevel(for: -70), .strong)
        XCTAssertEqual(RSSIMapper.signalLevel(for: -50), .veryStrong)
    }

    func testLostTimeoutThreshold() {
        let timeout: TimeInterval = 3
        let seen = Date(timeIntervalSince1970: 100)
        XCTAssertFalse(Date(timeIntervalSince1970: 102.9).timeIntervalSince(seen) >= timeout)
        XCTAssertTrue(Date(timeIntervalSince1970: 103).timeIntervalSince(seen) >= timeout)
    }
}
