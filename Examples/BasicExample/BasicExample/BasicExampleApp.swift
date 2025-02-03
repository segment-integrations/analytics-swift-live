//
//  BasicExampleApp.swift
//  BasicExample
//
//  Created by Brandon Sneed on 9/26/24.
//

import SwiftUI
import Segment
import AnalyticsLive

extension Analytics {
    static var main = Analytics(configuration: Configuration(writeKey: "<YOUR WRITE KEY>")
        .flushAt(3)
        .trackApplicationLifecycleEvents(true))
}

@main
struct BasicExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        // Set up fallback javascript file to use in case it can't be retrieved from the server and no cached version is available.
        // This javascript file will set up any javascript based plugins or enrichments to process events
        // as they come through the system.
        let fallbackURL: URL? = Bundle.main.url(forResource: "myFallback", withExtension: "js")
        
        // add the Analytics Live plugin to the timeline.
        let lp = LivePlugins(fallbackFileURL: fallbackURL)
        Analytics.main.add(plugin: lp)
        
        // add destination filters if desired ...
        let filters = DestinationFilters()
        Analytics.main.add(plugin: filters)
        
        // configure and add the Signals plugin if in use ...
        let config = SignalsConfiguration(
            writeKey: "<YOUR WRITE KEY>", // this is your segment writeKey.
            //relayCount: 1, // lets us see signals quickly ... , the default is 20.
            //broadcasters: [SegmentBroadcaster(), DebugBroadcaster()], // see console output.  Default is just SegmentBroadcaster.
            useSwiftUIAutoSignal: true, // automatically forward swiftUI control interaction signals to your event generators.
            useNetworkAutoSignal: true) // automatically forward network req/recv signals to your event generators.
        
        Signals.shared.useConfiguration(config)
        Analytics.main.add(plugin: Signals.shared)
    }
}

