//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/29/24.
//

import Foundation
import Segment

public class SegmentBroadcaster: SignalBroadcaster {
    internal var sendToSegment: Bool
    internal var obfuscate: Bool
    internal var mini: MiniAnalytics? = nil
    
    public func added(signal: any RawSignal) {
        let s = signal
        if sendToSegment {
            mini?.track(signal: s, obfuscate: obfuscate)
        }
    }
    
    public func relay() {
        if sendToSegment {
            mini?.flush()
        }
    }
    
    public init(sendToSegment: Bool = false, obfuscate: Bool = true, writeKey: String, apiHost: String) {
        self.obfuscate = obfuscate
        self.sendToSegment = sendToSegment
        if sendToSegment {
            self.mini = MiniAnalytics(writeKey: writeKey, apiHost: apiHost)
        }
    }
    
    public func disable() {
        self.obfuscate = true
        self.sendToSegment = false
    }
}
