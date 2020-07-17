import XCTest
@testable import TrHealthKit

final class TrHealthKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TrHealthKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
