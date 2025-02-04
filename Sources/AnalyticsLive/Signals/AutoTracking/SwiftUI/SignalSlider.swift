//
//  SignalSlider.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/3/25.
//

#if !os(tvOS)

import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalSlider<Label, ValueLabel>: SignalingUI, View
    where Label: View, ValueLabel: View {
    
    let sui: SwiftUI.Slider<Label, ValueLabel>
    let signalLabel: Any?
    let signalValue: Binding<Double>
    
    public var body: some View {
        Group {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                sui.onChange(of: signalValue.wrappedValue) { newValue in
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
        }
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Slider"
    }
}

// MARK: - Basic Initializers
extension SignalSlider {
    public init(
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        @ViewBuilder label: () -> Label,
        @ViewBuilder minimumValueLabel: () -> ValueLabel,
        @ViewBuilder maximumValueLabel: () -> ValueLabel
    ) {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            step: step ?? 0.001,
            label: label,
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel
        )
        self.signalValue = value
        self.signalLabel = Self.extractLabel(label())
    }
    
    public init(
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        @ViewBuilder label: () -> Label
    ) where ValueLabel == EmptyView {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: label
        )
        self.signalValue = value
        self.signalLabel = Self.extractLabel(label())
    }
}

// MARK: - Text Label Variants
extension SignalSlider where Label == Text {
    public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        minimumValueLabel: @escaping () -> ValueLabel,
        maximumValueLabel: @escaping () -> ValueLabel
    ) {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(titleKey) },
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel
        )
        self.signalValue = value
        self.signalLabel = titleKey
    }
    
    public init<S>(
        _ title: S,
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        minimumValueLabel: @escaping () -> ValueLabel,
        maximumValueLabel: @escaping () -> ValueLabel
    ) where S: StringProtocol {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(title) },
            minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel
        )
        self.signalValue = value
        self.signalLabel = String(title)
    }
}

// MARK: - Text Label Without Value Labels
extension SignalSlider where Label == Text, ValueLabel == EmptyView {
    public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1
    ) {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(titleKey) }
        )
        self.signalValue = value
        self.signalLabel = titleKey
    }
    
    public init<S>(
        _ title: S,
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1
    ) where S: StringProtocol {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(title) }
        )
        self.signalValue = value
        self.signalLabel = String(title)
    }
}

// MARK: - Deprecated Variants
extension SignalSlider where Label == Text, ValueLabel == EmptyView {
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use the slider initializer without an onEditingChanged callback and observe the value binding instead")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use the slider initializer without an onEditingChanged callback and observe the value binding instead")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use the slider initializer without an onEditingChanged callback and observe the value binding instead")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use the slider initializer without an onEditingChanged callback and observe the value binding instead")
    public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(titleKey) },
            onEditingChanged: onEditingChanged
        )
        self.signalValue = value
        self.signalLabel = titleKey
    }

    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use the slider initializer without an onEditingChanged callback and observe the value binding instead")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use the slider initializer without an onEditingChanged callback and observe the value binding instead")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use the slider initializer without an onEditingChanged callback and observe the value binding instead")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use the slider initializer without an onEditingChanged callback and observe the value binding instead")
    public init<S>(
        _ title: S,
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) where S: StringProtocol {
        self.sui = SwiftUI.Slider(
            value: value,
            in: bounds,
            label: { Text(title) },
            onEditingChanged: onEditingChanged
        )
        self.signalValue = value
        self.signalLabel = String(title)
    }
}

#endif
