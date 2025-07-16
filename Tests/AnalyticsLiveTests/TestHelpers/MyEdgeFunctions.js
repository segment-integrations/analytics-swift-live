console.log("edgefn script loaded for reals.")

function screenCall(currentSignal) {
    console.log("checked for screen ")
    console.log(currentSignal.type)
    if (currentSignal.type == "navigation") {
        analytics.screen(currentSignal.data.currentScreen, "category", { prop1: "hello"})
    }
}

function trackAddToCart(currentSignal) {
  if (currentSignal.type == "UIInteraction" && 
      currentSignal.data.title == "Add to cart") {
    var properties = new Object()
    let network = signals.find(currentSignal, NetworkActivity.type, (signal) => {
  		return signal.event === NetworkActivity.event.Response
		})
    if (network) {
      properties.price = network.data.options.priceV2.amount
      properties.currency = network.data.options.priceV2.currencyCode
      properties.productId = network.data.options.id
      properties.productName = network.data.title
    }
    
    analytics.track(currentSignal.data.title, properties)
  }
}

function detectIdentify(currentSignal) {
  if (currentSignal.type == "UIInteraction" && currentSignal.data.control == "Username") {
    let loginTapped = signals.find(currentSignal, UIInteraction.type, (signal) => {
  		return signal.data.title === "Login"
		})
    if (loginTapped) {
    	analytics.identify(currentSignal.data.title, null) 
    }
  }
}

function processSignal(signal) {
  screenCall(signal)
  trackAddToCart(signal)
  detectIdentify(signal)
}

