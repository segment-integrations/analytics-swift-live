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
    internal static var existingInstances: [Analytics] = []
    
    internal weak var analytics: Analytics?
    
    internal var addedPlugins = [(String?, LivePlugin)]()
    
    internal lazy var currentLivePluginVersion: String? = {
        return LivePlugins.currentLivePluginVersion()
    }()
    
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
    
    deinit {
        Self.existingInstances.removeAll(where: { $0 === self.analytics })
    }
    
    static func insertOrigin(event: RawEvent?, data: [String: Any]) -> RawEvent? {
        guard var working = event else { return event }
        if let newContext = try? working.context?.add(value: data, forKey: "__eventOrigin") {
            working.context = newContext
        }
        return working
    }
    
    internal func originMarkerEnrichment(event: RawEvent?) -> RawEvent? {
        return Self.insertOrigin(event: event, data: [
            "type": "signals",
            "version": currentLivePluginVersion ?? ""
        ])
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
        
        exportMethod(named: "track") { [weak self] in self?.track(args: $0) }
        exportMethod(named: "identify") { [weak self] in self?.identify(args: $0) }
        exportMethod(named: "screen") { [weak self] in self?.screen(args: $0) }
        exportMethod(named: "group") { [weak self] in self?.group(args: $0) }
        exportMethod(named: "alias") { [weak self] in self?.alias(args: $0) }
        exportMethod(named: "add") { [weak self] in self?.add(args: $0) }
        exportMethod(named: "flush") { [weak self] in self?.flush(args: $0) }
        exportMethod(named: "reset") { [weak self] in self?.reset(args: $0) }
        exportMethod(named: "removeLivePlugins") { [weak self] in self?.removeLivePlugins(args: $0) }
    }
    
    public override func construct(args: [JSConvertible?]) {
        if let writeKey = args.typed(as: String.self, index: 0) {
            let existing = Self.existingInstances.first(where: { $0.writeKey == writeKey })
            if let existing {
                self.analytics = existing
                return
            } else {
                // we do some work on user-created instances to avoid multiple instances of the same write key
                // by just attaching whatever existing instance that might exist with that write key.
                let createdAnalytics = Analytics(configuration: Configuration(writeKey: writeKey)
                    .trackApplicationLifecycleEvents(false)
                )
                Self.existingInstances.append(createdAnalytics)
                self.analytics = createdAnalytics
            }
        }
    }
    
    public func track(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let name = args.typed(as: String.self, index: 0) else { return nil }
        let properties = args.typed(as: Dictionary.self, index: 1)
        
        let addEventOrigin: EnrichmentClosure = { [weak self] event in
            return Self.insertOrigin(event: event, data: [
                "type": "signals",
                "version": self?.currentLivePluginVersion ?? ""
            ])
        }
        
        analytics.track(name: name, properties: properties, enrichments: [addEventOrigin])
        return nil
    }
    
    public func identify(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let userId = args.typed(as: String.self, index: 0) else { return nil }
        let traits = args.typed(as: Dictionary.self, index: 1)
        analytics.identify(userId: userId, traits: traits, enrichments: [originMarkerEnrichment])
        return nil
    }
    
    public func screen(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let title = args.typed(as: String.self, index: 0) else { return nil }
        let category = args.typed(as: String.self, index: 1)
        let properties = args.typed(as: Dictionary.self, index: 2)
        analytics.screen(title: title, category: category, properties: properties, enrichments: [originMarkerEnrichment])
        return nil
    }
    
    public func group(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let groupId = args.typed(as: String.self, index: 0) else { return nil }
        let traits = args.typed(as: Dictionary.self, index: 1)
        analytics.group(groupId: groupId, traits: traits, enrichments: [originMarkerEnrichment])
        return nil
    }
    
    public func alias(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let newId = args.typed(as: String.self, index: 0) else { return nil }
        analytics.alias(newId: newId, enrichments: [originMarkerEnrichment])
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
                //DispatchQueue.main.async {
                    _ = d.add(plugin: edgeFn)
                //}
                result = true
                self.addedPlugins.append((dest, edgeFn))
            }
        } else {
            //DispatchQueue.main.async {
                _ = analytics.add(plugin: edgeFn)
            //}
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
