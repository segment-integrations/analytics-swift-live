//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import XCTest
import Segment
import Substrata
@testable import EdgeFn

func waitUntilStarted() {
    RunLoop.main.run(until: Date.init(timeIntervalSinceNow: 2))
}

class EdgeFnTests: XCTestCase {
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
    
    func testEdgeFnLoad() throws {
        let analytics = Analytics(configuration: Configuration(writeKey: "1234"))
        analytics.add(plugin: EdgeFunctions(fallbackFileURL: bundleTestFile(file: "testbundle.js")))
        
        let outputReader = OutputReaderPlugin()
        analytics.add(plugin: outputReader)
        
        waitUntilStarted()
        
        analytics.track(name: "blah", properties: nil)
        
        var lastEvent: RawEvent? = nil
        while lastEvent == nil {
            RunLoop.main.run(until: Date.distantPast)
            lastEvent = outputReader.lastEvent
        }
        
        print(lastEvent)
    }
}
