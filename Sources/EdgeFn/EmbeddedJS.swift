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

struct EmbeddedJS {
    static let enumSetupScript = """
    const EdgeFnType = {
        before: \(PluginType.before.rawValue),
        enrichment: \(PluginType.enrichment.rawValue),
        after: \(PluginType.after.rawValue),
        utility: \(PluginType.before.rawValue)
    };
    """
    
    static let edgeFnBaseSetupScript = """
    class EdgeFn {
        constructor(type, destination) {
            console.log("js: EdgeFn.constructor() called");
            this.type = type;
            this.destination = destination;
        }

        update(settings, type) { }

        execute(event) {
            console.log("js: EdgeFn.execute() called");
            var result = event;
            switch(event.type) {
                case "identify":
                    result = this.identify(event);
                case "track":
                    result = this.track(event);
                case "group":
                    result = this.group(event);
                case "alias":
                    result = this.alias(event);
                case "screen":
                    result = this.screen(event);
            }
            return result;
        }

        identify(event) { return event; }
        track(event) { return event; }
        group(event) { return event; }
        alias(event) { return event; }
        screen(event) { return event; }
        reset() { }
        flush() { }
    }
    """
}
