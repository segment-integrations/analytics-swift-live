//
//  TestBuild.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 9/27/24.
//

import XCTest
import Segment
import AnalyticsLive

final class TestBuild: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDoestItWork() throws {
        let a = Analytics(configuration: Configuration(writeKey: "1234"))
        
        let lp = LivePlugins(fallbackFileURL: nil)
        print(lp)
    }
}
