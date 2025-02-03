//
//  TestSegmentBroadcast.swift
//  
//
//  Created by Brandon Sneed on 2/29/24.
//

import XCTest
import Segment
@testable import AnalyticsLive

final class TestSegmentBroadcast: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    /*
    func testSegmentBroadcast() throws {
        LivePlugins.clearCache()
        
        let analytics = Analytics(configuration: Configuration(writeKey: "TEST"))
        let fallbackURL = bundleTestFile(file: "MyEdgeFunctions.js")
        analytics.add(plugin: LivePlugins(fallbackFileURL: fallbackURL))
        analytics.add(plugin: Signals.shared)
        
        //let webhookURL = URL(string: "https://webhook.site/42e7175d-eac9-4367-8941-53521b764f7f")!
        
        let config = Signals.Configuration(
            writeKey: "HDq8FTEv6WjAzTykX3U8hP4iVM7WbCy8",
            maximumBufferSize: 1000
        )
        Signals.shared.useConfiguration(config)
        
        analytics.waitUntilStarted()
        
        for i in 0..<1500 {
            let s = NavigationSignal(action: .entering, screen: "screen \(i)")
            Signals.shared.emit(signal: s)
            RunLoop.main.run(until: Date.distantPast)
        }
        
        RunLoop.main.run()

    }
     */
}
