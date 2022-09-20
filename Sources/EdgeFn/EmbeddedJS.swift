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
    const EdgeFnType = {
        before: \(PluginType.before.rawValue),
        enrichment: \(PluginType.enrichment.rawValue),
        after: \(PluginType.after.rawValue),
        utility: \(PluginType.before.rawValue)
    };
    """
    
    public static let edgeFnBaseSetupScript = """
    class EdgeFn {
        constructor(type, destination) {
            console.log("js: EdgeFn.constructor() called");
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
            console.log("js: EdgeFn.execute() called");
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
}
