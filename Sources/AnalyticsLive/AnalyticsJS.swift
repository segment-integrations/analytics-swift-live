//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import Segment
import Substrata

public class AnalyticsJS: JSExport {
    internal var analytics: Analytics?
    
    internal var addedPlugins = [(String?, LivePlugin)]()
    
    public required init() {
        super.init()
        self.analytics = nil
        setupExports()
    }
    
    public init(wrapping analytics: Analytics) {
        super.init()
        self.analytics = analytics
        setupExports()
    }
    
    internal func setupExports() {
        exportProperty(named: "traits") { [weak self] in
            guard let self else { return nil }
            let traits: [String: Any]? = analytics?.traits()
            return traits as? JSConvertible
        }
        
        exportProperty(named: "userId") { [weak self] in
            guard let self else { return nil }
            return analytics?.userId
        }
        
        exportProperty(named: "anonymousId") { [weak self] in
            guard let self else { return nil }
            return analytics?.anonymousId
        }
        
        exportMethod(named: "track", function: track)
        exportMethod(named: "identify", function: identify)
        exportMethod(named: "screen", function: screen)
        exportMethod(named: "group", function: group)
        exportMethod(named: "alias", function: alias)
        exportMethod(named: "add", function: add)
        exportMethod(named: "flush", function: flush)
        exportMethod(named: "reset", function: reset)
        exportMethod(named: "removeLivePlugins", function: removeLivePlugins)
    }
    
    public override func construct(args: [JSConvertible?]) {
        if let writeKey = args.typed(as: String.self, index: 0) {
            self.analytics = Analytics(configuration: Configuration(writeKey: writeKey)
                .trackApplicationLifecycleEvents(false))
        }
    }
    
    public func track(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let name = args.typed(as: String.self, index: 0) else { return nil }
        let properties = args.typed(as: Dictionary.self, index: 1)
        analytics.track(name: name, properties: properties)
        return nil
    }
    
    public func identify(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let userId = args.typed(as: String.self, index: 0) else { return nil }
        let traits = args.typed(as: Dictionary.self, index: 1)
        analytics.identify(userId: userId, traits: traits)
        return nil
    }
    
    public func screen(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let title = args.typed(as: String.self, index: 0) else { return nil }
        let category = args.typed(as: String.self, index: 1)
        let properties = args.typed(as: Dictionary.self, index: 2)
        analytics.screen(title: title, category: category, properties: properties)
        return nil
    }
    
    public func group(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let groupId = args.typed(as: String.self, index: 0) else { return nil }
        let traits = args.typed(as: Dictionary.self, index: 1)
        analytics.group(groupId: groupId, traits: traits)
        return nil
    }
    
    public func alias(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let newId = args.typed(as: String.self, index: 0) else { return nil }
        analytics.alias(newId: newId)
        return nil
    }
    
    public func flush(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        analytics.flush()
        return nil
    }
    
    public func reset(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        analytics.reset()
        return nil
    }
    
    public func add(args: [JSConvertible?]) -> JSConvertible? {
        var result = false
        
        guard let analytics else { return result }
        guard let plugin = args.typed(as: JSClass.self, index: 0) else { return result }
        
        let type = plugin["type"]?.typed(as: Int.self)
        let destination = plugin["destination"]?.typed(as: String.self)
        
        guard let type = type else { return result }
        
        guard let pluginType = PluginType(rawValue: type) else { return result }
        let edgeFn = LivePlugin(jsPlugin: plugin, type: pluginType)
        
        if let dest = destination {
            // we have a destination specified, so add it there
            if let d = analytics.find(key: dest) {
                DispatchQueue.main.async {
                    _ = d.add(plugin: edgeFn)
                }
                result = true
                self.addedPlugins.append((dest, edgeFn))
            }
        } else {
            DispatchQueue.main.async {
                analytics.add(plugin: edgeFn)
            }
            result = true
            self.addedPlugins.append((nil, edgeFn))
        }
        return result
    }
    
    public func removeLivePlugins(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        
        for tuple in self.addedPlugins {
            let (dest, p) = tuple
            if let dst = dest {
                // Remove from destination
                if let d = analytics.find(key: dst) {
                    d.remove(plugin: p)
                }
            } else {
                // Remove from main timeline
                analytics.remove(plugin: p)
            }
        }
        self.addedPlugins.removeAll()
        return nil
    }
}
