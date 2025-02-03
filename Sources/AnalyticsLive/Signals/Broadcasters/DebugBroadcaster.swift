//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/27/24.
//

import Foundation
import Segment

public class DebugBroadcaster: SignalJSONBroadcaster {
    public weak var analytics: Analytics? = nil
    
    public var signals = [any RawSignal]()
    public var last: (any RawSignal)? {
        return signals.last
    }
    
    public func added(signal: [String : Any]) {
        signals_emit_log(signal)
    }
    
    public func added(signal: any RawSignal) {
        signals.append(signal)
    }
    
    public func relay() {
        signals.removeAll()
    }
    
    public init() {}
}
