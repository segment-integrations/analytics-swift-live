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
        if let newContext = try? working.context?.add(
            value: data,
            forKey: "__eventOrigin"
        ) {
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
    
    private func contextEnrichment(with context: [String: Any]?) -> EnrichmentClosure {
        return { event in
            guard var working = event, let context = context else {
                return event
            }
            
            // Get existing context as dictionary and merge with new context
            var mergedContext = working.context?.dictionaryValue ?? [:]
            mergedContext.merge(context) { _, new in new }
            
            do {
                working.context = try JSON(mergedContext)
            } catch {
                // If JSON creation fails, return original event
                return event
            }
            return working
        }
    }
    
    private func enrichments(with context: [String: Any]?) -> [EnrichmentClosure] {
        var enrichments = [originMarkerEnrichment]
        if let context = context {
            enrichments.append(contextEnrichment(with: context))
        }
        return enrichments
    }
    
    internal func setupExports() {
        exportProperty(named: "traits") { [weak self] in
            guard let self, let analytics = self.analytics else { return nil }
            let traits: [String: Any]? = analytics.traits()
            return traits as? JSConvertible
        }
        
        exportProperty(named: "userId") { [weak self] in
            return self?.analytics?.userId
        }
        
        exportProperty(named: "anonymousId") { [weak self] in
            return self?.analytics?.anonymousId
        }
        
        exportMethod(named: "track") { [weak self] in self?.track(args: $0) }
        exportMethod(named: "identify") {
            [weak self] in self?.identify(args: $0)
        }
        exportMethod(named: "screen") { [weak self] in self?.screen(args: $0) }
        exportMethod(named: "group") { [weak self] in self?.group(args: $0) }
        exportMethod(named: "add") { [weak self] in self?.add(args: $0) }
        exportMethod(named: "flush") { [weak self] in self?.flush(args: $0) }
        exportMethod(named: "reset") { [weak self] in self?.reset(args: $0) }
    }
    
    public override func construct(args: [JSConvertible?]) {
        if let writeKey = args.typed(as: String.self, index: 0) {
            let existing = Self.existingInstances.first(
                where: { $0.writeKey == writeKey
                })
            if let existing {
                self.analytics = existing
                return
            } else {
                // we do some work on user-created instances to avoid multiple instances of the same write key
                // by just attaching whatever existing instance that might exist with that write key.
                let createdAnalytics = Analytics(
                    configuration: Configuration(
                        writeKey: writeKey
                    )
                    .setTrackedApplicationLifecycleEvents(.none)
                )
                Self.existingInstances.append(createdAnalytics)
                self.analytics = createdAnalytics
            }
        }
    }
    
    public func track(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let name = args.typed(as: String.self, index: 0) else {
            return nil
        }
        let properties = args.typed(as: Dictionary.self, index: 1)
        let context = args.typed(as: Dictionary.self, index: 2)
        
        analytics
            .track(
                name: name,
                properties: properties,
                enrichments: enrichments(with: context)
            )
        return nil
    }
    
    public func identify(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let userId = args.typed(as: String.self, index: 0) else {
            return nil
        }
        let traits = args.typed(as: Dictionary.self, index: 1)
        let context = args.typed(as: Dictionary.self, index: 2)
        analytics
            .identify(
                userId: userId,
                traits: traits,
                enrichments: enrichments(with: context)
            )
        return nil
    }
    
    public func screen(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let title = args.typed(as: String.self, index: 0) else {
            return nil
        }
        let category = args.typed(as: String.self, index: 1)
        let properties = args.typed(as: Dictionary.self, index: 2)
        let context = args.typed(as: Dictionary.self, index: 3)
        analytics
            .screen(
                title: title,
                category: category,
                properties: properties,
                enrichments: enrichments(with: context)
            )
        return nil
        
    }
    
    public func group(args: [JSConvertible?]) -> JSConvertible? {
        guard let analytics else { return nil }
        guard let groupId = args.typed(as: String.self, index: 0) else {
            return nil
        }
        let traits = args.typed(as: Dictionary.self, index: 1)
        let context = args.typed(as: Dictionary.self, index: 2)
        analytics
            .group(
                groupId: groupId,
                traits: traits,
                enrichments: enrichments(with: context)
            )
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
        guard let analytics else { return nil }
        guard let plugin = args.typed(as: JSClass.self, index: 0) else {
            return false
        }
        
        let type = plugin["type"]?.typed(as: Int.self)
        let destination = plugin["destination"]?.typed(as: String.self)
        
        guard let type = type else { return false }
        guard let pluginType = PluginType(rawValue: type) else { return false }
        
        let edgeFn = LivePlugin(jsPlugin: plugin, type: pluginType)
        
        if let dest = destination {
            // we have a destination specified, so add it there
            guard let d = analytics.find(key: dest) else { return false }
            _ = d.add(plugin: edgeFn)
            return true
        } else {
            _ = analytics.add(plugin: edgeFn)
            return true
        }
    }
}
