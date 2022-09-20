//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/9/22.
//

import Foundation
@testable import Segment

func waitUntilStarted(analytics: Analytics?) {
    guard let analytics = analytics else { return }
    // wait until the startup queue has emptied it's events.
    if let startupQueue = analytics.find(pluginType: StartupQueue.self) {
        while startupQueue.running != true {
            RunLoop.main.run(until: Date.distantPast)
        }
    }
}

enum NetworkError: Error {
    case failed(URLError.Code)
}

func bundleTestFile(file: String) -> URL? {
    let bundle = Bundle.module
    if let pathURL = bundle.url(forResource: file, withExtension: nil) {
        return pathURL
    }
    return nil
}

class OutputReaderPlugin: Plugin {
    let type: PluginType
    var analytics: Analytics?
    
    var events = [RawEvent]()
    var lastEvent: RawEvent? = nil
    
    init() {
        self.type = .after
    }
    
    func execute<T>(event: T?) -> T? where T : RawEvent {
        if let e = event {
            events.append(e)
            lastEvent = e
            print("TYPE: \(String(describing: e.type)), newEventCount = \(events.count)")
        }
        return event
    }
}
