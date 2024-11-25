import XCTest
@testable import AnalyticsLive

final class SignalsTests: XCTestCase {
    func testDebugCheck() {
        let debug = isAppRunningInDebug()
        XCTAssertTrue(debug)
    }
}
