//
//  SignalPicker.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/3/25.
//

import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalPicker<Label, SelectionValue, Content>: SignalingUI, View
    where Label: View, SelectionValue: Hashable, Content: View {
    
    let sui: SwiftUI.Picker<Label, SelectionValue, Content>
    let signalLabel: Any?
    let signalSelection: Binding<SelectionValue>
    
    public var body: some View {
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            return sui.onChange(of: signalSelection.wrappedValue) { newValue in
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
                    data: ["value": String(describing: newValue)]
                )
                Signals.emit(signal: signal, source: .autoSwiftUI)
            }
        } else {
            return sui
        }
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Picker"
    }
    
    static func extractLabel(_ label: Label, _ file: String? = nil, _ function: String? = nil, _ line: Int? = nil) -> String {
        let s = String(describing: label)
        var result: String
        
        let label = describe(label: s)
        if let label {
            result = label
        } else {
            if let file, let function, let line {
                result = "Unknown Label @ \(file), \(function), line \(line)"
            } else {
                result = "Unknown Label"
            }
        }
        return result
    }
}

// MARK: - Basic Initializers
extension SignalPicker {
    public init(
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.Picker(
            selection: selection,
            content: content,
            label: label
        )
        self.signalSelection = selection
        self.signalLabel = Self.extractLabel(label())
    }
}

// MARK: - Text Label Variants
extension SignalPicker where Label == Text {
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(
            titleKey,
            selection: selection,
            content: content
        )
        self.signalSelection = selection
        self.signalLabel = titleKey
    }

    public init<S>(
        _ title: S,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) where S: StringProtocol {
        self.sui = SwiftUI.Picker(
            title,
            selection: selection,
            content: content
        )
        self.signalSelection = selection
        self.signalLabel = String(title)
    }
}

// MARK: - Deprecated Variants
extension SignalPicker where Label == Text {
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter")
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        onCommit: @escaping () -> Void
    ) {
        self.sui = SwiftUI.Picker(
            titleKey,
            selection: selection,
            content: content
        )
        self.signalSelection = selection
        self.signalLabel = titleKey
    }

    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter")
    public init<S>(
        _ title: S,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        onCommit: @escaping () -> Void
    ) where S: StringProtocol {
        self.sui = SwiftUI.Picker(
            title,
            selection: selection,
            content: content
        )
        self.signalSelection = selection
        self.signalLabel = String(title)
    }
}
