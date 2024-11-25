/**
THIS FILE IS GENERATED!! DO NOT MODIFY!
THIS FILE IS GENERATED!! DO NOT MODIFY!
THIS FILE IS GENERATED!! DO NOT MODIFY!

Use embedJS.sh to re-generate if needed.
*/

internal class SignalsRuntime {
    static let embeddedJS = """
    
    
    // Raw Signal Definitions ---------------------------------
    const SignalType = Object.freeze({
        Interaction: "interaction",
        Navigation: "navigation",
        Network: "network",
        LocalData: "localData",
        Instrumentation: "instrumentation",
        UserDefined: "userDefined"
    })
      
      
    class RawSignal {
        anonymousId;
        type;
        data;
        timestamp;
        index;
        
        constructor(type, data) {
            this.anonymousId = analytics.anonymousId
            this.type = type
            this.data = data
            this.timestamp = new Date()
            this.index = -1 // this is set on signals.add(...)
        }
    }
      
      
    // Navigation Signal Definitions --------------------------
    const NavigationAction = Object.freeze({
        Forward: "forward",
        Backward: "backward",
        Modal: "modal",
        Entering: "entering",
        Leaving: "leaving",
        Page: "page",
        Popup: "popup"
    })
      
    class NavigationData {
        action;
        screen;
        constructor(action, screen) {
            this.action = action
            this.screen = screen
        }
    }
      
    class NavigationSignal extends RawSignal {
        constructor(action, screen) {
            let data = new NavigationData(action, screen)
            super(SignalType.Navigation, data)
        }
    }
      
      
    // Interaction Signal Definitions -------------------------
    class InteractionData {
        component;
        info;
        data;
        constructor(component, info, data) {
            this.component = component
            this.info = info
            this.data = data
        }
    }
      
    class InteractionSignal extends RawSignal {
        constructor(component, info, object) {
            let data = new InteractionData(component, info, object)
            super(SignalType.Interaction, data)
        }
    }
      
      
    // Network Signal Definitions -----------------------------
    const NetworkAction = Object.freeze({
        Request: "request",
        Response: "response"
    })
      
    class NetworkData {
        action;
        url;
        data;
        constructor(action, url, data) {
            this.action = action
            this.url = url
            this.data = data
        }
    }
      
    class NetworkSignal extends RawSignal {
        constructor(action, url, object) {
            let data = new NetworkData(action, url, object)
            super(SignalType.Network, data)
        }
    }
    
    
    // LocalData Signal Definitions ---------------------------
      
    const LocalDataAction = Object.freeze({
        Loaded: "loaded",
        Updated: "updated",
        Saved: "saved",
        Deleted: "deleted",
        Undefined: "undefined"
    })
      
    class LocalData {
        action;
        identifier;
        data;
        constructor(action, identifier, data) {
            this.action = action
            this.identifier = identifier
            this.data = data
        }
    }
      
    class LocalDataSignal extends RawSignal {
        constructor(action, identifier, object) {
            let data = new LocalData(action, identifier, object)
            super(SignalType.LocalData, data)
        }
    }
      
    
    // Instrumentation Signal Definitions ---------------------
    
    const EventType = Object.freeze({
        Track: "track",
        Screen: "screen",
        Identify: "identify",
        Group: "group",
        Alias: "alias"
    })
      
    class InstrumentationData {
        type;
        rawEvent;
        constructor(rawEvent) {
            this.type = rawEvent.event
            this.rawEvent = rawEvent
        }
    }
      
    class InstrumentationSignal extends RawSignal {
        constructor(rawEvent) {
            let data = new InstrumentationData(rawEvent)
            super(SignalType.Instrumentation, data)
        }
    }
    
    
    // Signals Class Defintion --------------------------------
    
    class Signals {
        constructor() {
            this.signalBuffer = []
            this.signalCounter = 0
            this.maxBufferSize = 1000
        }
        
        add(signal) {
            if (this.signalCounter < 0) {
                // we've rolled over?  start back at zero.
                this.signalCounter = 0
            }
            if (signal.index == -1) {
                signal.index = getNextIndex()
            }
            this.signalBuffer.unshift(signal)
            // R-E-S-P-E-C-T that's what this maxBufferSize means to me
            if (this.signalBuffer.length > this.maxBufferSize) {
                this.signalBuffer.pop()
            }
        }
    
        getNextIndex() {
            let index = this.signalCounter
            this.signalCounter += 1
            return index
        }
        
        find(fromSignal, signalType, predicate) {
            var fromIndex = 0
            if (fromSignal != null) {
                this.signalBuffer.find((signal, index) => {
                    if (fromSignal === signal) {
                        fromIndex = index
                    }
                })
            }
            
            for (let i = fromIndex; i < this.signalBuffer.length; i++) {
                let s = this.signalBuffer[i]
                if ((s.type === signalType) || (signalType == undefined)) {
                    if (predicate != null) {
                        try {
                            if (predicate(s)) {
                                return s
                            }
                        } catch (e) {  
                        }
                    } else {
                        return s
                    }
                }
            }
            
            return null
        }
        
        findAndApply(fromSignal, signalType, searchPredicate, applyPredicate) {
            let result = this.find(fromSignal, signalType, searchPredicate)
            if (result) {
                applyPredicate(result)
            }
            return result
        }
    }
      
    let signals = new Signals();
      
    

    """
}

