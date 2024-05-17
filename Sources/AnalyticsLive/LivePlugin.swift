//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import Segment
import Substrata
import JavaScriptCore


/**
 LivePlugin is the wrapper class that will end up calling into
 the JS for a given LivePlugin.
 */
internal class LivePlugin: EventPlugin {
    let type: PluginType
    var analytics: Analytics? = nil
    
    let jsPlugin: JSClass
    
    init(jsPlugin: JSClass, type: PluginType) {
        self.jsPlugin = jsPlugin
        self.type = type
    }
    
    func update(settings: Settings, type: UpdateType) {
        guard let dict = toDictionary(settings)?.toJSConvertible() else { return }
        jsPlugin.call(method: "update", args: [dict])
    }
    
    func execute<T: RawEvent>(event: T?) -> T? {
        guard let dict = toDictionary(event)?.toJSConvertible() else { return nil }
        //let dict = adict.toJSConvertible()
                
        var result = event
        let modified = jsPlugin.call(method: "execute", args: [dict])?.typed(as: Dictionary.self)
        
        if let newEvent = modified {
            switch event {
                case is IdentifyEvent:
                    result = IdentifyEvent(fromDictionary: newEvent) as? T
                case is TrackEvent:
                    result = TrackEvent(fromDictionary: newEvent) as? T
                case is ScreenEvent:
                    result = ScreenEvent(fromDictionary: newEvent) as? T
                case is AliasEvent:
                    result = AliasEvent(fromDictionary: newEvent) as? T
                case is GroupEvent:
                    result = GroupEvent(fromDictionary: newEvent) as? T
                default:
                    break
            }
        } else {
            result = nil
        }
        
        return result
    }
}

