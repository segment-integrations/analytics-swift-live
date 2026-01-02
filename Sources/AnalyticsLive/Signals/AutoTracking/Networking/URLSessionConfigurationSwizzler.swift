//
//  URLSessionConfigurationSwizzler.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 1/2/26.
//

import Foundation

/// Swizzles URLSessionConfiguration.protocolClasses to automatically inject
/// SignalsNetworkProtocol into ALL URLSession configurations, not just the shared
/// session or default configurations.
///
/// This enables automatic network tracking for third-party networking libraries
/// like Alamofire that create custom URLSessionConfigurations.
class URLSessionConfigurationSwizzler {
    static let shared = URLSessionConfigurationSwizzler()
    private var hasSwizzled = false
    
    func start() {
        guard !hasSwizzled else { return }
        hasSwizzled = true
        
        let originalSelector = #selector(getter: URLSessionConfiguration.protocolClasses)
        let swizzledSelector = #selector(getter: URLSessionConfiguration.signals_protocolClasses)
        
        guard let originalMethod = class_getInstanceMethod(URLSessionConfiguration.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(URLSessionConfiguration.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    func stop() {
        guard hasSwizzled else { return }
        hasSwizzled = false
        
        let originalSelector = #selector(getter: URLSessionConfiguration.protocolClasses)
        let swizzledSelector = #selector(getter: URLSessionConfiguration.signals_protocolClasses)
        
        guard let originalMethod = class_getInstanceMethod(URLSessionConfiguration.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(URLSessionConfiguration.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension URLSessionConfiguration {
    @objc dynamic var signals_protocolClasses: [AnyClass]? {
        // After swizzling, this call actually invokes the ORIGINAL getter
        var protocols = self.signals_protocolClasses ?? []
        
        // Don't double-inject if already present
        if !protocols.contains(where: { $0 == SignalsNetworkProtocol.self }) {
            protocols.insert(SignalsNetworkProtocol.self, at: 0)
        }
        
        return protocols
    }
}
