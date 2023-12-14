console.log("starting example...");

class TestSuper extends LivePlugin {
    constructor(type, destination) {

        super(type, destination);
        console.log("js: TestSuper.constructor() called")
    }

    update(settings, initialUpdate) {
        console.log("js: TestSuper.update() called")
        if (initialUpdate == true) {
            console.log(settings)
        }
    }

    execute(event) {
        console.log("js: TestSuper.execute() called");
        return super.execute(event);
    }

    track(event) {
        console.log("js: TestSuper.track() called");
        event.context.livePluginMessage = "This came from a LivePlugin";
        return event;
    }

    screen(event) {
        console.log("js: TestSuper.screen() called");
        analytics.track("trackScreen", null)
        return event;
    }

    identify(event) {
        console.log("js: TestSuper.identify() called");
        console.log("js: event: ", event)
        analytics.track("trackIdentify", null)
        return event;
    }
};

// EdgeFn example end -------------------------------------------

let fn = new TestSuper(LivePluginType.enrichment, null);

analytics.add(fn);
