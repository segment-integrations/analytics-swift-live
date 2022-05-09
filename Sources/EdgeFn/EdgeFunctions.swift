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
        // setup error handler
        engine.errorHandler = { error in
            // TODO: Make this useful
            print(error)
        }
        
        // expose our classes
        engine.expose(classType: JSAnalytics.self, name: "Analytics")
        
        // set the system analytics object.
        engine.setObject(key: "analytics", value: JSAnalytics(wrapping: self.analytics, engine: engine))
        
        // setup our enum for plugin types.
        engine.execute(script: EmbeddedJS.enumSetupScript)
        engine.execute(script: EmbeddedJS.edgeFnBaseSetupScript)
        
        engine.loadBundle(url: url) { error in
            if case let .evaluationError(e) = error {
                if let e = e {
                    print(String(describing: e as Any))
                }
            }
        }

    }
    
    
}

