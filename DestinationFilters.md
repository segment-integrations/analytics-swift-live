# Destination Filters Guide

Destination Filters brings Segment's powerful server-side filtering capability directly to your mobile app. This feature allows you to filter analytics events on-device using the same JavaScript filtering logic as your server-side implementation, ensuring consistent filtering behavior across your entire analytics pipeline.

## Core Benefits

- **Consistent Filtering**: Uses the same JavaScript logic as Segment's server-side filters
- **Device-Mode Support**: Extends filtering capabilities to device-mode destinations
- **Network Optimization**: Filters events before transmission, reducing bandwidth usage
- **Data Point Savings**: Prevents unwanted events from being sent, reducing consumed data points
- **Zero Code Changes**: Configured entirely through the Segment web app

## How It Works

Destination Filters downloads your workspace's filtering rules and applies them locally on the device. When an analytics event is generated:

1. **Event Generated**: Your app creates a track, screen, identify, or group event
2. **Filters Applied**: The event is checked against your downloaded filtering rules
3. **Destination Routing**: Only events that pass the filters are sent to their respective destinations
4. **Consistent Logic**: The same filtering logic runs on-device and server-side

This ensures that device-mode destinations (like Firebase, Amplitude, etc.) receive exactly the same filtered events as your server-side destinations.

## Setup

### Prerequisites

1. **Segment Workspace**: Destination Filters enabled on your workspace
2. **Web App Configuration**: Filters configured at https://app.segment.com
3. **Analytics-Swift**: Version 1.8.0 or higher

> **Note**: Destination Filters may need to be enabled on your workspace by your Segment representative.

### Basic Setup

```swift
import AnalyticsLive

let filters = DestinationFilters()
Analytics.main.add(plugin: filters)
```

That's it! The plugin automatically:
- Downloads your workspace's filtering rules
- Applies them to all events
- Updates rules when your workspace configuration changes

### Complete Setup Example

```swift
import AnalyticsLive

// Set up your analytics instance as usual
let analytics = Analytics(configuration: Configuration(
    writeKey: "<YOUR WRITE KEY>"
))

// Add destination filters
let filters = DestinationFilters()
analytics.add(plugin: filters)

// Add other plugins as needed
let livePlugins = LivePlugins()
analytics.add(plugin: livePlugins)

// Your app is now filtering events on-device!
```

## Configuration

Destination Filters are configured entirely through the Segment web app - no code changes required.

### Web App Configuration

1. **Log into Segment**: Visit https://app.segment.com
2. **Navigate to Destinations**: Select your workspace and go to Destinations
3. **Configure Filters**: Set up filtering rules for your destinations
4. **Test Filters**: Use Segment's testing tools to verify filter behavior
5. **Deploy**: Changes are automatically downloaded to your mobile apps

### Filter Types

Destination Filters supports all Segment filter types:

#### Event Filters
Filter events based on event name, properties, or context:
```javascript
// Example: Only allow purchase events over $50
event.event === "Purchase" && event.properties.value > 50
```

#### Property Filters
Transform or remove specific properties:
```javascript
// Example: Remove PII from events
delete event.properties.email
delete event.context.traits.phone
```

#### Destination-Specific Filters
Apply different filtering logic to different destinations:
```javascript
// Example: Send full data to analytics, limited data to advertising
if (destination.name === "Google Analytics") {
    return event
} else if (destination.name === "Facebook Pixel") {
    delete event.properties.customer_id
    return event
}
```

## Benefits and Use Cases

### Network Optimization

By filtering events on-device, you reduce:
- **Bandwidth Usage**: Fewer HTTP requests to destination APIs
- **Battery Consumption**: Less network activity
- **Data Costs**: Important for users on limited data plans

### Data Point Management

Prevent unwanted events from consuming your destination quotas:
- **Debug Events**: Filter out test/debug events in production
- **Spam Prevention**: Block malformed or excessive events
- **Compliance**: Remove events containing PII for specific destinations

### Consistent User Experience

Ensure device-mode and server-side destinations receive identical data:
- **A/B Testing**: Consistent test group assignment across all destinations
- **Feature Flags**: Same feature visibility logic everywhere
- **User Segmentation**: Identical user categorization

## Advanced Scenarios

### Development vs Production

Use different filtering strategies for development and production:

```javascript
// Example filter that blocks test events in production
if (event.properties.environment === "test" && context.app.version.includes("prod")) {
    return null  // Block test events in production builds
}
return event
```

### Gradual Rollouts

Implement percentage-based filtering for gradual feature rollouts:

```javascript
// Example: Send new event type to only 10% of users
if (event.event === "New Feature Used") {
    const userId = event.userId || event.anonymousId
    const hash = simpleHash(userId)
    if (hash % 100 < 10) {
        return event  // Send to 10% of users
    }
    return null  // Block for 90% of users
}
return event
```

### Compliance and Privacy

Automatically remove sensitive data for specific regions or destinations:

```javascript
// Example: Remove PII for GDPR compliance
if (event.context.location.country === "Germany" && destination.name === "Marketing Tool") {
    delete event.properties.email
    delete event.properties.phone
    delete event.context.traits.firstName
    delete event.context.traits.lastName
}
return event
```

## Troubleshooting

### Filters Not Applied

If your filters aren't working:

1. **Check Workspace Settings**: Ensure Destination Filters is enabled
2. **Verify Filter Logic**: Test filters in the Segment web app
3. **App Restart**: Restart your app to download latest filter rules
4. **Network Connectivity**: Ensure the device can reach Segment's CDN

### Testing Filters

To verify filters are working:

1. **Segment Debugger**: Use the live debugger to see filtered events
2. **Destination Analytics**: Check if filtered events appear in destination dashboards
3. **Console Logging**: Add temporary logging to your filter JavaScript
4. **A/B Testing**: Create simple test filters to verify behavior

### Performance Considerations

- **Filter Complexity**: Keep filter logic simple for best performance
- **Event Volume**: High-volume apps should test filter performance thoroughly
- **Memory Usage**: Complex filters may increase memory usage slightly

## Migration from Server-Side Only

If you're currently using only server-side filters:

1. **Enable Feature**: Contact your Segment representative to enable Destination Filters
2. **Copy Logic**: Your existing server-side filter logic will work on-device
3. **Test Thoroughly**: Verify consistent behavior between server and device filtering
4. **Monitor Performance**: Watch for any performance impact in your mobile app
5. **Gradual Rollout**: Consider enabling for a subset of users initially

Your existing filter configurations will automatically apply to device-mode destinations once Destination Filters is enabled.
