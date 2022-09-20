//
//  AppDelegate.swift
//  EdgeFnExample
//
//  Created by Brandon Sneed on 5/5/22.
//

import UIKit
import Segment
import EdgeFn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var analytics: Analytics? = nil


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let config = Configuration(writeKey: "Sf37SZu7TfysLklHCahTo5HlSP9m9O6h")
            .flushAt(1)
            .trackApplicationLifecycleEvents(true)
        
        analytics = Analytics(configuration: config)
        
        let backupURL = Bundle.main.url(forResource: "defaultEdgeFn.js", withExtension: nil)
        analytics?.add(plugin: EdgeFunctions(fallbackFileURL: backupURL))
        
        
        analytics?.track(name: "howdy doody")
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

