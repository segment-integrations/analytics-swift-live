# LivePlugins Guide

LivePlugins revolutionizes how you handle analytics transformations by allowing you to write and deploy JavaScript-based transformation plugins directly to your mobile app. Instead of embedding transformation logic in native Swift code and waiting for app release cycles, you can now update transformation logic instantly via server-side updates.

## Core Benefits

- **Instant Updates**: Write and deploy transformation logic in JavaScript without app releases
- **Native Performance**: Optimized JavaScript execution with no network access during plugin runtime
- **Seamless Integration**: Works with your existing Analytics-Swift implementation
- **Flexible Targeting**: Apply transformations globally or to specific destinations

## Setup

### Basic Setup
```swift
import AnalyticsLive

let livePlugins = LivePlugins()
Analytics.main.add(plugin: livePlugins)
```

### Setup with Fallback
Provide a local JavaScript file as fallback when server downloads fail:

```swift
let fallbackURL = Bundle.main.url(forResource: "fallback", withExtension: "js")
let livePlugins = LivePlugins(fallbackFileURL: fallbackURL)
Analytics.main.add(plugin: livePlugins)
```

**Important**: If using with Signals, LivePlugins must be added first as Signals depends on it.

## Configuration

LivePlugins can be configured with several options during initialization:

```swift
let livePlugins = LivePlugins(
    fallbackFileURL: fallbackURL,
    force: false,
    exceptionHandler: { error in
        // Handle JavaScript errors
    }
)
```

### Configuration Parameters

#### fallbackFileURL: URL?
- Local file URL containing JavaScript to use as fallback
- Used when server downloads fail or are unavailable
- Ensures basic operation when network connectivity is poor
- **Must be a local file URL** (e.g., from Bundle.main)
- Optional - can be nil if no fallback is needed

#### force: Bool
- When `true`, always uses the fallback file instead of downloading from server
- When `false` (default), attempts server download first, falls back to local file if needed
- Primarily useful for debugging and development

#### exceptionHandler: ((Error) -> Void)?
- Custom error handling for JavaScript runtime errors
- Called when JavaScript execution encounters exceptions
- Optional - default behavior logs errors internally

### Configuration Examples

#### Basic Setup
```swift
let fallbackURL = Bundle.main.url(forResource: "fallback", withExtension: "js")
let livePlugins = LivePlugins(fallbackFileURL: fallbackURL)
Analytics.main.add(plugin: livePlugins)
```

#### Debug/Development Setup
```swift
let fallbackURL = Bundle.main.url(forResource: "testPlugins", withExtension: "js")
let livePlugins = LivePlugins(
    fallbackFileURL: fallbackURL,
    force: true,  // Force local file for debugging
    exceptionHandler: { error in
        print("LivePlugin error: \(error)")
        // Send to crash reporting, show alert, etc.
    }
)
Analytics.main.add(plugin: livePlugins)
```

## JavaScript Environment

LivePlugins runs in a secure, sandboxed JavaScript environment with the following characteristics:

- **No network access** - Plugins cannot make HTTP requests
- **Basic JavaScript functionality** - Standard JavaScript features available
- **Console logging** - Use `console.log()` for debugging
- **Pre-defined analytics instance** - Access via `analytics` variable

### Pre-defined Variables

#### analytics
A JavaScript wrapper around your existing native Analytics instance:
```javascript
// This is automatically available and uses your native Analytics configuration
analytics.track("Event Name", { property: "value" })

// You can also create additional instances for different write keys
let otherAnalytics = new Analytics("<DIFFERENT_WRITE_KEY>")
```

## Plugin Development

### Plugin Types

LivePlugins can be created with different types that determine when they run in the analytics timeline:

- `before` - Runs before any processing occurs
- `enrichment` - Runs during the main processing phase
- `after` - Runs after all processing is complete
- `utility` - Helper plugins that don't directly process events

### Basic Plugin Structure

All plugins extend the `LivePlugin` class:

```javascript
class MyPlugin extends LivePlugin {
    constructor() {
        super(LivePluginType.enrichment, null)
    }
    
    track(event) {
        // Transform track events
        return event
    }
}

// Create and add the plugin
let myPlugin = new MyPlugin()
analytics.add(myPlugin)
```

### Plugin Lifecycle Methods

LivePlugins can implement several lifecycle methods:

#### Event Processing Methods
- `process(event)` - Called for all events (catch-all method)
- `track(event)` - Called for track events specifically
- `identify(event)` - Called for identify events specifically
- `screen(event)` - Called for screen events specifically
- `group(event)` - Called for group events specifically

#### System Methods
- `update(settings, type)` - Called when settings are updated (type: "Initial" or "Refresh")
- `reset()` - Called when analytics is reset
- `flush()` - Called when analytics is flushed

### Basic Examples

#### Fix Misnamed Properties
```javascript
class FixProductViewed extends LivePlugin {
    constructor() {
        super(LivePluginType.enrichment, null)
    }
    
    track(event) {
        if (event.event == "Product Viewed") {
            // Set the correct property name
            event.properties.product_id = event.properties.product_did
            // Remove old property
            delete event.properties.product_did
        }
        return event
    }
}

let productViewFix = new FixProductViewed()
analytics.add(productViewFix)
```

#### Add Timestamp to All Events
```javascript
class AddTimestamp extends LivePlugin {
    constructor() {
        super(LivePluginType.enrichment, null)
    }
    
    process(event) {
        event.properties = event.properties || {}
        event.properties.processed_at = new Date().toISOString()
        return event
    }
}

let timestampPlugin = new AddTimestamp()
analytics.add(timestampPlugin)
```

#### Conditional Event Blocking
```javascript
class BlockTestEvents extends LivePlugin {
    constructor() {
        super(LivePluginType.before, null)
    }
    
    track(event) {
        // Block events with test_ prefix
        if (event.event.startsWith("test_")) {
            return null  // Returning null blocks the event
        }
        return event
    }
}

let blockTestEvents = new BlockTestEvents()
analytics.add(blockTestEvents)
```

## Destination-Specific Plugins

Plugins can target specific destinations by specifying a destination key in the constructor:

```javascript
// Remove advertisingId only from Amplitude events
class RemoveAdvertisingId extends LivePlugin {
    constructor() {
        super(LivePluginType.enrichment, "Amplitude")
    }
    
    process(event) {
        delete event.context.device.advertisingId
        return event
    }
}

let deleteAdID = new RemoveAdvertisingId()
analytics.add(deleteAdID)
```

## Advanced Features

### Context Enrichment

All analytics methods accept an optional context parameter that gets merged with the event's existing context:

```javascript
class ContextEnricher extends LivePlugin {
    constructor() {
        super(LivePluginType.enrichment, null)
    }
    
    track(event) {
        // Add context using the analytics instance
        analytics.track(event.event, event.properties, {
            campaign: {
                source: "liveplugin",
                version: "1.0"
            }
        })
        
        // Block original event since we sent an enriched version
        return null
    }
}

let enricher = new ContextEnricher()
analytics.add(enricher)
```

### Settings-Aware Plugins

Plugins can respond to settings updates:

```javascript
class SettingsAwarePlugin extends LivePlugin {
    constructor() {
        super(LivePluginType.enrichment, null)
        this.enabled = true
    }
    
    update(settings, type) {
        // type is "Initial" or "Refresh"
        this.enabled = settings.integrations?.MyPlugin?.enabled ?? true
        console.log(`Plugin ${this.enabled ? 'enabled' : 'disabled'} via ${type} settings`)
    }
    
    track(event) {
        if (!this.enabled) {
            return event  // Pass through unchanged
        }
        
        // Apply transformations when enabled
        event.properties.plugin_processed = true
        return event
    }
}

let settingsPlugin = new SettingsAwarePlugin()
analytics.add(settingsPlugin)
```

## JavaScript API Reference

### Analytics Class
```javascript
class Analytics {
   constructor(writeKey) {}              // Create new Analytics instance
   
   // Properties
   get traits() {}                       // Get current user traits
   get userId() {}                       // Get current user ID
   get anonymousId() {}                  // Get current anonymous ID
   
   // Event Methods
   track(event, properties, context) {}           // Send track event
   identify(userId, traits, context) {}           // Send identify event
   screen(title, category, properties, context) {} // Send screen event
   group(groupId, traits, context) {}             // Send group event
   
   // System Methods
   reset() {}                           // Reset analytics state
   flush() {}                           // Flush queued events
   add(livePlugin) {}                   // Add a LivePlugin
}
```

### LivePlugin Class
```javascript
class LivePlugin {
   constructor(type, destination) {}     // Create plugin with type and optional destination
   
   // Properties
   get type() {}                        // Get plugin type
   get destination() {}                 // Get destination key or null
   
   // Lifecycle Methods
   update(settings, type) {}            // Handle settings updates (type: "Initial" or "Refresh")
   process(event) {}                    // Process any event type
   
   // Event Methods
   track(event) {}                      // Handle track events
   identify(event) {}                   // Handle identify events
   group(event) {}                      // Handle group events
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
Settings update type values:
- `"Initial"` - Initial settings load
- `"Refresh"` - Settings refresh

### Utility Functions

#### Console Logging
```javascript
console.log(message)
```
Log a message to the native console for debugging.

## Best Practices

### Performance
- Keep plugin logic lightweight - they run on every event
- Avoid complex computations in hot paths
- Use early returns to skip unnecessary processing

### Error Handling
- Always return an event object from processing methods (or null to block)
- Handle undefined/null properties gracefully
- Use console.log() for debugging - logs appear in Xcode console

### Testing
- Use `force: true` during development to test local JavaScript files
- Implement custom exception handlers to catch errors during development
- Test both global and destination-specific plugin behavior

### Fallback Strategy
- Always provide a fallback file for critical transformations
- Keep fallback files simple and focused on essential transformations
- Test offline scenarios to ensure fallback behavior works correctly

