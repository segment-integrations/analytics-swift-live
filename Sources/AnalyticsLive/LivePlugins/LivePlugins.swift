//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import Segment
import Substrata

public protocol LivePluginsDependent {
    func prepare(engine: JSEngine)
    func readyToStart()
    func teardown(engine: JSEngine)
}

/**
 This is the main plugin for the EdgeFunctions feature.
 */
public class LivePlugins: UtilityPlugin, WaitingPlugin {
    public let type: PluginType = .utility
    public let key = "LivePlugins"
    public weak var analytics: Analytics? = nil
    
    internal struct Constants {
        static let userDefaultsKey = "LivePlugin"
        static let versionKey = "version"
        static let downloadURLKey = "downloadURL"
        static let edgeFunctionFilename = "livePlugin.js"
    }
    
    internal var engine = JSEngine()
    internal let fallbackFileURL: URL?
    internal let forceFallback: Bool
    internal var analyticsJS: AnalyticsJS?
    
    @Atomic var dependents = [LivePluginsDependent]()
    
    public init(fallbackFileURL: URL?, force: Bool = false) {
        self.fallbackFileURL = fallbackFileURL
        self.forceFallback = force
        engine.exceptionHandler = { error in
            print(error)
        }
    }
    
    deinit {
        analyticsJS?.analytics = nil
        analyticsJS = nil
        engine.shutdown()
    }
    
    public func configure(analytics: Analytics) {
        self.analytics = analytics
        // if we find an existing liveplugins instance ...
        if analytics.find(pluginType: LivePlugins.self) !== self {
            // remove ourselves.
            //DispatchQueue.main.async {
                analytics.remove(plugin: self)
            //}
            return
        }
    }
    
    public func update(settings: Settings, type: UpdateType) {
        if type != .initial { return }
        guard let analytics else { return }
        
        // pause the event timeline while get get our JS set up.
        analytics.pauseEventProcessing(plugin: self)
    
        setupEngine(self.engine)

        let edgeFnData = toDictionary(settings.edgeFunction)
        setEdgeFnData(edgeFnData) { success in
            // schedule this for later, lets let plugins finish setting up...
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let useFallback = self.forceFallback || !success
                self.loadEdgeFn(url: Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename), useFallback: useFallback)
                analytics.resumeEventProcessing(plugin: self)
            }
        }
    }
    
    public func execute<T: RawEvent>(event: T?) -> T? {
        return event
    }
    
    public func addDependent(plugin: LivePluginsDependent) {
        self._dependents.mutate { $0.append(plugin) }
    }
}

// MARK: - Internal Stuff

extension LivePlugins {
    internal func setupEngine(_ engine: JSEngine) {
        guard let analytics else { return }
        
        // setup error handler
        engine.exceptionHandler = { error in
            print(error.string)
        }
        
        // expose our classes
        engine.export(type: AnalyticsJS.self, className: "Analytics")
        
        // set the system analytics object.
        let a = AnalyticsJS(wrapping: analytics)
        engine.export(instance: a, className: "Analytics", as: "analytics")
        analyticsJS = a
        
        // setup our embedded scripts ...
        engine.evaluate(script: EmbeddedJS.enumSetupScript, evaluator: "EmbeddedJS.enumSetupScript")
        engine.evaluate(script: EmbeddedJS.edgeFnBaseSetupScript, evaluator: "EmbeddedJS.edgeFnBaseSetupScript")
    }
    
    internal func loadEdgeFn(url: URL, useFallback: Bool) {
        var localURL = url
        if useFallback, let fallbackFileURL {
            localURL = fallbackFileURL
        }
        if FileManager.default.fileExists(atPath: localURL.path) == false {
            // it's not there, copy in the fallback if we have it.
            if let fallbackFileURL = fallbackFileURL, fallbackFileURL.isFileURL {
                if FileManager.default.fileExists(atPath: fallbackFileURL.path) {
                    try? FileManager.default.copyItem(at: fallbackFileURL, to: localURL)
                }
            }
        }
        
        // tell the dependents to prepare
        for d in self.dependents {
            d.prepare(engine: engine)
        }
        
        engine.loadBundle(url: localURL) { [weak self] error in
            print(error)
            guard let self else { return }
            // tell dependents we're ready to rock
            for d in self.dependents {
                d.readyToStart()
            }
        }
    }
    
    /**
     Stores the retrieved settings data for Edge Functions.  Input will be a JSON dictionary from Segment's
     settings endpoint.
     
     Internal Use Only
     */
    internal func setEdgeFnData(_ data: [AnyHashable : Any]?, completion: @escaping (Bool) -> Void) {
        guard let data = data as? [String: Any] else {
            // we ain't got no data lt dan, fail.
            completion(false)
            return
        }
        
        let versionExists = data.keys.contains(Constants.versionKey)
        let downloadURLExists = data.keys.contains(Constants.downloadURLKey)
        
        var needsUpdate = false
        if versionExists && downloadURLExists {
            // it's actually valid
            if let currentData = currentData() {
                // if it's newer than what we have, store it and initiate download.
                let newVersion = data.valueToInt(for: Constants.versionKey)
                let currentVersion = currentData.valueToInt(for: Constants.versionKey)
                if let newVersion = newVersion, let currentVersion = currentVersion {
                    if newVersion > currentVersion {
                        needsUpdate = true
                    }
                }
            } else {
                // we didn't have it before
                needsUpdate = true
            }
        }
        
        if needsUpdate {
            updateEdgeFn(data: data, completion: completion)
        } else {
            // there's no updates, go ahead and load the file we have.
            completion(true)
        }
    }
    
    private func currentData() -> [String: Any]? {
        return UserDefaults.standard.dictionary(forKey: Constants.userDefaultsKey)
    }
    
    internal static func currentLivePluginVersion() -> String? {
        let currentData = UserDefaults.standard.dictionary(forKey: Constants.userDefaultsKey)
        let version = currentData?.valueToString(for: Constants.versionKey)
        return version
    }
    
    private func updateEdgeFn(data: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let urlString = data[Constants.downloadURLKey] as? String else { return }
        let url = URL(string: urlString)
        
        UserDefaults.standard.set(data, forKey: Constants.userDefaultsKey)
        
        if let url = url {
            Bundler.download(url: url, to: Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename)) { (success) in
                if success {
                    print("New EdgeFunction bundle downloaded and installed.")
                }
                completion(success)
            }
        } else {
            // bundle string was empty, disable the bundle.
            Bundler.disableBundleURL(localURL: Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename))
            // we've been instructed to disable edgefn, so technically a success i suppose.
            completion(true)
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

