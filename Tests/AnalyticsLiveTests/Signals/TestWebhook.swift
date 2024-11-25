//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/16/24.
//

import Foundation
import XCTest
@testable import Segment
@testable import AnalyticsLive

func bundleTestFile(file: String) -> URL? {
    let bundle = Bundle.module
    if let pathURL = bundle.url(forResource: file, withExtension: nil) {
        return pathURL
    }
    return nil
}

final class WebhookTests: XCTestCase {
    /*
    func testExample() throws {
        LivePlugins.clearCache()
        
        let analytics = Analytics(configuration: Configuration(writeKey: "TEST"))
        let fallbackURL = bundleTestFile(file: "MyEdgeFunctions.js")
        analytics.add(plugin: LivePlugins(fallbackFileURL: fallbackURL))
        analytics.add(plugin: Signals.shared)
        
        let webhookURL = URL(string: "https://webhook.site/42e7175d-eac9-4367-8941-53521b764f7f")!
        
        let config = Signals.Configuration(
            writeKey: "1234",
            maximumBufferSize: 1000,
            broadcasters: [WebhookBroadcaster(url: webhookURL)]
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
