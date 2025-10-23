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
    
    /*func testEdgeFnMultipleLoad() throws {
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
    }*/
    
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
    
    func testStorage() throws {
        LivePlugins.clearCache()
        
        let analytics = Analytics(configuration: Configuration(writeKey: "1234"))
        analytics.add(plugin: LivePlugins(fallbackFileURL: bundleTestFile(file: "teststorage.js")))
        
        let outputReader = OutputReaderPlugin()
        analytics.add(plugin: outputReader)
        
        waitUntilStarted(analytics: analytics)
        
        var lastEvent: RawEvent? = nil
        while lastEvent == nil {
            RunLoop.main.run(until: Date.distantPast)
            lastEvent = outputReader.lastEvent
        }
        
        let trackEvent = lastEvent as? TrackEvent
        XCTAssertNotNil(trackEvent)
        
        let properties = (trackEvent?.properties as? JSON)?.dictionaryValue
        XCTAssertNotNil(properties)
        XCTAssertEqual(properties?["testString"] as? String, "someString")
        XCTAssertEqual(properties?["testNumber"] as? Int, 120)
        XCTAssertEqual(properties?["testBool"] as? Bool, true)
        // NOTE: this is going to come back as a string since it's been through JSON conversion.
        XCTAssertEqual(properties?["testDate"] as? String, "2024-05-01T12:00:00.000Z")
        
        let testNull = properties?["testNull"] as? [Any]
        XCTAssertNotNil(testNull)
        XCTAssertEqual(testNull?[0] as? Int, 1)
        XCTAssertTrue(testNull?[1] is NSNull)
        XCTAssertEqual(testNull?[2] as? String, "test")
        
        let dict = properties?["testDict"] as? [String: Any]
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["testString"] as? String, "someString")
        XCTAssertEqual(dict?["testNumber"] as? Int, 120)
        let nestedDict = dict?["testDict"] as? [String: Int]
        XCTAssertEqual(nestedDict?["someValue"], 1)
        
        let array = properties?["testArray"] as? [Any]
        XCTAssertEqual(array?[0] as? Int, 1)
        XCTAssertEqual(array?[1] as? String, "test")
        XCTAssertEqual(array?[2] as? [String: Int], ["blah": 1])
        
        let remove = properties?["remove"] as? [Bool]
        XCTAssertNotNil(remove)
        XCTAssertTrue(remove![0])
        XCTAssertTrue(remove![1])
        XCTAssertTrue(remove![2])
        XCTAssertTrue(remove![3])
        XCTAssertTrue(remove![4])
        XCTAssertTrue(remove![5])
        
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
    
    func testForceFallbackLoadsCorrectly() throws {
        LivePlugins.clearCache()
        
        let analytics = Analytics(configuration: Configuration(writeKey: "1234"))
        
        // Create LivePlugins with forceFallback = true
        let livePlugins = LivePlugins(fallbackFileURL: bundleTestFile(file: "testbundle.js"), force: true)
        analytics.add(plugin: livePlugins)
        
        let outputReader = OutputReaderPlugin()
        analytics.add(plugin: outputReader)
        
        waitUntilStarted(analytics: analytics)
        
        // Send an event to verify the fallback JS is working
        analytics.track(name: "test fallback", properties: nil)
        
        var lastEvent: RawEvent? = nil
        while lastEvent == nil {
            RunLoop.main.run(until: Date.distantPast)
            lastEvent = outputReader.lastEvent
        }
        
        // Verify the fallback file was loaded by checking for the expected message
        let msg: String? = lastEvent?.context?[keyPath: "livePluginMessage"]!
        XCTAssertEqual(msg, "This came from a LivePlugin")
        
        waitUntilFinished(analytics: analytics)
        checkIfLeaked(analytics)
    }

    func testBadSettingsDataTriggersFallback() throws {
        LivePlugins.clearCache()
        
        // Setup mock network to ensure any download attempts fail
        Bundler.sessionConfig = URLSessionConfiguration.ephemeral
        Bundler.sessionConfig.protocolClasses = [URLProtocolMock.self]
        
        // Add the failing URL from badSettings.json to the mock dictionary
        let failingURL = URL(string: "http://this-will-fail-no-mock.com/bundle.js")!
        URLProtocolMock.testURLs = [
            failingURL: .failure(NetworkError.failed(URLError.cannotLoadFromNetwork))
        ]
        
        // Load bad settings from JSON file - this contains an edgeFunction with a URL that will fail
        let badDefaults = Settings.load(resource: "badSettings.json", bundle: Bundle.module)
        
        let config = Configuration(writeKey: "testBadSettings").defaultSettings(badDefaults)
        let analytics = Analytics(configuration: config)
        
        // Add LivePlugins with fallback file
        let livePlugins = LivePlugins(fallbackFileURL: bundleTestFile(file: "testbundle.js"))
        analytics.add(plugin: livePlugins)
        
        let outputReader = OutputReaderPlugin()
        analytics.add(plugin: outputReader)
        
        waitUntilStarted(analytics: analytics)
        
        // Send an event to verify the fallback JS is working
        analytics.track(name: "test bad settings fallback", properties: nil)
        
        var lastEvent: RawEvent? = nil
        while lastEvent == nil {
            RunLoop.main.run(until: Date.distantPast)
            lastEvent = outputReader.lastEvent
        }
        
        // Verify the fallback file was loaded despite the bad settings
        let msg: String? = lastEvent?.context?[keyPath: "livePluginMessage"]!
        XCTAssertEqual(msg, "This came from a LivePlugin")
        
        // Clean up
        Bundler.sessionConfig = URLSessionConfiguration.default
        waitUntilFinished(analytics: analytics)
        checkIfLeaked(analytics)
    }
}
