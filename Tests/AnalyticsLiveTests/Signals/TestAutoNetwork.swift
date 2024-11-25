//
//  TestAutoNetwork.swift
//  
//
//  Created by Brandon Sneed on 2/27/24.
//

import XCTest
import Segment
@testable import AnalyticsLive

final class TestAutoNetwork: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /*
    func testNetworkCapture() throws {
        LivePlugins.clearCache()
        
        let debug = DebugBroadcaster()
        
        let analytics = Analytics(configuration: Configuration(writeKey: "TEST"))
        let fallbackURL = bundleTestFile(file: "MyEdgeFunctions.js")
        analytics.add(plugin: LivePlugins(fallbackFileURL: fallbackURL))
        analytics.add(plugin: Signals.shared)
        
        let config = Signals.Configuration(
            writeKey: "1234",
            maximumBufferSize: 1000,
            broadcasters: [debug],
            useNetworkAutoSignal: true
        )
        Signals.shared.useConfiguration(config)
        
        analytics.waitUntilStarted()
        
        // Define the URL string
        let urlString = "https://filesamples.com/samples/code/json/sample1.json"

        // Create a URL object from the string
        if let url = URL(string: urlString) {
            // Create a URLSession object
            //let config = URLSessionConfiguration.default
            //config.protocolClasses?.insert(SignalsNetworkProtocol.self, at: 0)
            let session = URLSession(configuration: .default)
            
            // Create a data task
            let task = session.dataTask(with: url) { (data, response, error) in
            //let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                // Check for errors
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                
                // Check if response is valid
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Invalid response")
                    return
                }
                
                // Check if data is available
                if let jsonData = data {
                    // Convert data to string (optional)
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("JSON Data:")
                        print(jsonString)
                    }
                    // Process your JSON data here
                    // For example, you can parse it using JSONSerialization
                    // Do something with jsonData...
                }
            }
            
            // Resume the task
            task.resume()
        } else {
            print("Invalid URL")
        }
        
        RunLoop.main.run()
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
     */
}
