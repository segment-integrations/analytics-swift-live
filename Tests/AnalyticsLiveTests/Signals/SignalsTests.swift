import XCTest
import Segment
@testable import AnalyticsLive

final class TestSignals: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSendToSegment() throws {
        LivePlugins.clearCache()
        
        let config = Configuration(writeKey: "signals_test")
            .flushInterval(999999999)
            .flushAt(99999999)
        let analytics = Analytics(configuration: config)
                                    
        let signalsConfig = SignalsConfiguration(
            writeKey: "signals_test",
            sendDebugSignalsToSegment: true
        )
        
        // set up an observer.
        let expectation = self.expectation(description: "observer called")
        MiniAnalytics.observer = { signal, event in
            print("signal: \(signal.prettyPrint())")
            print("event: \(event.prettyPrint())")
            
            XCTAssertEqual(event.properties.value(forKeyPath: "data.data.customer_name"), "XXXX XXX")
            XCTAssertEqual(event.properties.value(forKeyPath: "data.data.price"), "99.99")
            expectation.fulfill()
        }
        Signals.shared.useConfiguration(signalsConfig)
        analytics.add(plugin: LivePlugins(fallbackFileURL: bundleTestFile(file: "MyEdgeFunctions.js")))
        analytics.add(plugin: Signals.shared)
        
        analytics.waitUntilStarted()
        
        let localData = LocalDataSignal(action: .loaded, identifier: "1234", data: ["price": "19.95", "customer_name": "John Doe"])
        Signals.emit(signal: localData)
        
        waitForExpectations(timeout: 5) { error in
            
        }
    }
    
    func testSendToSegmentUnobfuscated() throws {
        LivePlugins.clearCache()
        
        let config = Configuration(writeKey: "signals_test2")
            .flushInterval(999999999)
            .flushAt(99999999)
        let analytics = Analytics(configuration: config)
                                    
        let signalsConfig = SignalsConfiguration(
            writeKey: "signals_test2",
            sendDebugSignalsToSegment: true,
            obfuscateDebugSignals: false
        )
        
        // set up an observer.
        let expectation = self.expectation(description: "observer called")
        MiniAnalytics.observer = { signal, event in
            print("signal: \(signal.prettyPrint())")
            print("event: \(event.prettyPrint())")
            
            XCTAssertEqual(event.properties.value(forKeyPath: "data.data.customer_name"), "John Doe")
            XCTAssertEqual(event.properties.value(forKeyPath: "data.data.price"), "19.95")
            expectation.fulfill()
        }
        Signals.shared.useConfiguration(signalsConfig)
        analytics.add(plugin: LivePlugins(fallbackFileURL: bundleTestFile(file: "MyEdgeFunctions.js")))
        analytics.add(plugin: Signals.shared)
        
        analytics.waitUntilStarted()
        
        let localData = LocalDataSignal(action: .loaded, identifier: "1234", data: ["price": "19.95", "customer_name": "John Doe"])
        Signals.emit(signal: localData)
        
        waitForExpectations(timeout: 5) { error in
            
        }
    }
}
