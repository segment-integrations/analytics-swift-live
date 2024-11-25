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
    
    public let writeKey: String
    public let maximumBufferSize: Int
    public let relayCount: Int
    public let relayInterval: TimeInterval
    public let broadcasters: [SignalBroadcaster]?
    public let useUIKitAutoSignal: Bool
    public let useSwiftUIAutoSignal: Bool
    public let useNetworkAutoSignal: Bool
    public let allowedNetworkHosts: [String]
    public let blockedNetworkHosts: [String]
    
    public init(
        writeKey: String,
        maximumBufferSize: Int = 1000,
        relayCount: Int = 20,
        relayInterval: TimeInterval = 60,
        broadcasters: [SignalBroadcaster]? = [SegmentBroadcaster()],
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
        self.useUIKitAutoSignal = useUIKitAutoSignal
        self.useSwiftUIAutoSignal = useSwiftUIAutoSignal
        self.useNetworkAutoSignal = useNetworkAutoSignal
        self.allowedNetworkHosts = allowedNetworkHosts
        
        var blocked = blockedNetworkHosts + Self.autoBlockedHosts
        // block the webhook if it's in use
        if let broadcasters = self.broadcasters {
            for b in broadcasters {
                if let webhook = b as? WebhookBroadcaster, let host = webhook.webhookURL.host() {
                    blocked.append(host)
                }
            }
        }
        self.blockedNetworkHosts = blocked
    }
}

