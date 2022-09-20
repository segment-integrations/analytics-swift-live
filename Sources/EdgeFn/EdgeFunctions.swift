//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import Segment
import Substrata

/**
 This is the main plugin for the EdgeFunctions feature.
 */
public class EdgeFunctions: UtilityPlugin {
    private struct Constants {
        static let userDefaultsKey = "EdgeFunction"
        static let versionKey = "version"
        static let downloadURLKey = "downloadURL"
        
        static let edgeFunctionFilename = "edgeFunction.js"
    }

    public let type: PluginType = .utility
    
    public var analytics: Analytics? = nil
    
    public let engine = JSEngine()
    internal let fallbackFileURL: URL?
    @Atomic static internal var loaded = false
    
    public init(fallbackFileURL: URL?) {
        self.fallbackFileURL = fallbackFileURL
    }
    
    public func configure(analytics: Analytics) {
        self.analytics = analytics
        
        // if we've already got edgefn's, we don't wanna do any setup
        if analytics.find(pluginType: EdgeFunctions.self) != nil {
            // we can't remove ourselves here because configure needs to be
            // called before update; so we can only remove ourselves in update.
            return
        }

        // expose our classes
        try? engine.expose(name: "Analytics", classType: AnalyticsJS.self)
        
        // set the system analytics object.
        engine.setObject(key: "analytics", value: AnalyticsJS(wrapping: self.analytics, engine: engine))
        
        // setup our enum for plugin types.
        engine.evaluate(script: EmbeddedJS.enumSetupScript)
        engine.evaluate(script: EmbeddedJS.edgeFnBaseSetupScript)
    }
    
    public func update(settings: Settings, type: UpdateType) {
        guard type == .initial else { return }
        
        // if we find an existing edgefn instance ...
        if analytics?.find(pluginType: EdgeFunctions.self) !== self {
            // remove ourselves.  we can't do this in configure.
            analytics?.remove(plugin: self)
            return
        }
        
        guard Self.loaded == false else { return }
        
        Self.loaded = true
        
        let edgeFnData = settings.edgeFunction.asDictionary()
        setEdgeFnData(edgeFnData)
        
        loadEdgeFn(url: Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename))
    }
    
}

// MARK: - Internal Stuff

extension EdgeFunctions {
    internal func loadEdgeFn(url: URL) {
        // setup error handler
        engine.errorHandler = { error in
            // TODO: Make this useful
            print(error)
        }
        
        let localURL = url
        if FileManager.default.fileExists(atPath: localURL.path) == false {
            // it's not there, copy in the fallback if we have it.
            if let fallbackFileURL = fallbackFileURL, fallbackFileURL.isFileURL {
                if FileManager.default.fileExists(atPath: fallbackFileURL.path) {
                    try? FileManager.default.copyItem(at: fallbackFileURL, to: localURL)
                }
            }
        }
        
        engine.loadBundle(url: localURL) { error in
            if case let .evaluationError(e) = error {
                print(e)
            }
        }
    }
    
    /**
     Stores the retrieved settings data for Edge Functions.  Input will be a JSON dictionary from Segment's
     settings endpoint.
     
     Internal Use Only
     */
    public func setEdgeFnData(_ data: [AnyHashable : Any]?) {
        guard let data = data as? [String: Any] else { return }
        
        let versionExists = data.keys.contains(Constants.versionKey)
        let downloadURLExists = data.keys.contains(Constants.downloadURLKey)
        
        if versionExists && downloadURLExists {
            // it's actually valid
            if let currentData = currentData() {
                // if it's newer than what we have, store it and initiate download.
                let newVersion = data[Constants.versionKey] as? Int
                let currentVersion = currentData[Constants.versionKey] as? Int
                if let newVersion = newVersion, let currentVersion = currentVersion {
                    if newVersion > currentVersion {
                        update(data: data)
                    }
                }
            } else {
                // we didn't have it before, so store it
                update(data: data)
            }
        }
    }
    
    private func currentData() -> [String: Any]? {
        return UserDefaults.standard.dictionary(forKey: Constants.userDefaultsKey)
    }
    
    private func update(data: [String: Any]) {
        guard let urlString = data[Constants.downloadURLKey] as? String else { return }
        let url = URL(string: urlString)
        
        UserDefaults.standard.set(data, forKey: Constants.userDefaultsKey)
        
        if let url = url {
            Bundler.download(url: url, to: Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename)) { (success) in
                print("New EdgeFunction installed.  Will be used on next app launch.")
            }
        } else {
            // bundle string was empty, disable the bundle.
            Bundler.disableBundleURL(localURL: Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename))
        }
    }

    internal static func clearCache() {
        // remove the store info about said edgefn.
        UserDefaults.standard.set(nil, forKey: Constants.userDefaultsKey)
        // remove the bundle.
        let bundleURL = Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename)
        try? FileManager.default.removeItem(at: bundleURL)
    }
}

