console.log("starting example...");

class TestSuper extends EdgeFn {
	constructor(type, destination) {
		console.log("js code: TestSuper constructor")
		super(type, destination);
	}
	
	execute(event, properties) {
		console.log("js code: TestSuper execute");
		return super.execute(event, properties);
	}
};

// EdgeFn example end -------------------------------------------

/*
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
*/

let fn = new TestSuper(EdgeFnType.enrichment, null);
fn.execute(checkoutEventProps, null);

