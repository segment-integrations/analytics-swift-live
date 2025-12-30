//
//  AppDelegate.swift
//  UIKitNavExample
//
//  Created by Brandon Sneed on 12/30/25.
//

import UIKit
import Segment
import AnalyticsLive

extension Analytics {
    static var main = Analytics(configuration: Configuration(writeKey: "<YOUR WRITE KEY>")
        .flushAt(3)
        .setTrackedApplicationLifecycleEvents(.all))
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // add the Analytics Live plugin to the timeline.
        let lp = LivePlugins(fallbackFileURL: nil)
        Analytics.main.add(plugin: lp)
        
        // add destination filters if desired ...
        let filters = DestinationFilters()
        Analytics.main.add(plugin: filters)
        
        // configure and add the Signals plugin if in use ...
        let config = SignalsConfiguration(
            writeKey: "<YOUR WRITE KEY>",
            //broadcasters: [DebugBroadcaster()],
            useUIKitAutoSignal: true,
            useNetworkAutoSignal: true)
        
        Signals.shared.useConfiguration(config)
        Analytics.main.add(plugin: Signals.shared)
        
        // Enable debug logging for navigation observer
        NavigationObserver.shared.debugLogging = true
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
