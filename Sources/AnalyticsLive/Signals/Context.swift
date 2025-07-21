//
//  Context.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 7/16/25.
//
import Foundation
import Substrata

public struct StaticContext: Codable {
    struct Application: Codable {
        let name: String
        let version: String
        let build: String
        let namespace: String
    }
    
    struct Library: Codable {
        let name: String
        let version: String
    }
    
    let app: Application
    let library: Library
    let signalsRuntime: String
    
    private static var _signalsRuntimeVersion: String? = nil
    
    static let values: StaticContext = {
        let info = Bundle.main.infoDictionary ?? [:]
        
        let name = info["CFBundleDisplayName"] as? String
                ?? info["CFBundleName"] as? String
                ?? ""
        
        let application = Application(
            name: name,
            version: info["CFBundleShortVersionString"] as? String ?? "",
            build: info["CFBundleVersion"] as? String ?? "",
            namespace: Bundle.main.bundleIdentifier ?? ""
        )
        
        let library = Library(
            name: "analytics-swift-live",
            version: __analyticslive_version
        )
        
        return StaticContext(
            app: application,
            library: library,
            signalsRuntime: _signalsRuntimeVersion ?? SignalsRuntime.version
        )
    }()
    
    static func configureRuntimeVersion(engine: JSEngine) {
        guard _signalsRuntimeVersion == nil else { return }
        let jsVersion = /*engine.value(for: "SEGMENT_SIGNALS_RUNTIME_VERSION") as? String ??*/ SignalsRuntime.version
        _signalsRuntimeVersion = jsVersion
    }
}
