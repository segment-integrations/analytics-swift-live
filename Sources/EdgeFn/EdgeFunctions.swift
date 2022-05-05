//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import Segment
import Substrata

/**
 This is the main plugin for the EdgeFunctions feature.
 */
public class EdgeFunctions: UtilityPlugin {
    public let type: PluginType = .utility
    public var analytics: Analytics? = nil
    
    // We only want ONE engine running.
    internal let engine = JSEngine.shared
    
    // We only want ONE instance of EdgeFunctions ever.
    static public let shared = EdgeFunctions()
    
    private init() {}
    
    public func update(settings: Settings, type: UpdateType) {
        guard type == .initial else { return }
        
        /* pseudocode
         
         if settings.has(edgeFn) {
            if version > storedVersion {
                downloadNewOne(url, completion: {
                    loadEdgeFn(localURL)
                })
            } else {
                loadEdgeFn(localURL)
            }
         }
         
         */
    }
    
}

extension EdgeFunctions {
    internal func loadEdgeFn(url: URL) {
        /* pseudocode
         
         engine.errorHandler = { print(error) }
         
         /* need to expose ...
            - EdgeFnClass
            - AnalyticsClass
          
            need to set ...
            - analytics = self.analytics
          */
         
         engine.loadBundle(url) {
            // go make all the mini plugins ...
         
            // Q: how do we find the names of the classes in the js?
            // A: when JS creates an instance of the exposed EdgeFn class
            //    we'll know about it through the EdgeFn init.
         }
         
         */
    }
    
    
}

