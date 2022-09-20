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
 EdgeFn is the wrapper class that will end up calling into
 the JS for a given EdgeFn.
 */
internal class EdgeFn: EventPlugin {
    let type: PluginType
    var analytics: Analytics? = nil
    
    let engine: JSEngine
    let jsPlugin: JSObject
    
    init(jsPlugin: JSObject, type: PluginType, engine: JSEngine) {
        self.jsPlugin = jsPlugin
        self.type = type
        self.engine = engine
    }
    
    func update(settings: Settings, type: UpdateType) {
        guard let dict = settings.asDictionary() else { return }
        engine.syncRunEngine {
            let context = engine.context
            _ = jsPlugin.call(method: "update", params:[dict.jsValue(context: context), true.jsValue(context: context)])
            return nil
        }
    }
    
    func execute<T: RawEvent>(event: T?) -> T? {
        guard let dict = event?.asDictionary() else { return nil }
        
        var result = event
        
        let modified = engine.syncRunEngine {
            let modified = jsPlugin.call(method: "execute", params: [dict.jsValue(context: engine.context)])
            return modified.value([String: Any].self)
        }
        
        if let newEvent = modified as? [String: Any] {
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

