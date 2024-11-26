# Analytics Live

Analytics Live is a powerful enhancement suite that enables dynamic Analytics-Swift, and gives Segment customers the ability to deploy Destination Filters, transformations and even Auto-Instrumentation without app updates, while maintaining enterprise-grade security and performance.

## Core Features

### 📱 LivePlugins
LivePlugins revolutionizes how you handle analytics transformations by allowing you to write and deploy JavaScript-based transformation plugins directly to your mobile app. 

Instead of embedding transformation logic in native Swift code and waiting for app release cycles, you can now:

- Write and update transformation logic in JavaScript
- Deploy changes instantly via server-side updates
- Maintain native-level performance with optimized JavaScript execution
- Seamlessly integrate with your existing analytics implementation

### 🔍 Signals
Signals provides automated user activity tracking through a sophisticated breadcrumb system. It captures crucial user interactions and allows you to transform them into meaningful analytics events using JavaScript.

**Key Capabilities:**
- **Comprehensive Activity Tracking**
  - Navigation events and screen transitions
  - User interface interactions
  - Network activity monitoring (inbound/outbound)
  - Local data access patterns
  - Integration with existing analytics events

- **Enterprise-Grade Privacy**
  - Built-in PII protection
  - Automatic data obfuscation in release builds
  - Configurable privacy rules

- **Flexible Event Generation**
  - Transform breadcrumbs into Segment events using JavaScript
  - Create custom event generation rules
  - Process and filter data in real-time

### 🎯 Destination Filters
Destination Filters brings Segment's powerful server-side filtering capability directly to your mobile app. This feature:

- Uses the same JavaScript filtering logic as Segment's server-side implementation
- Extends filtering capabilities to device-mode destinations
- Ensures consistent filtering behavior across your entire analytics pipeline
- Optimizes network usage by filtering events before transmission
- Reduces data points consumed by preventing unwanted events from being sent

### Prerequisites
- Analytics-Swift version 1.6.2 or higher
- macOS 10.15+ or iOS 13+

### Installation

#### Swift Package Manager

Add Analytics Live as a dependency in your `Package.swift` file:

```swift
dependencies: [
    // your existing reference to analytics-swift
    .package(url: "https://github.com/segmentio/analytics-swift.git", from: "1.6.2")
    // add analytics-live ...
    .package(url: "https://github.com/segment-integrations/analytics-swift-live.git", from: "1.0.0")
]
```
#### Xcode

1. In Xcode, select File → Add Packages...
2. Enter the package URL: https://github.com/segment-integrations/analytics-swift-live.git
3. Click Add Package

### Usage

Analytics Live integrates with your existing Analytics-Swift setup through three main plugins:

#### Import AnalyticsLive
```swift
import AnalyticsLive
```

#### Using Live Plugins
LivePlugins allows you to transform analytics data using JavaScript. You can provide a fallback JavaScript file that will be used when network access is unavailable or during first launch.

```swift
// Set up fallback file
let fallbackURL: URL? = Bundle.main.url(forResource: "myFallback", withExtension: "js")
// Initialize and add LivePlugins
let lp = LivePlugins(fallbackFileURL: fallbackURL)
Analytics.main.add(plugin: lp)
```

#### Using Signals
Signals is implemented as a singleton to enable signal emission from anywhere in your app. Basic setup requires only a write key, with additional configuration options covered in the Signals Configuration section.

```swift
let config = SignalsConfiguration(writeKey: "<YOUR WRITE KEY>")
Signals.shared.useConfiguration(config)
Analytics.main.add(plugin: Signals.shared)
```

#### Using Destination Filters
Destination Filters allows you to filter analytics events on-device using rules configured in the Segment web app.

```swift
let filters = DestinationFilters()
Analytics.main.add(plugin: filters)
```

## LivePlugins

LivePlugins allows you to write JavaScript-based transformation plugins that process analytics events in your app. These plugins run in a secure, sandboxed JavaScript environment with no network access.  Also see the [LivePlugins Javascript API Reference](#liveplugins-javascript-api-reference) for more information.

### Plugin Types

LivePlugins can be created with different types that determine when they run in the analytics timeline:
- `before` - Runs before any processing occurs
- `enrichment` - Runs during the main processing phase
- `after` - Runs after all processing is complete
- `utility` - Helper plugins that don't directly process events

### Basic Example

Here's a simple plugin that fixes a misnamed property:

```javascript
class FixProductViewed extends LivePlugin {
    track(event) {
        if (event.event == "Product Viewed") {
            // set the correct property name
            event.properties.product_id = event.properties.product_did
            // remove old property
            delete event.properties.product_did
        }
        return event
    }
}

// Create and add the plugin
let productViewFix = new FixProductViewed(LivePluginType.enrichment, null)
analytics.add(productViewFix)
```

### Destination-Specific Plugins

Plugins can target specific destinations by specifying a destination key:

```javascript
// Remove advertisingId only from Amplitude events
class RemoveAdvertisingId extends LivePlugin {
    process(event) {
        delete event.context.device.advertisingId
        return super.process(event)
    }
}

let deleteAdID = new RemoveAdvertisingId(LivePluginType.enrichment, "Amplitude")
analytics.add(deleteAdID)
```

### JavaScript Environment

LivePlugins runs in a limited JavaScript environment:
- No network access
- Basic JavaScript functionality only
- Console logging available via `console.log()`
- Access to analytics instance via pre-defined `analytics` variable

### Plugin Lifecycle Methods

LivePlugins can implement several lifecycle methods:
- `process(event)` - Called for all events
- `track(event)` - Called for track events
- `identify(event)` - Called for identify events
- `screen(event)` - Called for screen events
- `group(event)` - Called for group events
- `alias(event)` - Called for alias events
- `update(settings, type)` - Called when settings are updated
- `reset()` - Called when analytics is reset
- `flush()` - Called when analytics is flushed


## Signals

Signals are lightweight data points that capture user interactions and system events in your app. While individual signals provide small pieces of information, they become powerful when combined to generate rich analytics events.  Also see the [Signals Javascript API Reference](#signals-javascript-api-reference) for more information.

### Core Concepts

#### What are Signals?
Signals represent discrete app activities, such as:
- Button taps (e.g., "Add To Cart" button clicked)
- Navigation changes (e.g., user entered Product Detail screen)
- Network requests/responses
- User interactions
- System events

#### Signal Buffer
The Signals system maintains a buffer of recent signals (default: 1000) that can be used by JavaScript event generators. This buffer allows you to:
- Access historical signals
- Correlate related signals
- Build rich context for events

#### Signal Processing
When signals are emitted, they're processed through your custom signal processing function:

```javascript
function processSignal(signal) {
   trackScreens(signal)
   trackAddToCart(signal)
}
```

This will then reach out to the individual event generators to see if Segment events can be formed.

#### Event Generators
Event generators are JavaScript functions that process signals and generate Segment events. Here's a simple example that creates screen events:

```javascript
function trackScreens(signal) {
   if (signal.type === SignalType.Navigation && signal.data.action === NavigationAction.Entering) {
       analytics.screen("Screen Viewed", null, {
           "screenName": signal.data.screen
       })
   }
}
```

#### Advanced Signal Correlation
Event generators can look back through the signal buffer to correlate related signals. Here's an example that combines user interaction with network data:

```javascript
function trackAddToCart(signal) {
   // Check for "Add To Cart" button tap
   if (signal.type === SignalType.Interaction && signal.data.title === "Add To Cart") {
       let properties = {}
       
       // Look for recent product network response
       const network = signals.find(signal, SignalType.Network, (s) => {
           return (s.data.action === NetworkAction.Response && s.data.url.includes("product"))
       })
       
       // Enrich event with product data
       if (network) {
           properties.price = network.data.data.content.price
           properties.currency = network.data.data.content.currency ?? "USD"
           properties.productId = network.data.data.content.id
           properties.productName = network.data.data.content.title
       }
       
       // Send enriched track event
       analytics.track("Add To Cart", properties)
   }
}
```

This approach to signal correlation allows you to:
- Build rich, contextual events
- Combine data from multiple sources
- Process data efficiently on-device
- Reduce need for server-side data correlation

## Signals Configuration

Signals can be configured through the `SignalsConfiguration` struct, which offers various options to control buffer size, automatic signal generation, network monitoring, and broadcasting behavior.

### Basic Configuration
```swift
let config = SignalsConfiguration(
   writeKey: "<YOUR WRITE KEY>",
   useSwiftUIAutoSignal: true,
   useNetworkAutoSignal: true
)
```

### Configuration Options

#### Required Parameters
- `writeKey: String`
 - Your Segment write key
 - No default value, must be provided

#### Buffer Control
- `maximumBufferSize: Int`
 - Maximum number of signals kept in memory
 - Default: 1000

#### Signal Relay
- `relayCount: Int`
 - Number of signals to collect before processing
 - Default: 20
- `relayInterval: TimeInterval`
 - Time interval between signal processing in seconds
 - Default: 60

#### Automatic Signal Generation
- `useUIKitAutoSignal: Bool`
 - Enable automatic UIKit interaction signals
 - Default: false
- `useSwiftUIAutoSignal: Bool`
 - Enable automatic SwiftUI interaction signals
 - Default: false
- `useNetworkAutoSignal: Bool`
 - Enable automatic network request/response signals
 - Default: false

#### Network Host Control
- `allowedNetworkHosts: [String]`
 - List of hosts to monitor for network signals
 - Default: ["*"] (all hosts)
- `blockedNetworkHosts: [String]`
 - List of hosts to exclude from network signals
 - Default: [] (empty array)
 - Automatically includes Segment endpoints:
   ```
   api.segment.com
   cdn-settings.segment.com
   signals.segment.com
   api.segment.build
   cdn.segment.build
   signals.segment.build
   ```

#### Signal Broadcasting
- `broadcasters: [SignalBroadcaster]?`
 - Array of broadcasters to handle signals
 - Default: [SegmentBroadcaster()]
 - Available broadcasters:
   - `SegmentBroadcaster`: Sends signals to Segment when in Debug mode
   - `DebugBroadcaster`: Prints signals to the console
   - `WebhookBroadcaster`: Delivers signals to a specified webhook URL
 
### Example Configurations

#### Basic Configuration
```swift
let config = SignalsConfiguration(
   writeKey: "<YOUR WRITE KEY>"
)
```

#### Full SwiftUI App Configuration
```swift
let config = SignalsConfiguration(
   writeKey: "<YOUR WRITE KEY>",
   maximumBufferSize: 2000,
   relayCount: 10,
   relayInterval: 30,
   useSwiftUIAutoSignal: true,
   useNetworkAutoSignal: true
)
```

#### Custom Network Monitoring
```swift
let config = SignalsConfiguration(
   writeKey: "<YOUR WRITE KEY>",
   useNetworkAutoSignal: true,
   allowedNetworkHosts: ["api.myapp.com", "api.myanalytics.com"],
   blockedNetworkHosts: ["internal.myapp.com"]
)
```

## Types of Signals

All signals share common fields:
- `anonymousId`: The anonymous identifier of the user
- `timestamp`: ISO8601 formatted timestamp of when the signal was created
- `index`: Sequential index of the signal
- `type`: The type of signal (navigation, interaction, network, etc.)
- `data`: Signal-specific data as detailed below

### Navigation Signals
Captures navigation events within your app.
- `action`: Type of navigation
 - `forward`: Forward navigation
 - `backward`: Backward navigation
 - `modal`: Modal presentation
 - `entering`: Entering a screen
 - `leaving`: Leaving a screen
 - `page`: Page change
 - `popup`: Popup display
- `screen`: Name or identifier of the screen

### Interaction Signals
Captures user interactions with UI components.
- `component`: Type of UI component interacted with
- `title`: Text or identifier associated with the component (optional)
- `data`: Additional contextual data about the interaction in JSON format (optional)

### Network Signals
Monitors network activity in your app.
- `action`: Type of network activity
 - `request`: Outgoing network request
 - `response`: Incoming network response
- `url`: The URL being accessed
- `statusCode`: HTTP status code (for responses)
- `data`: Response data in JSON format (optional)

### Local Data Signals
Monitors interactions with local data storage.
- `action`: Type of data operation
 - `loaded`: Data was loaded
 - `updated`: Data was updated
 - `saved`: Data was saved
 - `deleted`: Data was deleted
 - `undefined`: Other operations
- `identifier`: Identifier for the data being operated on
- `data`: The data being operated on in JSON format (optional)

### Instrumentation Signals
Captures analytics events from your existing instrumentation.
- `type`: Type of analytics event
 - `track`: Track events
 - `screen`: Screen events
 - `identify`: Identify events
 - `group`: Group events
 - `alias`: Alias events
 - `unknown`: Unknown event types
- `rawEvent`: The original analytics event data in JSON format

### User Defined Signals
Create custom signals to capture app-specific events.
- `type`: Always `.userDefined`
- `data`: Custom data structure defined by you

Example of creating a custom signal:
```swift
struct MyKindaSignal: RawSignal {
   struct MyKindaData {
       let that: String
   }
   
   var anonymousId: String = Signals.shared.anonymousId
   var type: SignalType = .userDefined
   var timestamp: String = Date().iso8601()
   var index: Int = Signals.shared.nextIndex
   var data: MyKindaData
   
   init(that: String) {
       self.data = MyKindaData(that: that)
   }
}

...

// Manually emit the signal in your code ...
Signals.emit(myKindaSignal("Robbie Ray Rana")
```

## Signal Broadcasting

Signals are broadcast according to these rules:

- `SegmentBroadcaster`: Only broadcasts signals to Segment when app is built with DEBUG enabled
- `DebugBroadcaster`: Always broadcasts signals to console, regardless of build configuration
- `WebhookBroadcaster`: Always broadcasts signals to specified webhook URL, regardless of build configuration

### Custom Broadcasters

You can create your own broadcasters in two ways:

1. Conform to `SignalBroadcaster` to work with typed signals:
```swift
public protocol SignalBroadcaster {
   var analytics: Analytics? { get set }
   func added(signal: any RawSignal)
   func relay()
}
```

2. Conform to `SignalJSONBroadcaster` to work with raw dictionary data:
```swift
public protocol SignalJSONBroadcaster: SignalBroadcaster {
   func added(signal: [String: Any])
}
```

The JSON broadcaster is useful when you need to work with the raw dictionary representation of signals before they're converted to JSON.

> Note: Signals is a paid feature that may need to be enabled on your workspace by your Segment representative.

## Destination Filters

Destination Filters allows you to run your Segment workspace's destination filters directly on-device. This feature requires:

1. A Segment workspace with Destination Filters enabled (contact your Segment representative)
2. Destination Filters configured in your workspace at https://app.segment.com

### Usage

Add the Destination Filters plugin to your analytics instance:

```swift
let filters = DestinationFilters()
Analytics.main.add(plugin: filters)
```

Once configured, your device-mode destinations will automatically respect the same filtering rules you've set up in your Segment workspace.

> Note: Destination Filters is a paid feature that may need to be enabled on your workspace by your Segment representative.

___

## LivePlugins Javascript API Reference

### Utility Functions

#### Console Logging
```javascript
console.log(message)
```
Log a message to the native console.

### Pre-defined Variables

#### analytics
A pre-configured Analytics instance using your write key:
```javascript
let analytics = Analytics("<YOUR WRITE KEY>")
```

### Core Classes

#### Analytics Class
```javascript
class Analytics {
   constructor(writeKey) {}              // Create new Analytics instance
   
   // Properties
   get traits() {}                       // Get current user traits
   get userId() {}                       // Get current user ID
   get anonymousId() {}                  // Get current anonymous ID
   
   // Event Methods
   track(event, properties) {}           // Send track event
   identify(userId, traits) {}           // Send identify event
   screen(title, category, properties) {} // Send screen event
   group(groupId, traits) {}             // Send group event
   alias(newId) {}                       // Send alias event
   
   // System Methods
   reset() {}                           // Reset analytics state
   flush() {}                           // Flush queued events
   add(livePlugin) {}                   // Add a LivePlugin
}
```

#### LivePlugin Class
```javascript
class LivePlugin {
   constructor(type, destination) {}     // Create plugin with type and optional destination
   
   // Properties
   get type() {}                        // Get plugin type
   get destination() {}                 // Get destination key or null
   
   // Lifecycle Methods
   update(settings, type) {}            // Handle settings updates
   process(event) {}                    // Process any event type
   
   // Event Methods
   track(event) {}                      // Handle track events
   identify(event) {}                   // Handle identify events
   group(event) {}                      // Handle group events
   alias(event) {}                      // Handle alias events
   screen(event) {}                     // Handle screen events
   
   // System Methods
   reset() {}                          // Handle analytics reset
   flush() {}                          // Handle analytics flush
}
```

### Constants

#### LivePluginType
Available plugin types:
```javascript
const LivePluginType = {
   before: "before",         // Run before processing
   enrichment: "enrichment", // Run during processing
   after: "after",          // Run after processing
   utility: "utility"        // Utility plugins
}
```

#### UpdateType
Settings update types:
```javascript
const UpdateType = {
   initial: true,   // Initial settings load
   refresh: false   // Settings refresh
}
```

## Signals JavaScript Runtime API

### Signal Type Constants

```javascript
const SignalType = {
    Interaction: "interaction",
    Navigation: "navigation",
    Network: "network",
    LocalData: "localData",
    Instrumentation: "instrumentation",
    UserDefined: "userDefined"
}
```

### Base Signal Classes

#### RawSignal
Base class for all signals:

```javascript
class RawSignal {
    constructor(type, data) {}     // Create new signal with type and data
    
    // Properties
    anonymousId: string           // Anonymous ID from analytics instance
    type: SignalType             // Type of signal
    data: object                 // Signal-specific data
    timestamp: Date              // Creation timestamp
    index: number               // Sequential index (set by signals.add())
}
```

### Navigation Signals

Navigation action constants:

```javascript
const NavigationAction = {
    Forward: "forward",      // Forward navigation
    Backward: "backward",    // Backward navigation
    Modal: "modal",          // Modal presentation
    Entering: "entering",    // Screen entry
    Leaving: "leaving",      // Screen exit
    Page: "page",           // Page change
    Popup: "popup"          // Popup display
}
```

Navigation signal class:

```javascript
class NavigationSignal extends RawSignal {
    constructor(action, screen) {} // Create navigation signal
    
    // Data Properties
    data.action: string          // NavigationAction value
    data.screen: string          // Screen identifier
}
```

### Interaction Signals

```javascript
class InteractionSignal extends RawSignal {
    constructor(component, info, object) {} // Create interaction signal
    
    // Data Properties
    data.component: string       // UI component type
    data.info: string           // Additional information
    data.data: object          // Custom interaction data
}
```

### Network Signals

Network action constants:

```javascript
const NetworkAction = {
    Request: "request",     // Outgoing request
    Response: "response"    // Incoming response
}
```

Network signal class:

```javascript
class NetworkSignal extends RawSignal {
    constructor(action, url, object) {} // Create network signal
    
    // Data Properties
    data.action: string        // NetworkAction value
    data.url: string          // Request/response URL
    data.data: object         // Network payload data
}
```

### Local Data Signals

Local data action constants:

```javascript
const LocalDataAction = {
    Loaded: "loaded",       // Data loaded
    Updated: "updated",     // Data updated
    Saved: "saved",         // Data saved
    Deleted: "deleted",     // Data deleted
    Undefined: "undefined"  // Other operations
}
```

Local data signal class:

```javascript
class LocalDataSignal extends RawSignal {
    constructor(action, identifier, object) {} // Create local data signal
    
    // Data Properties
    data.action: string         // LocalDataAction value
    data.identifier: string    // Data identifier
    data.data: object         // Associated data
}
```

### Instrumentation Signals

Event type constants:

```javascript
const EventType = {
   Track: "track",         // Track events
   Screen: "screen",       // Screen events
   Identify: "identify",   // Identify events
   Group: "group",         // Group events
   Alias: "alias"         // Alias events
}
```

Instrumentation signal class:

```javascript
class InstrumentationSignal extends RawSignal {
   constructor(rawEvent) {}    // Create instrumentation signal
   
   // Data Properties
   data.type: string          // EventType value
   data.rawEvent: object      // Original analytics event
}
```

### Signals Buffer Management

The Signals class manages a buffer of recently collected signals:

```javascript
class Signals {
   constructor() {}           // Create new signals buffer
   
   // Properties
   signalBuffer: RawSignal[]  // Array of signals
   signalCounter: number      // Current signal count
   maxBufferSize: number      // Maximum buffer size (default: 1000)
   
   // Methods
   add(signal) {}            // Add signal to buffer
   getNextIndex() {}         // Get next signal index
   
   // Signal Search Methods
   find(fromSignal,          // Starting signal (optional)
        signalType,          // Signal type to find (optional)
        predicate) {}        // Search predicate function
        
   findAndApply(fromSignal,  // Starting signal (optional)
                signalType,  // Signal type to find (optional)
                searchPredicate,    // Search criteria
                applyPredicate) {}  // Function to apply to found signal
}
```

A global instance is automatically created and available:

```javascript
let signals = new Signals()    // Global signals buffer instance
```

### Usage Examples

Creating and adding signals:

```javascript
// Create navigation signal
let navSignal = new NavigationSignal(
   NavigationAction.Entering,
   "ProductDetail"
)
signals.add(navSignal)

// Create interaction signal
let buttonSignal = new InteractionSignal(
   "button",
   "Add to Cart",
   { productId: "123" }
)
signals.add(buttonSignal)
```

Finding related signals:

```javascript
// Find most recent network response
let networkSignal = signals.find(
   currentSignal,
   SignalType.Network,
   (signal) => {
       return signal.data.action === NetworkAction.Response
   }
)

// Find and process related signals
signals.findAndApply(
   currentSignal,
   SignalType.Interaction,
   (signal) => signal.data.component === "button",
   (found) => {
       // Process found signal
       console.log("Found related interaction:", found)
   }
)
```