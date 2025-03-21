import XCTest
@testable import Segment
@testable import AnalyticsLive

final class AnalyticsFilters_SwiftTests: XCTestCase {
    func testFilterJSExecution() throws {
        UserDefaults.standard.removePersistentDomain(forName: "com.segment.storage.filterJS")
        Bundler.deleteLocalBundle(bundleName: LivePlugins.Constants.edgeFunctionFilename)
        
        let expectation = XCTestExpectation(description: "MyDestination Expectation")
        let myDestination = MyDestination {
            expectation.fulfill()
            return true
        }

        var defaults = Settings.load(resource: "filterSettings.json", bundle: Bundle.module)
        if let existing = defaults!.integrations?.dictionaryValue {
            var newIntegrations = existing
            newIntegrations[myDestination.key] = true
            defaults!.integrations = try! JSON(newIntegrations)
        }
        
        let config = Configuration(writeKey: "filterJS").defaultSettings(defaults)
        
        // a simple test to make sure the LivePlugin is actually getting executed.
        let analytics = Analytics(configuration: config)

        // this goes at the front of the chain
        let inputReader = OutputReaderPlugin()
        // and this one at the back
        let outputReader = OutputReaderPlugin()
        
        let filters = DestinationFilters()//Old()
        
        // we want the output reader on the dummy destination plugin
        myDestination.add(plugin: outputReader)
        analytics.add(plugin: myDestination)
        
        analytics.add(plugin: inputReader)
        analytics.add(plugin: filters)
        
        waitUntilStarted(analytics: analytics)
        
        // force a settings check causing the js engine to be rebuilt.
        analytics.checkSettings()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 2))
        
        analytics.track(name: "sampleEvent")
        RunLoop.main.run(until: Date.distantPast)
        let inputEvent: TrackEvent? = inputReader.lastEvent as? TrackEvent
        let outputEvent: TrackEvent? = outputReader.lastEvent as? TrackEvent
        
        let t1 = inputEvent?.context?.dictionaryValue
        let t2 = outputEvent?.context?.dictionaryValue
        
        let r = differences(dict1: t1!, dict2: t2!)
        
        let filterRan = r["filterRan"] as? (Any, Bool)
        let name = r[keyPath: "device.name"] as? (String, Any)
        let id = r[keyPath: "device.id"] as? (String, Any)
        
        XCTAssertNotNil(filterRan?.0 as? NSNull)
        XCTAssertNotNil(name?.0 as? String)
        XCTAssertNotNil(id?.0 as? String)
        
        XCTAssertEqual(filterRan?.1, true)
        XCTAssertNotNil(name?.1 as? NSNull)
        XCTAssertNotNil(id?.1 as? NSNull)
    }
}
