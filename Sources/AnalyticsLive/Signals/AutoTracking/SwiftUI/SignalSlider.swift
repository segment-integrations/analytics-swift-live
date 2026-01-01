//
//  SignalSlider.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/3/25.
//

#if !os(tvOS)

import SwiftUI

// MARK: - SignalSlider

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
public struct SignalSlider<Value, Label, ValueLabel>: SignalingUI, View
    where Value: BinaryFloatingPoint, Value.Stride: BinaryFloatingPoint,
          Label: View, ValueLabel: View {
    
    let sui: SwiftUI.Slider<Label, ValueLabel>
    let signalTitle: String?
    let signalValue: Binding<Value>
    
    public var body: some View {
        sui
    }
    
    // MARK: - Signal Emission
    
    private static func emitSignal(title: String?, isEditing: Bool, value: Value) {
        let signal = InteractionSignal(
            component: controlType(),
            title: title,
            data: [
                "action": isEditing ? "drag_started" : "drag_ended",
                "value": Double(value)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    /// Creates an onEditingChanged handler that emits signals and calls user's handler
    private static func makeEditingHandler(
        title: String?,
        value: Binding<Value>,
        userHandler: ((Bool) -> Void)?
    ) -> (Bool) -> Void {
        return { isEditing in
            emitSignal(title: title, isEditing: isEditing, value: value.wrappedValue)
            userHandler?(isEditing)
        }
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Slider"
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

// MARK: - Full Label Initializers (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalSlider {
    /// Creates a slider with custom labels and value labels.
    public init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0...1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label,
        @ViewBuilder minimumValueLabel: () -> ValueLabel,
        @ViewBuilder maximumValueLabel: () -> ValueLabel
    ) {
        let title = Self.extractTitle(from: label())
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: label,
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel,
            onEditingChanged: Self.makeEditingHandler(title: title, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = title
    }
    
    /// Creates a slider with step and custom labels.
    public init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label,
        @ViewBuilder minimumValueLabel: () -> ValueLabel,
        @ViewBuilder maximumValueLabel: () -> ValueLabel
    ) {
        let title = Self.extractTitle(from: label())
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            step: step,
            label: label,
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel,
            onEditingChanged: Self.makeEditingHandler(title: title, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = title
    }
}

// MARK: - Label Only (No Value Labels) (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalSlider where ValueLabel == EmptyView {
    /// Creates a slider with a custom label.
    public init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0...1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label
    ) {
        let title = Self.extractTitle(from: label())
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: label,
            onEditingChanged: Self.makeEditingHandler(title: title, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = title
    }
    
    /// Creates a slider with step and a custom label.
    public init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label
    ) {
        let title = Self.extractTitle(from: label())
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            step: step,
            label: label,
            onEditingChanged: Self.makeEditingHandler(title: title, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = title
    }
}

// MARK: - No Labels (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalSlider where Label == EmptyView, ValueLabel == EmptyView {
    /// Creates a slider without labels.
    public init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0...1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            onEditingChanged: Self.makeEditingHandler(title: nil, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = nil
    }
    
    /// Creates a slider with step but without labels.
    public init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            step: step,
            onEditingChanged: Self.makeEditingHandler(title: nil, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = nil
    }
}

// MARK: - Text Label with Value Labels (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalSlider where Label == Text {
    /// Creates a slider with a localized string key and value labels.
    public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0...1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder minimumValueLabel: () -> ValueLabel,
        @ViewBuilder maximumValueLabel: () -> ValueLabel
    ) {
        let title = Self.extractTitle(from: titleKey)
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(titleKey) },
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel,
            onEditingChanged: Self.makeEditingHandler(title: title, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = title
    }
    
    /// Creates a slider with a string title and value labels.
    public init<S: StringProtocol>(
        _ title: S,
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0...1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder minimumValueLabel: () -> ValueLabel,
        @ViewBuilder maximumValueLabel: () -> ValueLabel
    ) {
        let titleString = String(title)
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(title) },
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel,
            onEditingChanged: Self.makeEditingHandler(title: titleString, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = titleString
    }
}

// MARK: - Text Label Only (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalSlider where Label == Text, ValueLabel == EmptyView {
    /// Creates a slider with a localized string key.
    public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0...1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        let title = Self.extractTitle(from: titleKey)
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(titleKey) },
            onEditingChanged: Self.makeEditingHandler(title: title, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = title
    }
    
    /// Creates a slider with a string title.
    public init<S: StringProtocol>(
        _ title: S,
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0...1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        let titleString = String(title)
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(title) },
            onEditingChanged: Self.makeEditingHandler(title: titleString, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = titleString
    }
    
    /// Creates a slider with a localized string key and step.
    public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        let title = Self.extractTitle(from: titleKey)
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            step: step,
            label: { Text(titleKey) },
            onEditingChanged: Self.makeEditingHandler(title: title, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = title
    }
    
    /// Creates a slider with a string title and step.
    public init<S: StringProtocol>(
        _ title: S,
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value.Stride = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        let titleString = String(title)
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            step: step,
            label: { Text(title) },
            onEditingChanged: Self.makeEditingHandler(title: titleString, value: value, userHandler: onEditingChanged)
        )
        self.signalValue = value
        self.signalTitle = titleString
    }
}

#endif
