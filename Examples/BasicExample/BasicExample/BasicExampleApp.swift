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
    static var main = Analytics(configuration: Configuration(writeKey: "A1doKZCHoIx0XuwDJIdgnkTGU3ohndvh")
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
        
        // configure and add the Signals plugin if desired ...
        let config = Signals.Configuration(
            writeKey: "1234", // this is your segment writeKey.
            useSwiftUIAutoSignal: true, // automatically forward swiftUI control interaction signals to your event generators.
            useNetworkAutoSignal: true) // automatically forward network req/recv signals to your event generators.
        // tell the Signals singleton to use the config above.
        Signals.shared.useConfiguration(config)
        
        Analytics.main.add(plugin: Signals.shared)
    }
}

