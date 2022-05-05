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

    init(type: PluginType, placement: Int) {
        self.type = type
        
        /* pseudocode
         
         // JS just told us to init ... so we go put ourselves into
         // the timeline.
         
         analytics.add(self)
         
         // we have no way to control placement it looks like?
         
         */
        
    }
}

