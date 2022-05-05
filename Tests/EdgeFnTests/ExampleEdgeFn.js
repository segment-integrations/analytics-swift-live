// EdgeFn example code ------------------------------------------

class ExampleModification extends EdgeFunction {
  process(event) {
    if (event.type == "track") {
      event.properties.myValue = 1;
    }
    
    return super.process(event);
  }
}

class RegistrationEdgeFunction extends EdgeFunction {
  // API necessary stuff to tie it to a destination
  get destination() {
    return "Amplitude";
  }
  
  // what order should this run with other plugins?
  get index() {
    // we'll try for the 2nd spot, if we can get it.
    // ie: maybe there's no index 0, so we'd be 0
    // instead of the suggested 1.
    //
    // return -1 to be last?
    return 1;
  }
  
  // some stuff specific to this edgefn
  alternate = new Analytics("1234");
  
  update(settings) {
    
  }

  track(event) {
    if (event.event === "User Registered") {
      // send this event over to our imaginary registration collection.
      this.alternate.track({
          event: "Registration",
        context: event.context,
        properties: {
          id: event.anonymousId
        }
      })
      return null;
    }
    return event;
  }

}

class IDFAFilterEdgeFunction extends EdgeFunction {
  process(event) {
    // strip idfa out of every event for writekey 1234.
    let idfa = event.context.device.token;
    
    if (typeof idfa !== 'undefined' && idfa) {
      event.context.device.token = null;
    }
    
    return super.process(event);
  }
}

// EdgeFn example end -------------------------------------------

// Stuff to just run to see some output

const userRegisteredEvent = {
  type: "track",
  anonymousId: "111111",
  event: "User Registered",
  context: {
    device: {
      token: "1ae81456-08ac-469a-bd79-e516d246072e"
    }
  },
  properties: {
    plan: "Pro Annual",
    accountType : "Facebook"
  }
}

const checkoutEvent = {
  type: "track",
  anonymousId: "111111",
  event: "Checkout Completed",
  context: {
    device: {
      token: "1ae81456-08ac-469a-bd79-e516d246072e"
    }
  },
  properties: {
    amount: "$1337.00"
  }
}

let a = new Analytics("ABCD");
_ = a.track(userRegisteredEvent);
_ = a.track(checkoutEvent);

native.load(MyEdgeFn, "Amplitude", 1) // load MyEdgeFn *just* for amplitude, position 1.
native.load(MyEdgeFn, "Amplitude") // load MyEdgeFn *just* for ampltude, put it at the end.
native.load(MyEdgeFn) // source middleware, effectively
native.load(MyEdgeFn, 1) // source middleware, effectively; position 1.

