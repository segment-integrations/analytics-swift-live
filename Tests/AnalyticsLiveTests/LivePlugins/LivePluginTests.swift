//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import XCTest
@testable import Segment
@testable import Substrata
@testable import AnalyticsLive

class LivePluginTests: XCTestCase {
    let downloadURL = URL(string: "http://segment.com/bundles/testbundle.js")!
    let errorURL = URL(string:"http://error.com/bundles/testbundle.js")
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // setup our mock network handling.
        Bundler.sessionConfig = URLSessionConfiguration.ephemeral
        Bundler.sessionConfig.protocolClasses = [URLProtocolMock.self]
        
        let dataFile = bundleTestFile(file: "testbundle.js")
        let bundleData = try Data(contentsOf: dataFile!)
        
        URLProtocolMock.testURLs = [
            downloadURL: .success(bundleData),
            errorURL: .failure(NetworkError.failed(URLError.cannotLoadFromNetwork))
        ]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        // set our network handling back to default.
        Bundler.sessionConfig = URLSessionConfiguration.default
    }
    
    func testAnalyticsJSLeak() throws {
        let ajs = AnalyticsJS()
        ajs.construct(args: ["12345"])
        checkIfLeaked(ajs)
    }
    
    func testEdgeFnMultipleLoad() throws {
        LivePlugins.clearCache()
        
        let analytics = Analytics(configuration: Configuration(writeKey: "1234"))
        analytics.add(plugin: LivePlugins(fallbackFileURL: bundleTestFile(file: "testbundle.js")))
        analytics.add(plugin: LivePlugins(fallbackFileURL: bundleTestFile(file: "testbundle.js")))
        analytics.add(plugin: LivePlugins(fallbackFileURL: bundleTestFile(file: "testbundle.js")))

        waitUntilStarted(analytics: analytics)
        
        let v1 = analytics.find(pluginType: LivePlugins.self)
        analytics.remove(plugin: v1!)
        
        let v2 = analytics.find(pluginType: LivePlugins.self)
        XCTAssertNil(v2)
        
        waitUntilFinished(analytics: analytics)
        checkIfLeaked(analytics)
    }
    
    func testEdgeFnLoad() throws {
        LivePlugins.clearCache()
        
        let analytics = Analytics(configuration: Configuration(writeKey: "1234"))
        analytics.add(plugin: LivePlugins(fallbackFileURL: bundleTestFile(file: "testbundle.js")))
        
        let outputReader = OutputReaderPlugin()
        analytics.add(plugin: outputReader)
        
        waitUntilStarted(analytics: analytics)
        
        analytics.track(name: "blah", properties: nil)
        
        var lastEvent: RawEvent? = nil
        while lastEvent == nil {
            RunLoop.main.run(until: Date.distantPast)
            lastEvent = outputReader.lastEvent
        }
        
        let msg: String? = lastEvent?.context?[keyPath: "livePluginMessage"]!
        XCTAssertEqual(msg, "This came from a LivePlugin")
        
        waitUntilFinished(analytics: analytics)
    }
    
    func testEventMorphing() throws {
        LivePlugins.clearCache()
        
        let analytics = Analytics(configuration: Configuration(writeKey: "1234"))
        analytics.add(plugin: LivePlugins(fallbackFileURL: bundleTestFile(file: "testbundle.js")))
        
        let outputReader = OutputReaderPlugin()
        analytics.add(plugin: outputReader)
        
        waitUntilStarted(analytics: analytics)
        
        analytics.screen(title: "blah")
        
        print("waiting for events...")
        while outputReader.events.count < 2 {
            RunLoop.main.run(until: Date.distantPast)
        }
        print("events received.")
        
        let trackEvent = outputReader.events[0] as? TrackEvent
        let screenEvent = outputReader.events[1] as? ScreenEvent
        XCTAssertNotNil(screenEvent)
        XCTAssertNotNil(trackEvent)
        XCTAssertEqual(trackEvent!.event, "trackScreen")
    }

    func testCodableToDictionary() throws {
        struct MyTraits: Codable {
            let email: String?,
                isBool: Bool?
        }

        let traits = MyTraits(email: "me@work.com", isBool: true)
        let json = try? JSON(with: traits)
        let dv = json?.dictionaryValue

        // Ensure that BOOL values are preserved
        XCTAssertTrue(dv!["isBool"] as! Bool)
    }

    func testAddRemoveLivePlugins() throws {
        LivePlugins.clearCache()

        let analytics = Analytics(configuration: Configuration(writeKey: "1234"))

        let livePlugin = LivePlugins(fallbackFileURL: bundleTestFile(file: "addliveplugin.js"))

        // The script addliveplugins.js will add a LivePlugin to both the main timeline and the
        // timeline of the Segment destination
        analytics.add(plugin: livePlugin)

        waitUntilStarted(analytics: analytics)

        let lpMain = analytics.find(pluginType: LivePlugin.self)
        let lpDest = analytics.find(key: "Segment.io")?.timeline.find(pluginType: LivePlugin.self)

        XCTAssertNotNil(lpMain)
        XCTAssertNotNil(lpDest)

        livePlugin.engine.evaluate(script: "analytics.removeLivePlugins()")

        let lpMainAfter = analytics.find(pluginType: LivePlugin.self)
        let lpDestAfter = analytics.find(key: "Segment.io")?.timeline.find(pluginType: LivePlugin.self)

        XCTAssertNil(lpMainAfter)
        XCTAssertNil(lpDestAfter)
        
        analytics.remove(plugin: livePlugin)
        
        RunLoop.main.run(until: Date().addingTimeInterval(1))
        
        checkIfLeaked(analytics)
    }
}
