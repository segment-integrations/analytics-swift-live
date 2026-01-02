# Signals (Auto Instrumentation)

- [Signals (Auto Instrumentation)](#signals-auto-instrumentation)
  - [Prerequisites](#prerequisites)
  - [Getting Started](#getting-started)
  - [Additional Setup](#additional-setup)
    - [Capture Interactions](#capture-interactions)
      - [SwiftUI](#swiftui)
      - [UIKit](#uikit)
    - [Capture Navigation](#capture-navigation)
    - [Capture Network](#capture-network)
  - [Configuration Options](#configuration-options)
  - [Debug Mode](#debug-mode)

## Prerequisites

Auto-Instrumentation (aka Signals) works on top of Analytics and Live Plugins. The AnalyticsLive package includes both Signals and LivePlugins functionality. Make sure to add the following dependency to your project if you don't have analytics-swift already.

```swift
dependencies: [
    .package(url: "https://github.com/segmentio/analytics-swift.git", from: "1.9.1")
]
```

## Getting Started

1. Add AnalyticsLive to your Swift Package dependencies:
    ```swift
    dependencies: [
        .package(url: "https://github.com/segmentio/analytics-live-swift.git", from: "3.2.1")
    ]
    ```

2. Import and initialize with your Analytics instance:
    ```swift
    import Segment
    import AnalyticsLive
    
    let analytics = Analytics(configuration: Configuration(writeKey: "YOUR_WRITE_KEY"))
    
    // Add LivePlugins first
    analytics.add(plugin: LivePlugins())
    
    // Add Signals
    analytics.add(plugin: Signals.shared)
    
    // Configure Signals
    Signals.shared.useConfiguration(SignalsConfiguration(
        writeKey: "YOUR_WRITE_KEY", // Same writeKey as Analytics
        useUIKitAutoSignal: true,
        useSwiftUIAutoSignal: true,
        useNetworkAutoSignal: true,
        #if DEBUG
        // NOTE: See section below on using these flags appropriately.
        sendDebugSignalsToSegment: true, // Only true for development
        obfuscateDebugSignals: false // Only false for development
        #endif
        // ... other options
    ))
    ```

3. Set up capture for the UI framework(s) you're using:
     * [Capture SwiftUI Interactions](#swiftui)
     * [Capture UIKit Interactions](#uikit)
     * [Capture Network Activity](#capture-network)

## Additional Setup

### Capture Interactions

#### SwiftUI

SwiftUI automatic interaction signal capture requires adding typealiases to your code. This is necessary because SwiftUI doesn't provide hooks for automatic instrumentation of user interactions.

> **Note:** Navigation is captured automatically via swizzling and does NOT require typealiases. Only interaction controls need typealiases.

1. Enable SwiftUI auto-signals in your configuration:
    ```swift
    Signals.shared.useConfiguration(SignalsConfiguration(
        writeKey: "YOUR_WRITE_KEY",
        useSwiftUIAutoSignal: true
        // ... other options
    ))
    ```

2. Add the following typealiases to your SwiftUI views or in a shared file:
    ```swift
    import SwiftUI
    import AnalyticsLive
    
    // Selection & Input Controls
    typealias Button = SignalButton
    typealias TextField = SignalTextField
    typealias SecureField = SignalSecureField
    typealias Toggle = SignalToggle
    typealias Picker = SignalPicker
    typealias DatePicker = SignalDatePicker
    typealias ColorPicker = SignalColorPicker
    typealias Link = SignalLink
    typealias Menu = SignalMenu
    
    #if !os(tvOS)
    typealias Slider = SignalSlider
    typealias Stepper = SignalStepper
    #endif
    
    // List & Collection Views
    typealias List = SignalList
    ```

3. Use the controls normally in your SwiftUI code:
    ```swift
    struct ContentView: View {
        @State private var text = ""
        @State private var isOn = false
        
        var body: some View {
            NavigationStack {
                VStack {
                    Button("Click Me") {
                        // Button tap will automatically generate a signal
                    }
                    
                    TextField("Enter text", text: $text)
                    // Text changes will automatically generate signals
                    
                    Toggle("Enable Feature", isOn: $isOn)
                    // Toggle changes will automatically generate signals
                }
            }
        }
    }
    ```

> **Note:** The typealiases replace SwiftUI's native controls with signal-generating versions. Your code remains unchanged, but interactions are now automatically captured.

> **Implementation Detail:** The Signal* wrappers are extremely thin layers on top of the original SwiftUI controls. They pass through all initializers, modifiers, and behaviors exactly as the native controls do. The only addition is signal emission when the user interacts with the control. Your UI will look and behave identically to using the native SwiftUI controls directly.

#### UIKit

UIKit automatic signal capture uses method swizzling and requires no code changes.

1. Enable UIKit auto-signals in your configuration:
    ```swift
    Signals.shared.useConfiguration(SignalsConfiguration(
        writeKey: "YOUR_WRITE_KEY",
        useUIKitAutoSignal: true
        // ... other options
    ))
    ```

2. That's it! The following UIKit interactions are automatically captured via method swizzling:

    **Controls:**
    - `UIButton` taps
    - `UISwitch` toggle events
    - `UISlider` value changes
    - `UIStepper` value changes
    - `UISegmentedControl` selection
    - `UIDatePicker` value changes
    - `UIPageControl` page changes
    - `UIColorWell` color changes (iOS 14+)
    - `UITextField` text editing
    - `UIPickerView` row selection
    
    **Cells:**
    - `UITableViewCell` selection
    - `UICollectionViewCell` selection
    
    **Tab Bar:**
    - `UITabBarController` tab selection

### Capture Navigation

Navigation capture is fully automatic when you enable SwiftUI or UIKit auto-signals. No typealiases or additional setup required.

The following navigation events are captured via method swizzling:

- `UINavigationController` push/pop operations
- `UIViewController` modal presentations and dismissals
- Screen appearance and disappearance

Navigation signals include rich metadata:
- Screen name (extracted from title, navigation item, accessibility label, or class name)
- Previous screen information
- SwiftUI view names when available

> **Note:** Both SwiftUI and UIKit apps benefit from this automatic navigation tracking. SwiftUI navigation ultimately uses UIKit under the hood, so the same swizzlers capture both.

### Capture Network

Network capture automatically tracks URLSession requests and responses.

1. Enable network auto-signals in your configuration:
    ```swift
    Signals.shared.useConfiguration(SignalsConfiguration(
        writeKey: "YOUR_WRITE_KEY",
        useNetworkAutoSignal: true,
        allowedNetworkHosts: ["*"], // Allow all hosts (default)
        blockedNetworkHosts: [] // Block specific hosts (optional)
        // ... other options
    ))
    ```

2. Network requests are automatically captured, including:
   - Request URL, method, headers, and body
   - Response status, headers, and body
   - Request/response correlation via request ID

Network tracking works with:
- `URLSession.shared`
- Custom `URLSessionConfiguration` instances
- Third-party networking libraries (Alamofire, etc.)

#### Configuring Network Hosts

You can control which network requests are tracked:

```swift
SignalsConfiguration(
    writeKey: "YOUR_WRITE_KEY",
    useNetworkAutoSignal: true,
    allowedNetworkHosts: ["api.myapp.com", "*.example.com"], // Only track these hosts
    blockedNetworkHosts: ["analytics.google.com"] // Exclude these hosts
)
```

- `allowedNetworkHosts`: Array of host patterns to track. Use `"*"` to allow all hosts (default).
- `blockedNetworkHosts`: Array of host patterns to exclude from tracking.

The following hosts are automatically blocked to prevent recursive tracking:
- `api.segment.com`
- `cdn-settings.segment.com`
- `signals.segment.com`
- `api.segment.build`
- `cdn.segment.build`
- `signals.segment.build`

## Configuration Options

Using the `SignalsConfiguration` object, you can control the destination, frequency, and types of signals that Segment automatically tracks within your application. The following table details the configuration options for Signals-Swift.

| OPTION            | REQUIRED | VALUE                     | DESCRIPTION |
|------------------|----------|---------------------------|-------------|
| **writeKey** | Yes | String | Your Segment write key. Should match your Analytics instance writeKey. |
| **maximumBufferSize** | No  | Int                   | The number of signals to be kept for JavaScript inspection. This buffer is first-in, first-out. Default is **1000**. |
| **relayCount** | No  | Int                   | Relays every X signals to Segment. Default is **20**. |
| **relayInterval** | No  | TimeInterval                   | Relays signals to Segment every X seconds. Default is **60**. |
| **broadcasters**  | No      | [SignalBroadcaster]    | An array of broadcasters. These objects forward signal data to their destinations, like **WebhookBroadcaster**, or you could write your own **DebugBroadcaster** that writes logs to the developer console. **SegmentBroadcaster** is always added by the SDK when `sendDebugSignalsToSegment` is true. |
| **sendDebugSignalsToSegment**      | No      | Bool                    | Turns on debug mode and allows the SDK to relay Signals to Segment server. Default is **false**. It should only be set to true for development purposes. |
| **obfuscateDebugSignals**      | No      | Bool                    | Obfuscates signals being relayed to Segment. Default is **true**. |
| **apiHost** | No | String | API host for signal relay. Default is **"signals.segment.io/v1"**. |
| **useUIKitAutoSignal** | No | Bool | Enables automatic UIKit signal capture via method swizzling. Default is **false**. |
| **useSwiftUIAutoSignal** | No | Bool | Enables automatic SwiftUI signal capture (requires typealiases for interactions). Default is **false**. |
| **useNetworkAutoSignal** | No | Bool | Enables automatic network signal capture for URLSession. Default is **false**. |
| **allowedNetworkHosts** | No | [String] | Array of host patterns to track. Use `["*"]` for all hosts. Default is **["*"]**. |
| **blockedNetworkHosts** | No | [String] | Array of host patterns to exclude from tracking. Default is **[]**. |

## Debug Mode

The SDK automatically captures various types of signals, such as interactions, navigation, and network activity. However, relaying all these signals to a destination could consume a significant portion of the end user's bandwidth. Additionally, storing all user signal data on a remote server might violate privacy compliance regulations. Therefore, by default, the SDK disables this capability, ensuring that captured signals remain on the end user's device.

However, being able to view these signals is crucial for creating event generation rules on the Segment Auto-Instrumentation dashboard. To facilitate this, the SDK provides a `sendDebugSignalsToSegment` configuration option that enables signal relaying to a destination and an `obfuscateDebugSignals` configuration option to obfuscate signals data.

> **⚠️ Warning:** `sendDebugSignalsToSegment` should only be used in a development setting to avoid storing sensitive end-user data.

Although `sendDebugSignalsToSegment` offers convenience for logging events remotely, having to rebuild the app each time it is toggled on or off can be cumbersome. Below are some suggested workarounds:

* **Use Build Configurations to Toggle Debug Mode:**
  
  1. Define different configurations in your project settings (Debug, Release, etc.)
  
  2. Use compiler flags to control the setting:
      ```swift
      Signals.shared.useConfiguration(SignalsConfiguration(
          writeKey: "YOUR_WRITE_KEY",
          // ... other config options
          #if DEBUG
          sendDebugSignalsToSegment: true,
          obfuscateDebugSignals: false
          #else
          sendDebugSignalsToSegment: false,
          obfuscateDebugSignals: true
          #endif
      ))
      ```

* **Use a Feature Flag System:** If you're using Firebase Remote Config or a similar feature flag system, you can dynamically control `sendDebugSignalsToSegment` and `obfuscateDebugSignals` without requiring a new app build:
  ```swift
  let remoteConfig = RemoteConfig.remoteConfig()
  
  Signals.shared.useConfiguration(SignalsConfiguration(
      writeKey: "YOUR_WRITE_KEY",
      // ... other config options
      sendDebugSignalsToSegment: remoteConfig["sendDebugSignalsToSegment"].boolValue,
      obfuscateDebugSignals: remoteConfig["obfuscateDebugSignals"].boolValue
  ))
  ```

* **Use Environment Variables (for debugging/testing):** You can check for environment variables or launch arguments during development:
  ```swift
  let isDebugEnabled = ProcessInfo.processInfo.environment["SIGNALS_DEBUG"] != nil
  
  Signals.shared.useConfiguration(SignalsConfiguration(
      writeKey: "YOUR_WRITE_KEY",
      // ... other config options
      sendDebugSignalsToSegment: isDebugEnabled,
      obfuscateDebugSignals: !isDebugEnabled
  ))
  ```
