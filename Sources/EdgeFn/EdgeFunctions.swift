//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import Segment
import Substrata

public typealias JSObject = [String: Any]

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
    
    public var analytics: Analytics? = nil {
        didSet {
            if analytics?.find(pluginType: EdgeFunctions.self) != nil {
                fatalError("Can't have more than one instance of EdgeFunctions on Analytics.")
            }
        }
    }
    
    internal let engine = JSEngine()
    internal let fallbackFileURL: URL?
    @Atomic internal var loaded = false
    
    public init(fallbackFileURL: URL?) {
        self.fallbackFileURL = fallbackFileURL
    }
    
    public func update(settings: Settings, type: UpdateType) {
        guard type == .initial else { return }
        guard loaded == false else { return }
        
        self.loaded = true
        
        let edgeFnData = settings.edgeFunctions.asDictionary()
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
        
        // expose our classes
        engine.expose(classType: JSAnalytics.self, name: "Analytics")
        
        // set the system analytics object.
        engine.setObject(key: "analytics", value: JSAnalytics(wrapping: self.analytics, engine: engine))
        
        // setup our enum for plugin types.
        engine.execute(script: EmbeddedJS.enumSetupScript)
        engine.execute(script: EmbeddedJS.edgeFnBaseSetupScript)
        
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
                if let e = e {
                    print(String(describing: e as Any))
                }
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

}

