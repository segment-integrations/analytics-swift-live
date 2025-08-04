function screenCall(currentSignal) {
    if (currentSignal.type == "navigation") {
        analytics.screen(currentSignal.data.currentScreen, "category", { prop1: "hello"})
    }
}

function trackAddToCart(currentSignal) {
  if (currentSignal.type == "interaction" &&
      currentSignal.data.target.title == "Add to cart") {
    var properties = new Object()
    let network = signals.find(currentSignal, "network", (signal) => {
  		return signal.data.url.includes("/products")
    })
    if (network) {
      properties.price = network.data.price
      properties.productId = network.data.id
      properties.productName = network.data.title
    }
    
    analytics.track(currentSignal.data.target.title, properties)
  }
}

function processSignal(signal) {
  screenCall(signal)
  trackAddToCart(signal)
}

