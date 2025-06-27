//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/15/24.
//

import Foundation


public struct SignalsConfiguration {
    static public let allowAllHosts = "*"
    static public let autoBlockedHosts = [
        "api.segment.com",
        "cdn-settings.segment.com",
        "signals.segment.com",
        "api.segment.build",
        "cdn.segment.build",
        "signals.segment.build",
    ]
    
    internal let writeKey: String
    internal let maximumBufferSize: Int
    internal let relayCount: Int
    internal let relayInterval: TimeInterval
    internal var broadcasters: [SignalBroadcaster]
    internal let sendDebugSignalsToSegment: Bool
    internal let obfuscateDebugSignals: Bool
    internal let useUIKitAutoSignal: Bool
    internal let useSwiftUIAutoSignal: Bool
    internal let useNetworkAutoSignal: Bool
    internal let allowedNetworkHosts: [String]
    internal let blockedNetworkHosts: [String]
    
    public init(
        writeKey: String,
        maximumBufferSize: Int = 1000,
        relayCount: Int = 20,
        relayInterval: TimeInterval = 60,
        broadcasters: [SignalBroadcaster] = [],
        sendDebugSignalsToSegment: Bool = false,
        obfuscateDebugSignals: Bool = true,
        useUIKitAutoSignal: Bool = false,
        useSwiftUIAutoSignal: Bool = false,
        useNetworkAutoSignal: Bool = false,
        allowedNetworkHosts: [String] = [Self.allowAllHosts],
        blockedNetworkHosts: [String] = []
    ) {
        self.writeKey = writeKey
        self.maximumBufferSize = maximumBufferSize
        self.relayCount = relayCount
        self.relayInterval = relayInterval
        self.broadcasters = broadcasters
        self.sendDebugSignalsToSegment = sendDebugSignalsToSegment
        self.obfuscateDebugSignals = obfuscateDebugSignals
        self.useUIKitAutoSignal = useUIKitAutoSignal
        self.useSwiftUIAutoSignal = useSwiftUIAutoSignal
        self.useNetworkAutoSignal = useNetworkAutoSignal
        self.allowedNetworkHosts = allowedNetworkHosts
        
        if !self.broadcasters.contains(where: { $0 is SegmentBroadcaster }) {
            if self.sendDebugSignalsToSegment {
                let seg = SegmentBroadcaster(
                    sendToSegment: self.sendDebugSignalsToSegment,
                    obfuscate: self.obfuscateDebugSignals
                )
                self.broadcasters.append(seg)
            }
        }
        
        var blocked = blockedNetworkHosts + Self.autoBlockedHosts
        // block the webhook if it's in use
        for b in self.broadcasters {
            if let webhook = b as? WebhookBroadcaster, let host = webhook.webhookURL.host() {
                blocked.append(host)
            }
        }
        
        self.blockedNetworkHosts = blocked
    }
}

