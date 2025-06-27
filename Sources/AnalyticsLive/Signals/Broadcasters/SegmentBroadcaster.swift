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
            if sendToSegment {
                guard let analytics else { return }
                self.mini = MiniAnalytics(analytics: analytics)
            }
        }
    }
    
    internal let sendToSegment: Bool
    internal let obfuscate: Bool
    internal var mini: MiniAnalytics? = nil
    
    public func added(signal: any RawSignal) {
        var s = signal
        if sendToSegment {
            mini?.track(signal: s, obfuscate: obfuscate)
        }
    }
    
    public func relay() {
        if sendToSegment {
            mini?.flush()
        }
    }
    
    public init(sendToSegment: Bool = false, obfuscate: Bool = true) {
        self.obfuscate = obfuscate
        self.sendToSegment = sendToSegment
    }
}
