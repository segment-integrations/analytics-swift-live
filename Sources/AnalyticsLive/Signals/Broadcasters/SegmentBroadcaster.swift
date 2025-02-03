//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/29/24.
//

import Foundation
import Segment

public class SegmentBroadcaster: SignalBroadcaster {
    public weak var analytics: Analytics? = nil {
        didSet {
            #if DEBUG
            guard let analytics else { return }
            self.mini = MiniAnalytics(analytics: analytics)
            #endif
        }
    }
    
    internal var mini: MiniAnalytics? = nil
    
    public func added(signal: any RawSignal) {
        #if DEBUG
        mini?.track(signal: signal)
        #endif
    }
    
    public func relay() {
        #if DEBUG
        mini?.flush()
        #endif
    }
    
    public init() { }
}
