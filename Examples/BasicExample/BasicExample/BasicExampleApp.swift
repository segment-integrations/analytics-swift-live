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
    static var main = Analytics(configuration: Configuration(writeKey: "<YOUR_WRITE_KEY>")
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
        // Set up fallback javascript file to use in case it can't be retrieved from the server.
        // This javascript file will set up any javascript based plugins or enrichments to process events
        // as they come through the system.
        let fallbackURL: URL? = Bundle.main.url(forResource: "myFallback", withExtension: "js")
        
        // add the Analytics Live plugin to the timeline.
        Analytics.main.add(plugin: LivePlugins(fallbackFileURL: fallbackURL))
    }
}

