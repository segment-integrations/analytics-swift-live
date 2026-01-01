//
//  Annotations.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/20/24.
//

import Foundation
import SwiftUI
import Segment

// MARK: - View Utilities

extension View {
    /// Returns the struct name of the View type.
    static func structName() -> String {
        String(describing: Self.self)
    }
}

// MARK: - SignalAnnotation

/// A view modifier that attaches a text annotation to a view for signal capture.
///
/// `SignalAnnotation` allows you to provide explicit labels for views that would otherwise
/// be difficult to identify automatically. The annotation text is extracted during signal
/// processing to provide meaningful titles for interaction signals.
///
/// You typically don't create `SignalAnnotation` directly. Instead, use the
/// `signalAnnotation(_:)` view modifier methods.
///
/// ## Example
/// ```swift
/// // Simple annotation
/// Button("Submit") { submitForm() }
///     .signalAnnotation("Submit Order Form")
///
/// // Dynamic annotation based on state
/// Toggle(isOn: $isEnabled) { Text("Enable Feature") }
///     .signalAnnotation(state: isEnabled, true: "Feature Enabled", false: "Feature Disabled")
///
/// // Custom annotation from state
/// Slider(value: $volume)
///     .signalAnnotation(state: volume) { "Volume: \(Int($0 * 100))%" }
/// ```
public struct SignalAnnotation: ViewModifier {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    public func body(content: Content) -> some View {
        content
    }
}

// MARK: - View Extensions

extension View {
    /// Attaches a signal annotation to this view.
    ///
    /// Use this modifier to provide an explicit label for signal capture when the
    /// automatic label extraction doesn't produce a meaningful result.
    ///
    /// - Parameter text: The annotation text to attach to this view.
    /// - Returns: A view with the signal annotation attached.
    ///
    /// ## Example
    /// ```swift
    /// Button(action: { checkout() }) {
    ///     HStack {
    ///         Image(systemName: "cart")
    ///         Text("Buy Now")
    ///     }
    /// }
    /// .signalAnnotation("Checkout Button")
    /// ```
    public func signalAnnotation(_ text: String) -> some View {
        return modifier(SignalAnnotation(text))
    }
    
    /// Attaches a signal annotation based on a boolean state.
    ///
    /// Use this modifier when you want different annotation text depending on
    /// a boolean condition.
    ///
    /// - Parameters:
    ///   - state: The boolean state to evaluate.
    ///   - trueText: The annotation text when `state` is `true`.
    ///   - falseText: The annotation text when `state` is `false`.
    /// - Returns: A view with the conditional signal annotation attached.
    ///
    /// ## Example
    /// ```swift
    /// Button(action: { toggleFavorite() }) {
    ///     Image(systemName: isFavorite ? "heart.fill" : "heart")
    /// }
    /// .signalAnnotation(state: isFavorite, true: "Remove Favorite", false: "Add Favorite")
    /// ```
    public func signalAnnotation(state: Bool, true trueText: String, false falseText: String) -> some View {
        if state {
            return modifier(SignalAnnotation(trueText))
        } else {
            return modifier(SignalAnnotation(falseText))
        }
    }
    
    /// Attaches a signal annotation derived from a state value.
    ///
    /// Use this modifier when you need to generate annotation text dynamically
    /// based on some state value.
    ///
    /// - Parameters:
    ///   - state: The state value to use for generating the annotation.
    ///   - text: A closure that takes the state value and returns the annotation text.
    /// - Returns: A view with the dynamic signal annotation attached.
    ///
    /// ## Example
    /// ```swift
    /// Stepper(value: $quantity, in: 1...10) {
    ///     Text("Quantity: \(quantity)")
    /// }
    /// .signalAnnotation(state: quantity) { "Set Quantity to \($0)" }
    /// ```
    public func signalAnnotation<T>(state: T, text: (T) -> String) -> some View {
        let t = text(state)
        return modifier(SignalAnnotation(t))
    }
}
