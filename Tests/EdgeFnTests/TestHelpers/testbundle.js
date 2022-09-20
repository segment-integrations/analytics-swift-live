console.log("starting example...");

class TestSuper extends EdgeFn {
    constructor(type, destination) {
        console.log("js: TestSuper.constructor() called")
        super(type, destination);
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
        event.context.edgeFnMessage = "This came from an EdgeFn";
        return event;
    }
    
    screen(event) {
        console.log("js: TestSuper.screen() called");
        analytics.track("trackScreen", null)
        return event;
    }
};

// EdgeFn example end -------------------------------------------

const userRegisteredEventProps = {
    plan: "Pro Annual",
    accountType : "Facebook"
}

const checkoutEventProps = {
    amount: "$1337.00"
}

let a = new Analytics("lAtKCqFrmtnhIVV7LDPTrgoCbL0ujlBe");
_ = a.track("userRegisteredEvent", userRegisteredEventProps);
_ = a.track("checkoutEvent", checkoutEventProps);
a.flush();

let fn = new TestSuper(EdgeFnType.enrichment, null);

console.log(fn.type)

analytics.add(fn);

