# Signals Guide

Signals provides automated user activity tracking through a sophisticated breadcrumb system. It captures crucial user interactions and allows you to transform them into meaningful analytics events using JavaScript.

## Core Concepts

### What are Signals?
Signals represent discrete app activities, such as:
- Button taps (e.g., "Add To Cart" button clicked)
- Navigation changes (e.g., user entered Product Detail screen)
- Network requests/responses
- User interactions
- System events

### Signal Buffer
The Signals system maintains a buffer of recent signals (default: 1000) that can be used by JavaScript event generators. This buffer allows you to:
- Access historical signals
- Correlate related signals
- Build rich context for events

### Signal Processing
When signals are emitted, they're processed through your custom signal processing function:

```javascript
function processSignal(signal) {
   trackScreens(signal)
   trackAddToCart(signal)
}
```

This will then reach out to the individual event generators to see if Segment events can be formed.

### Event Generators
Event generators are JavaScript functions that process signals and generate Segment events. Here's a simple example that creates screen events:

```javascript
function trackScreens(signal) {
   if (signal.type === SignalType.Navigation) {
       analytics.screen("Screen Viewed", null, {
           "screenName": signal.data.currentScreen,
           "previousScreen": signal.data.previousScreen
       })
   }
}
```

### Advanced Signal Correlation
Event generators can look back through the signal buffer to correlate related signals. Here's an example that combines user interaction with network data:

```javascript
function trackAddToCart(signal) {
   // Check for "Add To Cart" button tap
   if (signal.type === SignalType.Interaction && signal.data.target.title === "Add To Cart") {
       let properties = {}
       
       // Look for recent product network response
       const network = signals.find(signal, SignalType.Network, (s) => {
           return (s.data.action === NetworkAction.Response && s.data.url.includes("product"))
       })
       
       // Enrich event with product data
       if (network && network.data.body) {
           properties.price = network.data.body.content.price
           properties.currency = network.data.body.content.currency ?? "USD"
           properties.productId = network.data.body.content.id
           properties.productName = network.data.body.content.title
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

## Setup

### Basic Setup
```swift
import AnalyticsLive

// Add LivePlugins first (required dependency)
let livePlugins = LivePlugins()
Analytics.main.add(plugin: livePlugins)

// Configure and add Signals
let config = SignalsConfiguration(writeKey: "<YOUR WRITE KEY>")
Signals.shared.useConfiguration(config)
Analytics.main.add(plugin: Signals.shared)
```

**Important**: LivePlugins must be added before Signals as Signals depends on it.

## Configuration

Signals can be configured through the `SignalsConfiguration` struct, which offers various options to control buffer size, automatic signal generation, network monitoring, and debug behavior.

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
  - Number of signals to collect before sending to broadcasters
  - Default: 20
- `relayInterval: TimeInterval`
  - Time interval between sending signals to broadcasters in seconds
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

#### Debug Signal Transmission
- `sendDebugSignalsToSegment: Bool`
  - Send signals to Segment for debugging signal-to-event generators
  - Default: false
  - **Use only during development when building signal processing logic**
  - High signal volume may impact your MTU limits
- `obfuscateDebugSignals: Bool`
  - Obfuscate sensitive data in debug signals sent to Segment
  - Default: true
  - **Note**: If `sendDebugSignalsToSegment=true`, signals will be obfuscated unless you explicitly set `obfuscateDebugSignals=false`
  - **Warning**: Disabling obfuscation may expose PII in signal data

#### Network Host Control
- `allowedNetworkHosts: [String]`
  - List of hosts to monitor for network signals
  - Default: ["*"] (all hosts)
  - Use "*" to allow all hosts, or specify exact hostnames
  - Examples: ["api.myapp.com", "analytics.mysite.com"]
- `blockedNetworkHosts: [String]`
  - List of hosts to exclude from network signals
  - Default: [] (empty array)
  - **Blocked hosts always take precedence over allowed hosts**
  - Automatically includes Segment endpoints:
    ```
    api.segment.com
    cdn-settings.segment.com
    signals.segment.com
    api.segment.build
    cdn.segment.build
    signals.segment.build
    ```

#### Network Filtering Rules
Network signal monitoring follows these rules in order:

1. **Blocked hosts win**: If a host appears in `blockedNetworkHosts`, it will never generate signals
2. **Allowed hosts**: If not blocked, the host must either:
   - Be explicitly listed in `allowedNetworkHosts`, OR
   - Have "*" in the `allowedNetworkHosts` array (which allows all hosts)
3. **Scheme restriction**: Only HTTP and HTTPS requests are monitored
4. **Host-only matching**: Filtering is based on hostname only (e.g., "api.myapp.com"), not full URLs with paths

#### Network Monitoring Examples

**Monitor only specific APIs:**
```swift
let config = SignalsConfiguration(
    writeKey: "<YOUR WRITE KEY>",
    useNetworkAutoSignal: true,
    allowedNetworkHosts: ["api.myapp.com", "api.analytics.com"],
    blockedNetworkHosts: []  // No additional blocks beyond Segment endpoints
)
```

**Monitor all hosts except internal ones:**
```swift
let config = SignalsConfiguration(
    writeKey: "<YOUR WRITE KEY>",
    useNetworkAutoSignal: true,
    allowedNetworkHosts: ["*"],  // Allow all hosts
    blockedNetworkHosts: ["internal.myapp.com", "dev-api.myapp.com"]
)
```

**Block specific hosts while allowing others:**
```swift
let config = SignalsConfiguration(
    writeKey: "<YOUR WRITE KEY>",
    useNetworkAutoSignal: true,
    allowedNetworkHosts: ["api.myapp.com", "public-api.myapp.com"],
    blockedNetworkHosts: ["api.myapp.com"]  // This would block api.myapp.com despite being in allowed list
)
// Result: Only public-api.myapp.com would generate signals
```

#### Custom Broadcasting
- `broadcasters: [SignalBroadcaster]`
  - Array of custom broadcasters to handle signals
  - Default: [] (empty array)
  - Available broadcasters:
    - `DebugBroadcaster`: Prints signal contents to Xcode console
    - `WebhookBroadcaster`: Sends signals to a user-supplied webhook URL
  - Use for custom signal handling beyond built-in debug transmission

### Example Configurations

#### Basic Configuration
```swift
let config = SignalsConfiguration(
    writeKey: "<YOUR WRITE KEY>"
)
```

#### Debug Configuration
```swift
let config = SignalsConfiguration(
    writeKey: "<YOUR WRITE KEY>",
    sendDebugSignalsToSegment: true,
    obfuscateDebugSignals: false  // Show raw signal data for debugging
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

Note: For SwiftUI, you'll also need to add these typealiases somewhere in your project to allow interaction signals to be captured. These are thin wrappers over SwiftUI's structs, no UI element behavior changes will occur. Additional SwiftUI controls will be supported in the future.

```swift
typealias Button = SignalButton
typealias NavigationLink = SignalNavigationLink
typealias NavigationStack = SignalNavigationStack
typealias TextField = SignalTextField
typealias SecureField = SignalSecureField
```

The complete list of available typealiases is maintained in [Typealiases.swift](Sources/AnalyticsLive/Signals/AutoTracking/SwiftUI/Typealiases.swift).

#### Custom Network Monitoring
```swift
let config = SignalsConfiguration(
    writeKey: "<YOUR WRITE KEY>",
    useNetworkAutoSignal: true,
    allowedNetworkHosts: ["api.myapp.com", "api.myanalytics.com"],
    blockedNetworkHosts: ["internal.myapp.com"]
)
```

## Signal Types

All signals share common fields:
- `anonymousId`: The anonymous identifier of the user
- `timestamp`: ISO8601 formatted timestamp of when the signal was created
- `index`: Sequential index of the signal
- `type`: The type of signal (navigation, interaction, network, etc.)
- `context`: Static context set at emit time (optional)
- `data`: Signal-specific data as detailed below

### Navigation Signals
Captures navigation events within your app.
- `currentScreen`: Name or identifier of the current screen
- `previousScreen`: Name or identifier of the previous screen (optional)

### Interaction Signals
Captures user interactions with UI components using a nested target structure.
- `target.component`: Type of UI component interacted with
- `target.title`: Text or identifier associated with the component (optional)
- `target.data`: Additional contextual data about the interaction in JSON format (optional)

### Network Signals
Monitors network activity in your app with comprehensive request/response data.
- `action`: Type of network activity (`request` or `response`)
- `url`: The URL being accessed
- `body`: Request/response body in JSON format (optional)
- `contentType`: Content type of the request/response (optional)
- `method`: HTTP method (GET, POST, etc.) (optional)
- `status`: HTTP status code (optional)
- `ok`: Boolean indicating if status code represents success (optional)
- `requestId`: Unique identifier linking requests and responses

### Local Data Signals
Monitors interactions with local data storage.
- `action`: Type of data operation (`loaded`, `updated`, `saved`, `deleted`, `undefined`)
- `identifier`: Identifier for the data being operated on
- `data`: The data being operated on in JSON format (optional)

### Instrumentation Signals
Captures analytics events from your existing instrumentation.
- `type`: Type of analytics event (`track`, `screen`, `identify`, `group`, `alias`, `unknown`)
- `rawEvent`: The original analytics event data in JSON format

### User Defined Signals
Create custom signals to capture app-specific events.
- `type`: Always `.userDefined`
- `data`: Custom data structure defined by you

Example of creating a custom signal:
```swift
struct MyKindaSignal: RawSignal {
   struct MyKindaData: Codable {
       let that: String
   }
   
   var anonymousId: String = Signals.shared.anonymousId
   var type: SignalType = .userDefined
   var timestamp: String = Date().iso8601()
   var index: Int = Signals.shared.nextIndex
   var context: StaticContext? = nil
   var data: MyKindaData
   
   init(that: String) {
       self.data = MyKindaData(that: that)
   }
}

...

// Manually emit the signal in your code
Signals.emit(MyKindaSignal("Rabi Ray Rana"))
```

## Signal Broadcasting

Signals are broadcast according to these rules:

- `sendDebugSignalsToSegment`: Only broadcasts signals to Segment when explicitly enabled for debugging
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

## JavaScript Runtime API

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
    context: object             // Static context (set at emit time, optional)
}
```

### Navigation Signals

Navigation signal class:

```javascript
class NavigationSignal extends RawSignal {
    constructor(currentScreen, previousScreen) {} // Create navigation signal
    
    // Data Properties
    data.currentScreen: string     // Current screen identifier
    data.previousScreen: string    // Previous screen identifier (optional)
}
```

### Interaction Signals

```javascript
class InteractionSignal extends RawSignal {
    constructor(component, title, data) {} // Create interaction signal
    
    // Data Properties (nested in target object)
    data.target.component: string    // UI component type
    data.target.title: string        // Additional information (optional)
    data.target.data: object         // Custom interaction data (optional)
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
    constructor(data) {} // Create network signal with NetworkData
    
    // Data Properties
    data.action: string        // NetworkAction value
    data.url: string          // Request/response URL
    data.body: object         // Request/response body (optional)
    data.contentType: string   // Content type (optional)
    data.method: string       // HTTP method (optional)
    data.status: number       // HTTP status code (optional)
    data.ok: boolean          // Success indicator (optional)
    data.requestId: string    // Unique request identifier
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
    constructor(action, identifier, data) {} // Create local data signal
    
    // Data Properties
    data.action: string         // LocalDataAction value
    data.identifier: string     // Data identifier
    data.data: object          // Associated data (optional)
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
   Alias: "alias",         // Alias events
   Unknown: "unknown"      // Unknown event types
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

The Signals class manages a buffer of recently collected signals and provides methods for searching and processing them:

```javascript
class Signals {
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
   "ProductDetail",
   "ProductList"
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
   (signal) => signal.data.target.component === "button",
   (found) => {
       // Process found signal
       console.log("Found related interaction:", found)
   }
)
```
