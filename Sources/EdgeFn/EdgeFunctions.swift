//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import Segment
import Substrata

public typealias JSObject = [String: Any]

/**
 This is the main plugin for the EdgeFunctions feature.
 */
public class EdgeFunctions: UtilityPlugin {
    public let type: PluginType = .utility
    
    public var analytics: Analytics? = nil {
        didSet {
            if analytics?.find(pluginType: EdgeFunctions.self) != nil {
                fatalError("Can't have more than one instance of EdgeFunctions on Analytics.")
            }
        }
    }
    
    internal let engine = JSEngine()
    
    public init() { }
    
    public func update(settings: Settings, type: UpdateType) {
        guard type == .initial else { return }
        
        let fileURL = URL(fileURLWithPath: "/Users/brandonsneed/work/EdgeFn-Swift/Tests/EdgeFnTests/ExampleEdgeFn.js")
        loadEdgeFn(url: fileURL)
        
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
          
            need to setup an enum-like thing representing
            the possible plugin types
          */
         
         engine.loadBundle(url) {
            // go make all the mini plugins ...
         
            // Q: how do we find the names of the classes in the js?
            // A: when JS creates an instance of the exposed EdgeFn class
            //    we'll know about it through the EdgeFn init.
         }
         
         */
        
        // setup error handler
        engine.errorHandler = { error in
            print(error)
        }
        
        // expose our classes
        engine.expose(classType: JSAnalytics.self, name: "Analytics")
        engine.expose(classType: JSEdgeFn.self, name: "EdgeFn")
        
        // set the system analytics object.
        engine.setObject(key: "analytics", value: JSAnalytics(wrapping: self.analytics))
        
        // setup our enum for plugin types.
        engine.execute(script: """
        const EdgeFnType = {
          before: \(PluginType.before.rawValue),
          enrichment: \(PluginType.enrichment.rawValue),
          after: \(PluginType.after.rawValue),
          utility: \(PluginType.before.rawValue)
        };
        """)
        
        engine.loadBundle(url: url) { error in
            if case let .evaluationError(e) = error {
                if let e = e {
                    print(String(describing: e as Any))
                }
            }
        }

    }
    
    
}

