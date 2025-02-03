console.log("starting example...");

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
        event.context.livePluginMessage = "This came from a LivePlugin";
        return event;
    }
    
    screen(event) {
        console.log("js: SampleLivePlugin.screen() called");
        analytics.track("trackScreen", null)
        return event;
    }
};

// Add to main timeline
let fn = new SampleLivePlugin(LivePluginType.enrichment, null);
analytics.add(fn);

// Add to Segment destination
let fn2 = new SampleLivePlugin(LivePluginType.enrichment, "Segment.io");
analytics.add(fn2)
