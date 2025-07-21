import XCTest
import Segment
@testable import AnalyticsLive

class MockBroadcaster: SignalBroadcaster {
    var analytics: Analytics?
    var relayCallCount = 0
    var addedSignals: [any RawSignal] = []
    
    func added(signal: any RawSignal) {
        addedSignals.append(signal)
    }
    
    func relay() {
        relayCallCount += 1
    }
}

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
        
        waitForExpectations(timeout: 5)
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
        
        waitForExpectations(timeout: 5)
    }
    
    func testCounterRelayOnCount() throws {
        // Reset shared instance to clean state
        Signals.shared.reset()
        
        let mockBroadcaster = MockBroadcaster()
        
        // Set up test configuration with low relay count
        let config = SignalsConfiguration(
            writeKey: "test",
            maximumBufferSize: 1000,  // High so it doesn't trigger
            relayCount: 3,            // Trigger after 3 signals
            broadcasters: [mockBroadcaster]
        )
        
        // Configure the shared instance
        Signals.shared.useConfiguration(config)
        
        // Set ready state to bypass queueing
        Signals.shared.setReady(true)
        
        // Emit 2 signals - should not trigger relay
        Signals.emit(signal: InteractionSignal(component: "button", title: "Test Button 1"))
        Signals.emit(signal: InteractionSignal(component: "button", title: "Test Button 2"))
        
        XCTAssertEqual(mockBroadcaster.relayCallCount, 0, "Should not relay before threshold")
        XCTAssertEqual(mockBroadcaster.addedSignals.count, 2, "Should have added 2 signals")
        
        // Emit 3rd signal - should trigger relay
        Signals.emit(signal: InteractionSignal(component: "button", title: "Test Button 3"))
        
        XCTAssertEqual(mockBroadcaster.relayCallCount, 1, "Should relay after hitting count threshold")
        XCTAssertEqual(mockBroadcaster.addedSignals.count, 3, "Should have added 3 signals")
        
        // Emit another signal - counter should have reset, no relay yet
        Signals.emit(signal: InteractionSignal(component: "button", title: "Test Button 4"))
        
        XCTAssertEqual(mockBroadcaster.relayCallCount, 1, "Should still be 1 relay (counter reset)")
        XCTAssertEqual(mockBroadcaster.addedSignals.count, 4, "Should have added 4 signals")
    }

    func testCounterRelayOnBufferSize() throws {
        Signals.shared.reset()
        
        let mockBroadcaster = MockBroadcaster()
        
        // Set up test configuration with low buffer size
        let config = SignalsConfiguration(
            writeKey: "test",
            maximumBufferSize: 2,     // Trigger after 2 signals
            relayCount: 1000,         // High so it doesn't trigger
            broadcasters: [mockBroadcaster]
        )
        
        Signals.shared.useConfiguration(config)
        Signals.shared.setReady(true)
        
        // Emit 1 signal - should not trigger
        Signals.emit(signal: InteractionSignal(component: "button", title: "Test Button 1"))
        XCTAssertEqual(mockBroadcaster.relayCallCount, 0)
        
        // Emit 2nd signal - should not trigger (> threshold, not >=)
        Signals.emit(signal: InteractionSignal(component: "button", title: "Test Button 2"))
        XCTAssertEqual(mockBroadcaster.relayCallCount, 0)
        
        // Emit 3rd signal - should trigger (counter > maximumBufferSize)
        Signals.emit(signal: InteractionSignal(component: "button", title: "Test Button 3"))
        XCTAssertEqual(mockBroadcaster.relayCallCount, 1, "Should relay when counter exceeds buffer size")
    }
    
    func testSignalQueueing() throws {
        Signals.shared.reset()
        
        let mockBroadcaster = MockBroadcaster()
        
        let config = SignalsConfiguration(
            writeKey: "test",
            broadcasters: [mockBroadcaster]
        )
        
        Signals.shared.useConfiguration(config)
        
        // Keep ready = false to test queueing
        Signals.shared.setReady(false)
        
        // Emit signals while not ready - should be queued, not processed
        Signals.emit(signal: InteractionSignal(component: "button", title: "Queued Button 1"))
        Signals.emit(signal: NavigationSignal(currentScreen: "Queued Screen", previousScreen: "Root"))
        Signals.emit(signal: InteractionSignal(component: "link", title: "Queued Link"))
        
        // Verify no signals reached the broadcaster yet
        XCTAssertEqual(mockBroadcaster.addedSignals.count, 0, "No signals should be processed while not ready")
        XCTAssertEqual(mockBroadcaster.relayCallCount, 0, "No relay should happen while not ready")
        
        // Verify signals are actually queued
        let queuedCount = Signals.shared.queuedSignalsCount() // You'll need to add this method
        XCTAssertEqual(queuedCount, 3, "Should have 3 queued signals")
    }

    func testSignalReplay() throws {
        Signals.shared.reset()
        
        let mockBroadcaster = MockBroadcaster()
        
        let config = SignalsConfiguration(
            writeKey: "test",
            broadcasters: [mockBroadcaster]
        )
        
        Signals.shared.useConfiguration(config)
        
        // Queue some signals while not ready
        Signals.shared.setReady(false)
        Signals.emit(signal: InteractionSignal(component: "button", title: "Queued Button 1"))
        Signals.emit(signal: InteractionSignal(component: "button", title: "Queued Button 2"))
        
        // Verify they're queued
        XCTAssertEqual(Signals.shared.queuedSignalsCount(), 2)
        XCTAssertEqual(mockBroadcaster.addedSignals.count, 0)
        
        // Now set ready = true and trigger replay
        Signals.shared.setReady(true)
        
        // Manually trigger replay to test the logic
        Signals.shared.replayQueuedSignals()
        
        // Verify queued signals were replayed
        XCTAssertEqual(mockBroadcaster.addedSignals.count, 2, "Both queued signals should be replayed")
        XCTAssertEqual(Signals.shared.queuedSignalsCount(), 0, "Queue should be empty after replay")
    }
    
    // Add this to your SignalsTests.swift file

    func testFullStackSignalProcessingWithCustomJS() throws {
        LivePlugins.clearCache()
        
        // Get our custom JS files
        guard let myEdgeFunctionsJS = bundleTestFile(file: "MyEdgeFunctions.js"),
              let testBundleJS = bundleTestFile(file: "testbundle.js") else {
            XCTFail("Could not find test JS files")
            return
        }
        
        // Set up analytics with output reader to capture generated events
        let config = Configuration(writeKey: "integration_test")
            .flushInterval(999999999)
            .flushAt(99999999)
            .setTrackedApplicationLifecycleEvents(.none)
        let analytics = Analytics(configuration: config)
        
        let outputReader = OutputReaderPlugin()
        analytics.add(plugin: outputReader)
        
        // Create LivePlugins with our custom JS and strict error handling
        let livePlugins = LivePlugins(
            fallbackFileURL: nil,  // No fallback needed for this test
            force: false,
            exceptionHandler: { error in
                XCTFail("JS Error detected: \(error.string)")
            },
            localJSURLs: [myEdgeFunctionsJS, testBundleJS]
        )
        
        // Set up signals with mock broadcaster to capture signals
        let mockBroadcaster = MockBroadcaster()
        let signalsConfig = SignalsConfiguration(
            writeKey: "integration_test",
            maximumBufferSize: 1000,
            broadcasters: [mockBroadcaster]
        )
        
        // Wire up the system
        analytics.add(plugin: livePlugins)
        analytics.add(plugin: Signals.shared)
        Signals.shared.useConfiguration(signalsConfig)
        
        // Wait for everything to be ready
        analytics.waitUntilStarted()
        
        // Give JS engine a moment to load our custom files
        Thread.sleep(forTimeInterval: 1.0)
        
        // Test 1: Navigation signal should trigger screenCall() -> analytics.screen()
        let navigationSignal = NavigationSignal(currentScreen: "Test Screen", previousScreen: "Root")
        Signals.emit(signal: navigationSignal)
        
        // Wait for the signal to be processed and event generated
        var screenEvent: RawEvent? = nil
        let startTime = Date()
        while screenEvent == nil && Date().timeIntervalSince(startTime) < 5.0 {
            RunLoop.main.run(until: Date.distantPast)
            if let lastEvent = outputReader.lastEvent, lastEvent.type == "screen" {
                screenEvent = lastEvent
            }
        }
        
        XCTAssertNotNil(screenEvent, "Navigation signal should have generated a screen event")
        if let screenEvent = screenEvent {
            XCTAssertEqual(screenEvent.type, "screen")
            print("Generated screen event: \(screenEvent.prettyPrint())")
        }
        
        // Test 2: Interaction signal should trigger trackAddToCart() -> analytics.track()
        // needs network signal with product data
        let body: [String: Any] = [
            "data": ["id": "1", "title": "Test Product", "price": 10.0]
        ]
        let networkData = NetworkSignal.NetworkData(action: .response, url: URL(string: "https://example.com/proudcts/1"), body: body, contentType: "application/json", method: nil, status: 200, requestId: "1234")
        let networkSignal = NetworkSignal(data: networkData)
        
        let interactionSignal = InteractionSignal(component: "button", title: "Add to cart")
        Signals.emit(signal: interactionSignal)
        
        // Wait for the track event
        var trackEvent: TrackEvent? = nil
        let trackStartTime = Date()
        while trackEvent == nil && Date().timeIntervalSince(trackStartTime) < 5.0 {
            RunLoop.main.run(until: Date.distantPast)
            if let lastEvent = outputReader.lastEvent as? TrackEvent {
                if lastEvent.event == "Add to cart" {
                    trackEvent = lastEvent
                }
            }
        }
        
        XCTAssertNotNil(trackEvent, "Interaction signal should have generated a track event")
        if let trackEvent = trackEvent {
            XCTAssertEqual(trackEvent.event, "Add to cart")
            print("Generated track event: \(trackEvent.prettyPrint())")
        }
        
        // Verify signals were captured by the broadcaster
        XCTAssertGreaterThanOrEqual(mockBroadcaster.addedSignals.count, 2,
                                   "Should have captured at least 2 signals")
        
        // Verify signal types
        let signalTypes = mockBroadcaster.addedSignals.map { $0.type }
        XCTAssertTrue(signalTypes.contains(.navigation), "Should have captured navigation signal")
        XCTAssertTrue(signalTypes.contains(.interaction), "Should have captured interaction signal")
        
        print("Test completed successfully! Captured \(mockBroadcaster.addedSignals.count) signals")
    }

    func testJSErrorHandling() throws {
        LivePlugins.clearCache()
        
        // Get our intentionally broken JS file from the bundle
        guard let badJSFile = bundleTestFile(file: "badtest.js") else {
            XCTFail("Could not find badtest.js file")
            return
        }
        
        let analytics = Analytics(configuration: Configuration(writeKey: "error_test"))
        
        let errorExpectation = self.expectation(description: "JS error caught")
        
        // This should trigger our error handler
        let livePlugins = LivePlugins(
            fallbackFileURL: nil,
            force: false,
            exceptionHandler: { error in
                print("Caught expected JS error: \(error.string)")
                XCTAssertTrue(error.string.contains("thisFunctionDoesNotExist") ||
                             error.string.contains("not defined") ||
                             error.string.contains("ReferenceError"),
                             "Error should mention the missing function or reference error")
                errorExpectation.fulfill()
            },
            localJSURLs: [badJSFile]
        )
        
        analytics.add(plugin: livePlugins)
        analytics.waitUntilStarted()
        
        // Give time for JS to load and error
        waitForExpectations(timeout: 5)
    }
}
