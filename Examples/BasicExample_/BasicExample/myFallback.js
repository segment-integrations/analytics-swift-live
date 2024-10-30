//
//  myFallback.js
//  BasicExample
//
//  Created by Brandon Sneed on 9/26/24.
//

console.log("My Fallback JS was loaded.")

class SampleLivePlugin extends LivePlugin {
    constructor(type, destination) {
        console.log("js: SampleLivePlugin.constructor() called")
        super(type, destination);
    }
    
    update(settings, initialUpdate) {
        console.log("js: SampleLivePlugin.update() called")
        if (initialUpdate == true) {
            console.log(settings)
        }
    }
    
    execute(event) {
        console.log("js: SampleLivePlugin.execute() called");
        return super.execute(event);
    }
    
    track(event) {
        console.log("js: SampleLivePlugin.track() called");
        event.context.livePluginMessage = "This came from a LivePlugin track";
        return event;
    }
    
    identify(event) {
        console.log("js: SampleLivePlugin.identify() called");
        event.context.livePluginMessage = "This came from a LivePlugin identify";
        return event;
    }

};

// Add to main timeline
let fn = new SampleLivePlugin(LivePluginType.enrichment, null);
analytics.add(fn);

// Add to Segment destination
//let fn2 = new SampleLivePlugin(LivePluginType.enrichment, "Segment.io");
//analytics.add(fn2)

function trackClick(currentSignal) {
  if (currentSignal.type == "UIInteraction") {
    analytics.track(currentSignal.data.title, null)
  }
}


function processSignal(signal) {
  trackClick(signal)
}
