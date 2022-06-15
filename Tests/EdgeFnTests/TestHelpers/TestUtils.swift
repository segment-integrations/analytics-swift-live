//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/9/22.
//

import Foundation
import Segment

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
        lastEvent = event
        if let t = lastEvent as? TrackEvent {
            events.append(t)
            print("EVENT: \(t.event)")
        }
        return event
    }
}
