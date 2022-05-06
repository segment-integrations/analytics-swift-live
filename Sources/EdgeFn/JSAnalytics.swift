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
}

@objc
internal class JSAnalytics: NSObject, JSAnalyticsExports, JSConvertible {
    internal var analytics: Analytics? = nil
    
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
    
    init(wrapping analytics: Analytics?) {
        self.analytics = analytics
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
}
