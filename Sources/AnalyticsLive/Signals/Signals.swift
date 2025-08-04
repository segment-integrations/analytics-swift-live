//
//  Signals.swift
//
//  Created by Brandon Sneed on 2/4/24.
//

import Foundation
import Segment
import Substrata

public class Signals: Plugin {
    public let key = "SignalsPlugin"
    public var type: PluginType = .after
    public weak var analytics: Analytics? = nil

    internal var signalObject: JSClass? = nil
    internal var signalAdd: JSFunction? = nil
    internal var processSignals: JSFunction? = nil
    internal var engine: JSEngine? = nil
    internal var broadcasters = [SignalBroadcaster]()
    internal var broadcastTimer: QueueTimer? = nil
    @Atomic internal var counter: Int = 0
    @Atomic internal var configuration: SignalsConfiguration = SignalsConfiguration(writeKey: "NONE")

    struct QueuedSignal {
        let signal: any RawSignal
        let source: SignalSource
    }
    @Atomic internal var queuedSignals = [QueuedSignal]()
    @Atomic internal var ready = false

    public var anonymousId: String {
        get {
            if let anonId = analytics?.anonymousId {
                return anonId
            } else {
                return ""
            }
        }
    }

    public var nextIndex: Int {
        var result: Int = -1
        guard let signalObject else { return result }
        guard let index = signalObject.call(method: "_getNextIndex", args: nil)?.typed(as: Int.self) else { return result }
        result = index
        return result
    }

    static public let shared = Signals()

    internal init() { }

    public func configure(analytics: Analytics) {
        self.analytics = analytics

        if let e = analytics.find(pluginType: LivePlugins.self) {
            e.addDependent(plugin: self)
        }

        for var b in broadcasters {
            b.analytics = analytics
        }
    }

    public func execute<T: RawEvent>(event: T?) -> T? {
        guard let event else { return event }
        // prevent possible infinite recursion ...
        // ie: a signal generates an event, that generates a signal, that generates an event, ...
        if isRepeating(event: event) {
            // don't emit another signal for this.
            return event
        }
        // end preventative measures ^
        let s = InstrumentationSignal(event: event)
        emit(signal: s, source: .manual)
        return event
    }

    public func flush() {
        for b in broadcasters {
            b.relay()
        }
    }

    public func useConfiguration(_ configuration: SignalsConfiguration) {
        // Stop existing swizzlers
        stopAllSwizzlers()

        _configuration.set(configuration)
        updateConfiguration()

        // Start swizzlers with new config
        startConfiguredSwizzlers()

        for var b in broadcasters {
            b.analytics = analytics
        }
    }

    public func emit<T: RawSignal>(signal: T, source: SignalSource = .manual) {
        if ready == false {
            let queued = QueuedSignal(signal: signal, source: source)
            _queuedSignals.mutate { qs in
                qs.append(queued)
            }
            return
        }

        switch source {
        case .autoNetwork:
            if !configuration.useNetworkAutoSignal {
                return
            }
        case .autoSwiftUI:
            if !configuration.useSwiftUIAutoSignal {
                return
            }
        case .autoUIKit:
            if !configuration.useUIKitAutoSignal {
                return
            }
        case .manual:
            break
        }

        var workingSignal = signal
        workingSignal.context = StaticContext.values

        if let json = try? JSON(with: workingSignal) {
            guard let dict = json.dictionaryValue?.toJSConvertible() else { return }

            for b in broadcasters {
                // sometimes it's useful to get it in both formats since we have them
                // and it bypasses double-conversion.  See DebugBroadcaster.
                b.added(signal: workingSignal)
                if let jB = b as? SignalJSONBroadcaster {
                    jB.added(signal: dict)
                }
            }
            
            signalAdd?.call(args: [dict])
            processSignals?.call(args: [dict])

            /** Perf tracking ...
            // Start timing the expensive part
            let startTime = CFAbsoluteTimeGetCurrent()
            processSignals?.call(args: [dict])
            let endTime = CFAbsoluteTimeGetCurrent()

            let processingTime = (endTime - startTime) * 1000 // Convert to milliseconds
            SignalPerformanceTracker.shared.recordProcessingTime(processingTime)
             */
        }

        var shouldRelay = false
        _counter.mutate { c in
            c += 1
            if c > configuration.maximumBufferSize || c >= configuration.relayCount {
                c = 0
                shouldRelay = true
            }
        }
        if shouldRelay {
            for b in broadcasters { b.relay() }
        }
    }

    public func buffer() -> [JSConvertible]? {
        let buffer = signalObject?["signalBuffer"]?.typed(as: Array.self)
        return buffer
    }

    static public func emit<T: RawSignal>(signal: T, source: SignalSource = .manual) {
        Signals.shared.emit(signal: signal, source: source)
    }
}

// MARK: -- LivePluginsDependent

extension Signals: LivePluginsDependent {
    public func prepare(engine: JSEngine) {
        self.engine = engine
    }

    public func readyToStart() {
        _ready.set(true)

        // get all our entry points and config stuff up to date ...
        locateJSRequirements()
        updateConfiguration()

        replayQueuedSignals()
    }

    public func teardown(engine: JSEngine) {
        _ready.set(false)
        stopAllSwizzlers()
    }
}

// MARK: -- Swizzler Lifecycle Management

extension Signals {
    internal func stopAllSwizzlers() {
        #if canImport(UIKit) && !os(watchOS)
        TabBarSwizzler.shared.stop()
        NavigationSwizzler.shared.stop()
        ModalSwizzler.shared.stop()
        TapSwizzler.shared.stop()
        #endif

        // Remove network tracking plugin if it exists
        if let analytics = analytics {
            if let networkPlugin = analytics.find(pluginType: SignalsNetworkTracking.self) {
                analytics.remove(plugin: networkPlugin)
            }
        }
    }

    internal func startConfiguredSwizzlers() {
        if configuration.useSwiftUIAutoSignal {
            let _ = SignalNavCache.shared // touch this so it gets set up.

            #if canImport(UIKit) && !os(watchOS)
            // needed for SwiftUI TabView's.
            TabBarSwizzler.shared.start()
            NavigationSwizzler.shared.start()
            ModalSwizzler.shared.start()
            #endif
        }

        #if canImport(UIKit) && !os(watchOS)
        if configuration.useUIKitAutoSignal {
            TabBarSwizzler.shared.start()
            NavigationSwizzler.shared.start()
            TapSwizzler.shared.start()
        }
        #endif

        if configuration.useNetworkAutoSignal {
            _ = analytics?.add(plugin: SignalsNetworkTracking())
        }
    }
}

// MARK: -- Configuration & Setup

extension Signals {
    internal func locateJSRequirements() {
        assert(engine != nil, "ERROR: JSEngine hasn't been set!")
        engine?.perform {
            if signalObject == nil {
                signalObject = engine?["signals"]?.typed(as: JSClass.self)
                signalAdd = signalObject?.value(for: "_add")?.typed(as: JSFunction.self)
            }

            if processSignals == nil {
                processSignals = engine?["processSignal"]?.typed(as: JSFunction.self)
            }
        }
    }

    internal func updateConfiguration() {
        // Update JS configuration
        signalObject?.setValue(configuration.maximumBufferSize, for: "maxBufferSize")
        StaticContext.configureRuntimeVersion(engine: engine)

        // Update native configuration
        broadcasters = configuration.broadcasters
        broadcastTimer = QueueTimer(interval: configuration.relayInterval, handler: { [weak self] in
            guard let self else { return }
            for b in self.broadcasters { b.relay() }
        })

        SignalsNetworkProtocol.allowedHosts = configuration.allowedNetworkHosts
        SignalsNetworkProtocol.blockedHosts = configuration.blockedNetworkHosts
    }
}

// MARK: -- Utilities

extension Signals {
    internal func replayQueuedSignals() {
        if queuedSignals.count > 0 {
            let queued = queuedSignals
            _queuedSignals.mutate { qs in
                qs.removeAll()
            }

            for item in queued {
                var signal = item.signal
                // update these, as we wouldn't have had them earlier
                signal.index = nextIndex
                signal.anonymousId = anonymousId
                // emit it like normal
                emit(signal: signal, source: item.source)
            }
        }
    }

    internal func isRepeating(event: RawEvent?) -> Bool {
        let type: String? = event?.context?.value(forKeyPath: KeyPath("__eventOrigin.type"))
        guard let type else { return false }
        if type == "signals" {
            return true
        }
        return false
    }
}

// MARK: - Testing Utils
/// Reset the shared instance -- *FOR TESTING ONLY*
/// Needs to be here to access the @Atomic's.
extension Signals {
    internal func reset() {
        _ready.set(false)
        _counter.set(0)
        _queuedSignals.mutate { $0.removeAll() }

        stopAllSwizzlers()

        signalObject = nil
        processSignals = nil
        engine = nil

        broadcasters.removeAll()
        broadcastTimer = nil

        analytics = nil

        _configuration.set(SignalsConfiguration(writeKey: "NONE"))
    }

    internal func setReady(_ value: Bool) {
        _ready.set(value)
    }

    internal func queuedSignalsCount() -> Int {
        return queuedSignals.count
    }
}
