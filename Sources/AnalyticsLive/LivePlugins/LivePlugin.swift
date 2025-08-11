//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import Substrata
import Segment

extension UpdateType {
    var stringValue: String {
        switch self {
        case .initial:
            return "Initial"
        case .refresh:
            return "Refresh"
        }
    }
}

/**
 LivePlugin is the wrapper class that will end up calling into
 the JS for a given LivePlugin.
 */
public class LivePlugin: EventPlugin {
    public var key: String = "JSLivePlugin"
    
    public let type: PluginType
    public weak var analytics: Analytics? = nil
    
    let jsPlugin: JSClass
    
    init(jsPlugin: JSClass, type: PluginType) {
        self.jsPlugin = jsPlugin
        self.type = type
    }
    
    public func configure(analytics: Analytics) {
        self.analytics = analytics
    }
    
    public func update(settings: Settings, type: UpdateType) {
        guard let dict = toDictionary(settings)?.toJSConvertible() else { return }
        jsPlugin.call(method: "update", args: [dict, type.stringValue])
    }
    
    public func execute<T: RawEvent>(event: T?) -> T? {
        guard let dict = toDictionary(event)?.toJSConvertible() else { return nil }
                
        var result = event
        let modified = jsPlugin.call(method: "execute", args: [dict])?.typed(as: Dictionary.self)
        
        if let newEvent = modified {
            result = T(fromDictionary: newEvent)
        } else {
            result = nil
        }
        
        return result
    }
}

