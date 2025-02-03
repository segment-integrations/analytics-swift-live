//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/16/24.
//

import Foundation
import Segment

public class WebhookBroadcaster: SignalBroadcaster {
    public weak var analytics: Analytics? = nil
    
    @Atomic internal var recordedSignals = [any RawSignal]()
    internal let webhookURL: URL
    
    public init(url: URL) {
        self.webhookURL = url
    }
    
    public func added(signal: any RawSignal) {
        var signal = signal
        if let obf = signal as? JSONObfuscation {
            signal = obf.obfuscated()
        }
        _recordedSignals.mutate { rs in
            rs.append(signal)
        }
    }
    
    public func relay() {
        // copy the buffer for relay
        let currentRecordings = recordedSignals
        // clear the buffer
        _recordedSignals.mutate { rs in
            rs.removeAll()
        }
        
        if currentRecordings.isEmpty { return }
        
        // make our json
        let j = JSON.array(currentRecordings.map({ wrapped in
            try! JSON(with: wrapped)
        }))
        
        guard let jsonData = try? JSONEncoder().encode(j) else { return }
        
        var request = URLRequest(url: webhookURL, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // do nothing ...
        }
        
        task.resume()
    }
}
