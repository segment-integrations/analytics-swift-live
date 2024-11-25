//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import JavaScriptCore
import Substrata
import Segment

public struct EmbeddedJS {
    public static let enumSetupScript = """
    const LivePluginType = {
        before: \(PluginType.before.rawValue),
        enrichment: \(PluginType.enrichment.rawValue),
        after: \(PluginType.after.rawValue),
        utility: \(PluginType.before.rawValue)
    };
    """
    
    public static let edgeFnBaseSetupScript = """
    class LivePlugin {
        constructor(type, destination) {
            console.log("js: LivePlugin.constructor() called");
            this._type = type;
            this._destination = destination;
        }
    
        get type() {
            return this._type
        }
    
        get destination() {
            return this._destination
        }

        update(settings, type) { }

        execute(event) {
            console.log("js: LivePlugin.execute() called");
            var result = event;
            switch(event.type) {
                case "identify":
                    result = this.identify(event);
                    break;
                case "track":
                    result = this.track(event);
                    break;
                case "group":
                    result = this.group(event);
                    break;
                case "alias":
                    result = this.alias(event);
                    break;
                case "screen":
                    result = this.screen(event);
                    break;
            }
            return result;
        }

        identify(event) {
            return event;
        }
    
        track(event) {
            console.log("js: Super.track() called");
            return event;
        }
    
        group(event) {
            return event;
        }
    
        alias(event) {
            return event;
        }
        
        screen(event) {
            console.log("js: Super.screen() called");
            return event;
        }
        
        reset() {
        }
    
        flush() {
        }
    }
    """
    
    public static let signalsBaseSetupScript = """
    // mockup the class so we can run it here and try it out
    const UIInteraction = Object.freeze({
      type: "UIInteraction",
      event: {
        TouchUp: "TouchUp",
        TouchDown: "TouchDown",
        ScrollUp: "ScrollUp",
        ScrollDown: "ScrollDown",
        LongPress: "LongPress",
        Gesture: "Gesture"
      }
    })

    const NavigationChange = Object.freeze({
      type: "NavigationChange",
      event: {
        Forwards: "Forwards",
        Backwards: "Backwards",
        Modal: "Modal",
      }
    })

    const NetworkActivity = Object.freeze({
      type: "NetworkActivity",
      event: {
        Request: "Request",
        Response: "Response",
      }
    })


    class RawSignal {
      type;
      event;
      data;
      timestamp;
      
      constructor(type, event, data) {
        this.type = type
        this.event = event
        this.data = data
        this.timestamp = new Date()
      }
    }


    class Signals {
      constructor() {
        this.signalBuffer = []
      }
      
      add(signal) {
        console.log("js: signal = ", signal)
        this.signalBuffer.unshift(signal)
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
          if (s.type === signalType) {
            if (predicate != null) {
              if (predicate(s)) {
                return s
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

    function addSignal(signal) {
        signals.add(signal)
    }
    """

}
