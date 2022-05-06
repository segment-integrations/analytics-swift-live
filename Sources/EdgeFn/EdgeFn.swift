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
 EdgeFn is the wrapper class that will end up calling into
 the JS for a given EdgeFn.
 */
internal class EdgeFn: EventPlugin {
    let type: PluginType
    var analytics: Analytics? = nil
    
    let engine = JSEngine.shared
    
    var destination: String? = nil
    
    var jsPlugin: JSEdgeFn

    init(jsPlugin: JSEdgeFn, type: PluginType, destination: String? = nil) {
        self.jsPlugin = jsPlugin
        self.type = type
        self.destination = destination
        
        /* pseudocode
         
         // JS just told us to init ... so we go put ourselves into
         // the timeline.
         
         analytics.add(self)
         
         */
        
    }
    
    func update(settings: Settings, type: UpdateType) {
        //jsPlugin.update(settings)
    }
}

