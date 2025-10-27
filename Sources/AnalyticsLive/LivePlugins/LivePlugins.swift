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
    internal var storageJS: StorageJS?
    internal let localJSURLs: [URL]
    
    @Atomic var dependents = [LivePluginsDependent]()
    
    public init(fallbackFileURL: URL?, force: Bool = false, exceptionHandler: ((JSError) -> Void)? = nil, localJSURLs: [URL] = []) {
        self.fallbackFileURL = fallbackFileURL
        self.forceFallback = force
        self.localJSURLs = localJSURLs
        let defaultHandler: ((JSError) -> Void)? = { error in
            print(error)
        }
        engine.exceptionHandler = exceptionHandler ?? defaultHandler
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
                let url = Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename)
                self.loadEdgeFn(url: url, useFallback: useFallback)
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

// MARK: - Engine Related bits
extension LivePlugins {
    internal func setupEngine(_ engine: JSEngine) {
        guard let analytics else { return }
        
        // expose our classes
        engine.export(type: AnalyticsJS.self, className: "Analytics")
        
        // set the system analytics object.
        let a = AnalyticsJS(wrapping: analytics)
        engine.export(instance: a, className: "Analytics", as: "analytics")
        analyticsJS = a
        
        // set the system storage object.
        let s = StorageJS()
        engine.export(instance: s, className: "Storage", as: "storage")
        storageJS = s
        
        // setup our embedded scripts ...
        engine.evaluate(script: EmbeddedJS.enumSetupScript, evaluator: "EmbeddedJS.enumSetupScript")
        engine.evaluate(script: EmbeddedJS.edgeFnBaseSetupScript, evaluator: "EmbeddedJS.edgeFnBaseSetupScript")
    }
}

// MARK: - EdgeFn management
extension LivePlugins {
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
        
        // load local JS files
        for url in self.localJSURLs {
            if let data = try? Data(contentsOf: url) {
                let scriptString = String(data: data, encoding: .utf8) ?? ""
                engine.evaluate(script: scriptString, evaluator: "local file \(url)")
            }
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
     Stores the retrieved settings data for Edge Functions.
     Input should be a JSON dictionary from Segment's settings endpoint.
     
     Completion is ALWAYS called - guaranteed.
     */
    internal func setEdgeFnData(_ data: [AnyHashable : Any]?, completion: @escaping (Bool) -> Void) {
        // Early validation - if data is invalid, we're done
        guard let validData = validateEdgeFnData(data) else {
            completion(false)
            return
        }
        
        // Check if we need to update
        if shouldUpdateEdgeFunction(newData: validData) {
            performEdgeFnUpdate(data: validData, completion: completion)
        } else {
            // No update needed, existing file is current
            completion(true)
        }
    }
    
    private func validateEdgeFnData(_ data: [AnyHashable : Any]?) -> [String: Any]? {
        guard let data = data as? [String: Any],
              data.keys.contains(Constants.versionKey),
              data.keys.contains(Constants.downloadURLKey) else {
            return nil
        }
        return data
    }
    
    private func shouldUpdateEdgeFunction(newData: [String: Any]) -> Bool {
        guard let currentData = currentData() else {
            // No existing data, so we need to download
            return true
        }
        
        // Compare versions
        let newVersion = newData.valueToInt(for: Constants.versionKey) ?? 0
        let currentVersion = currentData.valueToInt(for: Constants.versionKey) ?? 0
        
        return newVersion > currentVersion
    }
    
    private func performEdgeFnUpdate(data: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let urlString = data[Constants.downloadURLKey] as? String else {
            // URL is missing or invalid - ALWAYS call completion
            completion(false)
            return
        }
        
        // Save the new data first
        UserDefaults.standard.set(data, forKey: Constants.userDefaultsKey)
        
        // Handle empty URL case (disable bundle)
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            // Empty URL means disable the bundle
            Bundler.disableBundleURL(localURL: Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename))
            completion(true) // Successfully disabled
            return
        }
        
        // Perform the actual download
        let localURL = Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename)
        Bundler.download(url: url, to: localURL) { success in
            if success {
                print("New EdgeFunction bundle downloaded and installed.")
            }
            // ALWAYS call completion, no matter what
            completion(success)
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

    internal static func clearCache() {
        // remove the store info about said edgefn.
        UserDefaults.standard.set(nil, forKey: Constants.userDefaultsKey)
        // remove the bundle.
        let bundleURL = Bundler.getLocalBundleURL(bundleName: Constants.edgeFunctionFilename)
        try? FileManager.default.removeItem(at: bundleURL)
    }
}

