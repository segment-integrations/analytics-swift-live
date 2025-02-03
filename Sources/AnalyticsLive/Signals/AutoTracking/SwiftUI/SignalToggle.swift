//
//  SignalToggle.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/3/25.
//

import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalToggle<Label>: SignalingUI, View where Label: View {
    let sui: SwiftUI.Toggle<Label>
    let signalLabel: Any?
    let signalIsOn: Binding<Bool>
    
    public var body: some View {
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            return sui.onChange(of: signalIsOn.wrappedValue) { newValue in
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
            return sui
        }
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Toggle"
    }
}

// MARK: - Basic Initializers
extension SignalToggle {
    public init(isOn: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self.sui = SwiftUI.Toggle(isOn: isOn, label: label)
        self.signalIsOn = isOn
        self.signalLabel = Self.extractLabel(label())
    }
}

// MARK: - Text Label Variants
extension SignalToggle where Label == Text {
    public init(_ titleKey: LocalizedStringKey, isOn: Binding<Bool>) {
        self.sui = SwiftUI.Toggle(titleKey, isOn: isOn)
        self.signalIsOn = isOn
        self.signalLabel = titleKey
    }
    
    public init<S>(_ title: S, isOn: Binding<Bool>) where S: StringProtocol {
        self.sui = SwiftUI.Toggle(title, isOn: isOn)
        self.signalIsOn = isOn
        self.signalLabel = String(title)
    }
}

// MARK: - Deprecated Variants
extension SignalToggle where Label == Text {
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use Toggle.init(_:isOn:) instead")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use Toggle.init(_:isOn:) instead")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use Toggle.init(_:isOn:) instead")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use Toggle.init(_:isOn:) instead")
    public init(isOn: Binding<Bool>, label: Text) {
        self.sui = SwiftUI.Toggle(isOn: isOn, label: { label })
        self.signalIsOn = isOn
        self.signalLabel = String(describing: label)
    }
}
