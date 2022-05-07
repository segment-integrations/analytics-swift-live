//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import JavaScriptCore
import Segment
import Substrata

@objc
internal protocol JSAnalyticsExports: JSExport {
    var anonymousId: String? { get }
    var userId: String? { get }
    var traits: JSObject? { get }
    
    init(writeKey: String)
    func track(_ event: String, _ properties: JSObject)
    func identify(_ userId: String, _ traits: JSObject)
    func screen(_ title: String, _ category: String, _ properties: JSObject)
    func group(_ groupId: String, _ traits: JSObject)
    func alias(_ newId: String)
    
    func flush()
    func reset()
    
    func add(_ plugin: JSValue) -> Bool
}

@objc
internal class JSAnalytics: NSObject, JSAnalyticsExports, JSConvertible {
    internal var analytics: Analytics? = nil
    internal var engine: JSEngine? = nil
    
    var anonymousId: String? {
        return analytics?.anonymousId
    }
    var userId: String? {
        return analytics?.userId
    }
    var traits: JSObject? {
        // TODO: can't access state from here to get the dictionary version.
        return nil
    }
    
    required init(writeKey: String) {
        self.analytics = Analytics(configuration: Configuration(writeKey: writeKey))
    }
    
    init(wrapping analytics: Analytics?, engine: JSEngine) {
        self.analytics = analytics
        self.engine = engine
    }
    
    func track(_ event: String, _ properties: JSObject) {
        analytics?.track(name: event, properties: properties)
    }
    
    func identify(_ userId: String, _ traits: JSObject) {
        analytics?.identify(userId: userId, traits: traits)
    }
    
    func screen(_ title: String, _ category: String, _ properties: JSObject) {
        analytics?.screen(title: title, category: category, properties: properties)
    }
    
    func group(_ groupId: String, _ traits: JSObject) {
        analytics?.group(groupId: groupId, traits: traits)
    }
    
    func alias(_ newId: String) {
        analytics?.alias(newId: newId)
    }
    
    func flush() {
        analytics?.flush()
    }
    
    func reset() {
        analytics?.reset()
    }
    
    func add(_ plugin: JSValue) -> Bool {
        var result = false
        guard let engine = engine else { return result }
        guard let analytics = analytics else { return result }
        
        let type = plugin.objectForKeyedSubscript("type").typedObject as? Int
        let destination = plugin.objectForKeyedSubscript("destination").typedObject as? String
        
        guard let type = type else { return result }
        
        guard let pluginType = PluginType(rawValue: type) else { return result }
        let edgeFn = EdgeFn(jsPlugin: plugin, type: pluginType, engine: engine)
        
        if let dest = destination {
            // we have a destination specified, so add it there
            if let d = analytics.find(key: dest) {
                DispatchQueue.main.async {
                    _ = d.add(plugin: edgeFn)
                }
                result = true
            }
        } else {
            DispatchQueue.main.async {
                analytics.add(plugin: edgeFn)
            }
            result = true
        }
        return result
    }
}
