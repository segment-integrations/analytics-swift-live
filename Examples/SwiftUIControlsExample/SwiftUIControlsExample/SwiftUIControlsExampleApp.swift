//
//  SwiftUIControlsExampleApp.swift
//  SwiftUIControlsExample
//
//  Created by Brandon Sneed on 12/30/25.
//

import SwiftUI
import Segment
import AnalyticsLive

extension Analytics {
    static var main = Analytics(configuration: Configuration(writeKey: "<YOUR WRITE KEY>")
        .flushAt(3)
        .setTrackedApplicationLifecycleEvents(.all))
}

@main
struct SwiftUIControlsExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        // add the Analytics Live plugin to the timeline.
        let lp = LivePlugins(fallbackFileURL: nil)
        Analytics.main.add(plugin: lp)
        
        // add destination filters if desired ...
        let filters = DestinationFilters()
        Analytics.main.add(plugin: filters)
        
        // configure and add the Signals plugin if in use ...
        let config = SignalsConfiguration(
            writeKey: "<YOUR WRITE KEY>", // this is your segment writeKey.
            relayCount: 1, // lets us see signals quickly ... , the default is 20.
            broadcasters: [DebugBroadcaster()], // see console output.  Default is just SegmentBroadcaster.
            useUIKitAutoSignal: true, // automatically forward UIKit interaction signals to your event generators.
            useSwiftUIAutoSignal: true, // automatically forward SwiftUI control interaction signals to your event generators.
            useNetworkAutoSignal: true) // automatically forward network req/recv signals to your event generators.
        
        Signals.shared.useConfiguration(config)
        Analytics.main.add(plugin: Signals.shared)
        
        // Enable debug logging for navigation observer
        NavigationObserver.shared.debugLogging = true
    }
}
