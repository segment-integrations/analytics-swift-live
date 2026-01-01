//
//  Description.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/21/24.
//

import Foundation
import SwiftUI

// MARK: - SignalingUI Protocol

/// Protocol for SwiftUI wrapper types that emit interaction signals.
///
/// Conforming types provide a `controlType()` method that returns a string
/// identifier for the type of control (e.g., "Button", "Toggle", "Slider").
/// This is used when emitting `InteractionSignal` events.
public protocol SignalingUI {
    /// Returns the control type identifier for this signal-emitting view.
    static func controlType() -> String
}

// MARK: - Label Description Functions

/// Extracts a label string from a stringified view description.
///
/// Handles both `SignalAnnotation` wrapped labels and plain text labels
/// by parsing the string representation of a SwiftUI view.
internal func describe(label: String) -> String? {
    let s = label
    if let r = s.range(of: "Signals.SignalAnnotation(text:") {
        let substring = String(s[r.upperBound...])
        let annotation = substring.components(separatedBy: "\"").dropFirst().first
        return annotation
    }
    
    let label = s.components(separatedBy: "\"").dropFirst().first
    return label
}

/// Extracts a label string from any value by converting it to a string first.
internal func describe(label: Any?) -> String? {
    if label == nil { return nil }
    return describe(label: String(describing: label))
}

/// Attempts to extract a label from multiple optional values, returning the first successful match.
internal func describeWith(options: [Any?]) -> String? {
    var result: String? = nil
    for opt in options {
        guard let opt else { continue }
        if let s = describe(label: String(describing: opt)), s.count > 0 {
            result = s
            return result
        }
    }
    return result
}

// MARK: - LocalizedStringKey Extension

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension LocalizedStringKey {
    /// Extracts the key string from a LocalizedStringKey using reflection.
    ///
    /// This is a workaround since `LocalizedStringKey` doesn't expose its underlying key directly.
    internal var string: String {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String ?? "unknown"
    }
}

// MARK: - LocalizedStringResource Extension

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension LocalizedStringResource {
    /// Extracts the localized string from a LocalizedStringResource.
    internal var string: String {
        String(localized: self)
    }
}

// MARK: - View Label Extraction

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
    /// Extracts a label string from a View using reflection and description parsing.
    ///
    /// This method converts the view to its string description and attempts to parse
    /// out a meaningful label, either from a `SignalAnnotation` or from text content.
    internal static func extractLabel<V: View>(_ label: V) -> String {
        let s = String(describing: label)
        if let label = describe(label: s) {
            return label
        }
        return "Unknown Label"
    }
}
