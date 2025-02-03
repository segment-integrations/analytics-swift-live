//
//  SignalStepper.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/3/25.
//

import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalStepper<Label>: SignalingUI, View where Label: View {
    let sui: SwiftUI.Stepper<Label>
    let signalLabel: Any?
    let signalValue: Binding<Double>?
    
    public var body: some View {
        Group {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                if let value = signalValue {
                    sui.onChange(of: value.wrappedValue) { newValue in
                        let title: String?
                        if let localizedKey = signalLabel as? LocalizedStringKey {
                            title = localizedKey.string
                        } else if let stringValue = signalLabel as? String {
                            title = stringValue
                        } else {
                            title = describeWith(options: [signalLabel])
                        }
                        
                        let signal = InteractionSignal(
                            component: Self.controlType(),
                            title: title,
                            data: ["value": newValue]
                        )
                        Signals.emit(signal: signal, source: .autoSwiftUI)
                    }
                } else {
                    sui
                }
            } else {
                sui
            }
        }
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Stepper"
    }
}

// MARK: - Value Binding Initializers
extension SignalStepper where Label == Text {
    public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Double>,
        in bounds: ClosedRange<Double>,
        step: Double = 1
    ) {
        self.sui = SwiftUI.Stepper(titleKey, value: value, in: bounds, step: step)
        self.signalValue = value
        self.signalLabel = titleKey
    }
    
    public init<S>(
        _ title: S,
        value: Binding<Double>,
        in bounds: ClosedRange<Double>,
        step: Double = 1
    ) where S: StringProtocol {
        self.sui = SwiftUI.Stepper(title, value: value, in: bounds, step: step)
        self.signalValue = value
        self.signalLabel = String(title)
    }
}

// MARK: - Increment/Decrement Initializers
extension SignalStepper {
    public init(
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label
    ) {
        // Capture the label value up front
        let labelTitle = Self.extractLabel(label())
        
        self.sui = SwiftUI.Stepper(
            onIncrement: {
                onIncrement?()
                let signal = InteractionSignal(
                    component: Self.controlType(),
                    title: labelTitle,
                    data: ["action": "increment"]
                )
                Signals.emit(signal: signal, source: .autoSwiftUI)
            },
            onDecrement: {
                onDecrement?()
                let signal = InteractionSignal(
                    component: Self.controlType(),
                    title: labelTitle,
                    data: ["action": "decrement"]
                )
                Signals.emit(signal: signal, source: .autoSwiftUI)
            },
            onEditingChanged: onEditingChanged,
            label: label
        )
        self.signalValue = nil
        self.signalLabel = labelTitle
    }
}

extension SignalStepper where Label == Text {
    public init(
        _ titleKey: LocalizedStringKey,
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.sui = SwiftUI.Stepper(
            titleKey,
            onIncrement: {
                onIncrement?()
                let signal = InteractionSignal(
                    component: Self.controlType(),
                    title: titleKey.string,
                    data: ["action": "increment"]
                )
                Signals.emit(signal: signal, source: .autoSwiftUI)
            },
            onDecrement: {
                onDecrement?()
                let signal = InteractionSignal(
                    component: Self.controlType(),
                    title: titleKey.string,
                    data: ["action": "decrement"]
                )
                Signals.emit(signal: signal, source: .autoSwiftUI)
            },
            onEditingChanged: onEditingChanged
        )
        self.signalValue = nil
        self.signalLabel = titleKey
    }
    
    public init<S>(
        _ title: S,
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) where S: StringProtocol {
        self.sui = SwiftUI.Stepper(
            title,
            onIncrement: {
                onIncrement?()
                let signal = InteractionSignal(
                    component: Self.controlType(),
                    title: String(title),
                    data: ["action": "increment"]
                )
                Signals.emit(signal: signal, source: .autoSwiftUI)
            },
            onDecrement: {
                onDecrement?()
                let signal = InteractionSignal(
                    component: Self.controlType(),
                    title: String(title),
                    data: ["action": "decrement"]
                )
                Signals.emit(signal: signal, source: .autoSwiftUI)
            },
            onEditingChanged: onEditingChanged
        )
        self.signalValue = nil
        self.signalLabel = String(title)
    }
}
