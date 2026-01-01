//
//  SignalStepper.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/3/25.
//

#if !os(tvOS)

import SwiftUI

// MARK: - SignalStepper

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
public struct SignalStepper<Value, Label>: SignalingUI, View
    where Value: Strideable, Label: View {
    
    let sui: SwiftUI.Stepper<Label>
    let signalTitle: String?
    let signalValue: Binding<Value>?
    
    public var body: some View {
        if let value = signalValue {
            if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
                sui.onChange(of: value.wrappedValue) { oldValue, newValue in
                    emitSignal(oldValue: oldValue, newValue: newValue)
                }
            } else if #available(iOS 14.0, macOS 11.0, watchOS 7.0, *) {
                sui.onChange(of: value.wrappedValue) { newValue in
                    emitSignalLegacy(newValue: newValue)
                }
            } else {
                sui
            }
        } else {
            sui
        }
    }
    
    // MARK: - Signal Emission
    
    private func emitSignal(oldValue: Value, newValue: Value) {
        let action: String
        if let oldNum = oldValue as? any Numeric, let newNum = newValue as? any Numeric {
            action = compareNumeric(oldNum, newNum) < 0 ? "increment" : "decrement"
        } else {
            action = "changed"
        }
        
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "action": action,
                "value": String(describing: newValue),
                "previousValue": String(describing: oldValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    private func emitSignalLegacy(newValue: Value) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "action": "changed",
                "value": String(describing: newValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    /// Helper to compare numeric values
    private func compareNumeric(_ lhs: any Numeric, _ rhs: any Numeric) -> Int {
        if let l = lhs as? Int, let r = rhs as? Int {
            return l < r ? -1 : (l > r ? 1 : 0)
        } else if let l = lhs as? Double, let r = rhs as? Double {
            return l < r ? -1 : (l > r ? 1 : 0)
        } else if let l = lhs as? Float, let r = rhs as? Float {
            return l < r ? -1 : (l > r ? 1 : 0)
        }
        return 0
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Stepper"
    }
    
    // MARK: - Label Extraction
    
    private static func extractTitle(from label: Label) -> String? {
        let s = String(describing: label)
        return describe(label: s)
    }
    
    private static func extractTitle(from key: LocalizedStringKey) -> String? {
        return key.string
    }
}

// MARK: - Value Binding with Custom Label (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalStepper {
    /// Creates a stepper with a value binding and custom label.
    public init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.Stepper(
            value: value,
            in: bounds,
            step: step,
            onEditingChanged: onEditingChanged,
            label: label
        )
        self.signalValue = value
        self.signalTitle = Self.extractTitle(from: label())
    }
}

// MARK: - Value Binding with Text Label (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalStepper where Label == Text {
    /// Creates a stepper with a localized string key and value binding.
    public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.sui = SwiftUI.Stepper(
            titleKey,
            value: value,
            in: bounds,
            step: step,
            onEditingChanged: onEditingChanged
        )
        self.signalValue = value
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a stepper with a string title and value binding.
    public init<S: StringProtocol>(
        _ title: S,
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.sui = SwiftUI.Stepper(
            title,
            value: value,
            in: bounds,
            step: step,
            onEditingChanged: onEditingChanged
        )
        self.signalValue = value
        self.signalTitle = String(title)
    }
}

// MARK: - Unbounded Value Binding (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalStepper where Label == Text {
    /// Creates a stepper with a localized string key and unbounded value.
    public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.sui = SwiftUI.Stepper(
            titleKey,
            value: value,
            step: step,
            onEditingChanged: onEditingChanged
        )
        self.signalValue = value
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a stepper with a string title and unbounded value.
    public init<S: StringProtocol>(
        _ title: S,
        value: Binding<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.sui = SwiftUI.Stepper(
            title,
            value: value,
            step: step,
            onEditingChanged: onEditingChanged
        )
        self.signalValue = value
        self.signalTitle = String(title)
    }
}

// MARK: - Increment/Decrement Callbacks (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalStepper where Value == Int {
    /// Creates a stepper with increment/decrement callbacks and custom label.
    public init(
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label
    ) {
        let title = Self.extractTitle(from: label())
        
        self.sui = SwiftUI.Stepper(
            onIncrement: {
                onIncrement?()
                Self.emitCallbackSignal(title: title, action: "increment")
            },
            onDecrement: {
                onDecrement?()
                Self.emitCallbackSignal(title: title, action: "decrement")
            },
            onEditingChanged: onEditingChanged,
            label: label
        )
        self.signalValue = nil
        self.signalTitle = title
    }
    
    private static func emitCallbackSignal(title: String?, action: String) {
        let signal = InteractionSignal(
            component: controlType(),
            title: title,
            data: ["action": action]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalStepper where Value == Int, Label == Text {
    /// Creates a stepper with a localized string key and increment/decrement callbacks.
    public init(
        _ titleKey: LocalizedStringKey,
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        let title = Self.extractTitle(from: titleKey)
        
        self.sui = SwiftUI.Stepper(
            titleKey,
            onIncrement: {
                onIncrement?()
                Self.emitCallbackSignal(title: title, action: "increment")
            },
            onDecrement: {
                onDecrement?()
                Self.emitCallbackSignal(title: title, action: "decrement")
            },
            onEditingChanged: onEditingChanged
        )
        self.signalValue = nil
        self.signalTitle = title
    }
    
    /// Creates a stepper with a string title and increment/decrement callbacks.
    public init<S: StringProtocol>(
        _ title: S,
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        let titleString = String(title)
        
        self.sui = SwiftUI.Stepper(
            title,
            onIncrement: {
                onIncrement?()
                Self.emitCallbackSignal(title: titleString, action: "increment")
            },
            onDecrement: {
                onDecrement?()
                Self.emitCallbackSignal(title: titleString, action: "decrement")
            },
            onEditingChanged: onEditingChanged
        )
        self.signalValue = nil
        self.signalTitle = titleString
    }
}

#endif
