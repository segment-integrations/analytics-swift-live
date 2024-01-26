//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import Segment
import Substrata

/*
@objc
public protocol JSAnalyticsExports: JSExport {
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
    func removeLivePlugins()
}
*/

public class AnalyticsJS: JavascriptClass, JSConvertible {
    public static var className = "Analytics"
    
    public static var staticProperties = [String: JavascriptProperty]()
    public static var staticMethods = [String: JavascriptMethod]()
    
    public var instanceProperties: [String : JavascriptProperty] = [
        "traits": JavascriptProperty(get: { weakSelf, this in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            return self.analytics?.traits()
        }),
        "userId": JavascriptProperty(get: { weakSelf, this in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            return self.analytics?.userId
        }),
        "anonymousId": JavascriptProperty(get: { weakSelf, this in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            return self.analytics?.anonymousId
        })
    ]
    
    public var instanceMethods: [String : JavascriptMethod] = [
        "track": JavascriptMethod { weakSelf, this, params in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            guard let name = params[0]?.typed(String.self) else { return nil }
            let properties = params[1]?.typed([String: JSConvertible].self)
            self.analytics?.track(name: name, properties: properties)
            return nil
        },
        "identify": JavascriptMethod { weakSelf, this, params in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            guard let userId = params[0]?.typed(String.self) else { return nil }
            let traits = params[1]?.typed([String: JSConvertible].self)
            self.analytics?.identify(userId: userId, traits: traits)
            return nil
        },
        "screen": JavascriptMethod { weakSelf, this, params in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            guard let title = params[0]?.typed(String.self) else { return nil }
            let category = params[1]?.typed(String.self)
            let properties = params[2]?.typed([String: JSConvertible].self)
            self.analytics?.screen(title: title, category: category, properties: properties)
            return nil
        },
        "group": JavascriptMethod { weakSelf, this, params in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            guard let groupId = params[0]?.typed(String.self) else { return nil }
            let traits = params[1]?.typed([String: JSConvertible].self)
            self.analytics?.group(groupId: groupId, traits: traits)
            return nil
        },
        "alias": JavascriptMethod { weakSelf, this, params in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            guard let newId = params[0]?.typed(String.self) else { return nil }
            self.analytics?.alias(newId: newId)
            return nil
        },
        "flush": JavascriptMethod { weakSelf, this, params in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            self.analytics?.flush()
            return nil
        },
        "reset": JavascriptMethod { weakSelf, this, params in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            self.analytics?.reset()
            return nil
        },
        "add": JavascriptMethod { weakSelf, this, params in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            guard let this = this else { return nil }
            guard let param = params[0] as? JavascriptValue else { return nil }
            guard let plugin = param.value as? JSObject else { return nil }
            let added = self.add(plugin)
            return added
        },
        "removeLivePlugins": JavascriptMethod { weakSelf, this, params in
            guard let self = weakSelf as? AnalyticsJS else { return nil }
            self.removeLivePlugins()
            return nil
        }
    ]
    
    public required init(context: JSContext, params: JSConvertible?...) throws {
        guard let writeKey = params[0]?.typed(String.self) else { throw "No write key was supplied." }
        self.analytics = Analytics(configuration: Configuration(writeKey: writeKey))
    }
    
    internal var analytics: Analytics? = nil
    internal var engine: JSEngine? = nil
    internal var addedPlugins: Array<LivePlugin> = Array()
    
    public init(wrapping analytics: Analytics?, engine: JSEngine) {
        self.analytics = analytics
        self.engine = engine
    }
    
    internal func removeLivePlugins() {
        guard let analytics = analytics else { return }

        DispatchQueue.main.async {
            for p in self.addedPlugins {
                analytics.remove(plugin: p)
            }
        }
        self.addedPlugins = Array()
    }

    internal func add(_ plugin: JSObject) -> Bool {
        var result = false
        guard let engine = engine else { return result }
        guard let analytics = analytics else { return result }
        
        let type = plugin["type"].value(Int.self)
        let destination = plugin["destination"].value(String.self)
        
        guard let type = type else { return result }
        
        guard let pluginType = PluginType(rawValue: type) else { return result }
        let edgeFn = LivePlugin(jsPlugin: plugin, type: pluginType, engine: engine)
        
        if let dest = destination {
            // we have a destination specified, so add it there
            if let d = analytics.find(key: dest) {
                DispatchQueue.main.async {
                    _ = d.add(plugin: edgeFn)
                }
                result = true
                self.addedPlugins.append(edgeFn)
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
