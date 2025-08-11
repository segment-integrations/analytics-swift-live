# Analytics Live

Analytics Live is a powerful enhancement suite for Analytics-Swift that enables dynamic analytics capabilities without app updates. Deploy JavaScript transformations, capture automated user activity signals, and filter events on-device while maintaining enterprise-grade security and performance.

## Features

### 📱 LivePlugins
Write and deploy JavaScript-based transformation plugins directly to your mobile app. Update analytics logic instantly via server-side updates without waiting for app releases.

**[→ Full LivePlugins Guide](LivePlugins.md)**

### 🔍 Signals  
Automated user activity tracking through a sophisticated signal system. Captures user interactions, navigation, and network activity, then transforms them into meaningful analytics events using JavaScript.

**[→ Full Signals Guide](Signals.md)**

### 🎯 Destination Filters
Brings Segment's server-side filtering capability directly to your mobile app. Filter events on-device using the same JavaScript logic as your server-side implementation.

**[→ Full Destination Filters Guide](DestinationFilters.md)**

## Installation

### Prerequisites
- Analytics-Swift version 1.8.0 or higher
- macOS 10.15+ or iOS 13+

### Swift Package Manager

Add Analytics Live as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/segmentio/analytics-swift.git", from: "1.8.0"),
    .package(url: "https://github.com/segment-integrations/analytics-swift-live.git", from: "3.2.0")
]
```

### Xcode

1. In Xcode, select File → Add Packages...
2. Enter the package URL: `https://github.com/segment-integrations/analytics-swift-live.git`
3. Click Add Package

## Quick Start

Import Analytics Live in your project:

```swift
import AnalyticsLive
```

### LivePlugins Quick Start

Transform analytics events with JavaScript:

```swift
// Optional: provide fallback JavaScript file
let fallbackURL = Bundle.main.url(forResource: "fallback", withExtension: "js")

let livePlugins = LivePlugins(fallbackFileURL: fallbackURL)
Analytics.main.add(plugin: livePlugins)
```

**[→ See full plugin development guide](LivePlugins.md)**

### Signals Quick Start

Capture and process user activity automatically:

```swift
// Add LivePlugins first (required when using Signals)
let livePlugins = LivePlugins()
Analytics.main.add(plugin: livePlugins)

let config = SignalsConfiguration(
    writeKey: "<YOUR WRITE KEY>",
    useSwiftUIAutoSignal: true,
    useNetworkAutoSignal: true
)

Signals.shared.useConfiguration(config)
Analytics.main.add(plugin: Signals.shared)
```

**[→ See full signals configuration and usage](Signals.md)**

### Destination Filters Quick Start

Filter events on-device using your Segment workspace rules:

```swift
let filters = DestinationFilters()
Analytics.main.add(plugin: filters)
```

**[→ See full destination filters setup](DestinationFilters.md)**

## Complete Setup Example

Using all Analytics Live features together:

```swift
import AnalyticsLive

// 1. Set up LivePlugins first (required if using with Signals)
let fallbackURL = Bundle.main.url(forResource: "fallback", withExtension: "js")
let livePlugins = LivePlugins(fallbackFileURL: fallbackURL)
Analytics.main.add(plugin: livePlugins)

// 2. Configure and add Signals
let signalsConfig = SignalsConfiguration(writeKey: "<YOUR WRITE KEY>")
Signals.shared.useConfiguration(signalsConfig)
Analytics.main.add(plugin: Signals.shared)

// 3. Add Destination Filters
let filters = DestinationFilters()
Analytics.main.add(plugin: filters)
```

## Documentation

- **[LivePlugins Guide](LivePlugins.md)** - JavaScript plugin development and API reference
- **[Signals Guide](Signals.md)** - Automated activity tracking and signal processing  
- **[Destination Filters Guide](DestinationFilters.md)** - On-device event filtering

## Support

Analytics Live features may require enablement on your Segment workspace. Contact your Segment representative for access to LivePlugins, Signals, or Destination Filters.
