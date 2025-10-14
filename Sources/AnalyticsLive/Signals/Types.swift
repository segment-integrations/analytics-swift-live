//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/4/24.
//

import Foundation
import Segment
import Substrata

// MARK: -- Signal Broadcaster

public protocol SignalBroadcaster {
    func added(signal: any RawSignal)
    func relay()
}

public protocol SignalJSONBroadcaster: SignalBroadcaster {
    func added(signal: [String: Any])
}

extension SignalJSONBroadcaster {
    func added(signal: any RawSignal) { /* do nothing */ }
}

// MARK: -- Custom Signal Helpers for different types (see Manual.swift)
public protocol Signaling {}

// MARK: -- Signal Sources

public enum SignalSource {
    case autoNetwork
    case autoSwiftUI
    case autoUIKit
    case manual
}

// MARK: -- Core Signal Definitions

public enum SignalType: String, Codable {
    case interaction
    case navigation
    case network
    case localData
    case instrumentation
    case userDefined
}

public protocol RawSignal<T>: Codable {
    associatedtype T: Codable
    var anonymousId: String { get set }
    var type: SignalType { get set }
    var timestamp: String { get set }
    var index: Int { get set }
    var context: StaticContext? { get set } // this is set at emit time
    var data: T { get set }
}

// MARK: -- Navigation Signal

public struct NavigationSignal: RawSignal {
    public struct NavigationData: Codable {
        let currentScreen: String
        let previousScreen: String?
    }
    
    public var anonymousId: String = Signals.shared.anonymousId
    public var type: SignalType = .navigation
    public var timestamp: String = Date().iso8601()
    public var index: Int = Signals.shared.nextIndex
    public var context: StaticContext? = nil
    public var data: NavigationData
    
    public init(currentScreen: String, previousScreen: String? = nil) {
        self.data = NavigationData(currentScreen: currentScreen, previousScreen: previousScreen)
    }
}


// MARK: -- Interaction Signal

public struct InteractionSignal: RawSignal {
    public struct InteractionData: Codable {
        public struct Target: Codable {
            let component: String
            let title: String?
            let data: JSON?
        }
        let target: Target
        
        init(component: String, title: String? = nil, data: JSON? = nil) {
            self.target = Target(component: component, title: title, data: data)
        }
    }
    
    public var anonymousId: String = Signals.shared.anonymousId
    public var type: SignalType = .interaction
    public var timestamp: String = Date().iso8601()
    public var index: Int = Signals.shared.nextIndex
    public var context: StaticContext? = nil
    public var data: InteractionData

    public init(component: String, title: String? = nil, data: [String: Any]? = nil) {
        if let data {
            let json: JSON? = try? JSON(data)
            self.data = InteractionData(component: component, title: title, data: json)
        } else {
            self.data = InteractionData(component: component, title: title, data: nil)
        }
    }
}

// MARK: -- Network Signal

public struct NetworkSignal: RawSignal {
    public enum NetworkAction: String, Codable {
        case request
        case response
    }
    
    public struct NetworkData: Codable {
        let action: NetworkAction
        let url: URL?
        let body: JSON?
        let contentType: String?
        let method: String?
        let status: Int?
        let ok: Bool?
        let requestId: String
        
        init(action: NetworkAction, url: URL?, body: [String: Any]?, contentType: String?, method: String?, status: Int?, requestId: String) {
            if let body {
                let json: JSON? = try? JSON(body)
                self.body = json
            } else {
                self.body = nil
            }
            
            self.action = action
            self.url = url
            self.contentType = contentType
            self.method = method
            self.status = status
            self.ok = (status ?? 0 >= 200 && status ?? 0 < 300)
            self.requestId = requestId
        }
        
        init(action: NetworkAction, url: URL?, body: JSON?, contentType: String?, method: String?, status: Int?, ok: Bool?, requestId: String) {
            self.body = body
            self.action = action
            self.url = url
            self.contentType = contentType
            self.method = method
            self.status = status
            self.ok = ok
            self.requestId = requestId
        }
    }
    
    public var anonymousId: String = Signals.shared.anonymousId
    public var type: SignalType = .network
    public var timestamp: String = Date().iso8601()
    public var index: Int = Signals.shared.nextIndex
    public var context: StaticContext? = nil
    public var data: NetworkData

    public init(data: NetworkData) {
        self.data = data
    }
}

// MARK: -- Local Data Signal

public struct LocalDataSignal: RawSignal {
    public enum LocalDataAction: String, Codable {
        case loaded
        case updated
        case saved
        case deleted
        case undefined
    }
    
    public struct LocalData: Codable {
        let action: LocalDataAction
        let identifier: String
        let data: JSON?
    }
    
    public var anonymousId: String = Signals.shared.anonymousId
    public var type: SignalType = .localData
    public var timestamp: String = Date().iso8601()
    public var index: Int = Signals.shared.nextIndex
    public var context: StaticContext? = nil
    public var data: LocalData

    public init(action: LocalDataAction, identifier: String, data: [String: Any]? = nil) {
        if let data {
            let json: JSON? = try? JSON(data)
            self.data = LocalData(action: action, identifier: identifier, data: json)
        } else {
            self.data = LocalData(action: action, identifier: identifier, data: nil)
        }
    }
}

// MARK: -- Instrumentation Signal

public struct InstrumentationSignal: RawSignal {
    public enum EventType: String, Codable {
        case track
        case screen
        case identify
        case group
        case alias
        case unknown // likely never to happen, but a good fallback
    }
    
    public struct InstrumentationData: Codable {
        let type: EventType
        let rawEvent: JSON?
    }

    public var anonymousId: String = Signals.shared.anonymousId
    public var type: SignalType = .instrumentation
    public var timestamp: String = Date().iso8601()
    public var index: Int = Signals.shared.nextIndex
    public var context: StaticContext? = nil
    public var data: InstrumentationData

    public init(event: RawEvent) {
        let typeStr = event.type ?? "Unknown Segment Event"
        var json: JSON = .null
        if let j = try? JSON(with: event) {
            json = j
        }
        self.data = InstrumentationData(type: EventType(rawValue: typeStr) ?? .unknown, rawEvent: json)
    }
}

// MARK: -- User Defined signal

/**
 .....
 
 what part of User Defined, don't you get ... did you expect us to define it for you homie? :D
 
```
struct MyKindaSignal: RawSignal {
    struct MyKindaData {
        let that: String
    }
    
    var anonymousId: String = Signals.shared.anonymousId
    var type: SignalType = .userDefined
    var timestamp: String = Date().iso8601()
    var index: Int = Signals.shared.nextIndex
    var context: StaticContext? = nil
    var data: MyKindaData
    
    init(that: String) {
        self.data = MyKindaData(that: that)
    }
}
```
 
 */
 

