//
//  SwiftUIView.swift
//  
//
//  Created by Alan Charles on 2/22/24.
//

import SwiftUI


@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalSecureField<Label>: SignalingUI, View where Label: View {
    let sui: SwiftUI.SecureField<Label>
    let signalTitle: Any?
    let signalPrompt: Any?
    
    public var body: some View {
        if #available(iOS 15, macOS 12.0, *)  {
            return sui.modifier(SignalFocused(signalLabel: nil, signalTitle: signalTitle, signalPrompt: signalPrompt, component: Self.controlType()))
        } else {
            return sui
        }
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
    
    @inline(__always)
    static public func controlType() -> String {
         return "SecureField"
    }
}

extension SignalSecureField where Label == Text {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text?) {
        self.sui = SecureField(titleKey, text: text, prompt: prompt)
        self.signalTitle = titleKey
        self.signalPrompt = prompt
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<S>(_ title: S, text: Binding<String>, prompt: Text?) where S : StringProtocol {
        self.sui = SecureField(title, text: text, prompt: prompt)
        self.signalTitle = title
        self.signalPrompt = prompt
    }
}

extension SignalSecureField {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init(text: Binding<String>, prompt: Text? = nil, @ViewBuilder label: () -> Label) {
        self.sui = SecureField(text: text, prompt: prompt, label: label)
        self.signalTitle = Self.extractLabel(label())
        self.signalPrompt = prompt
    }
}

extension SignalSecureField where Label == Text {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>) {
        self.sui = SecureField(titleKey, text: text)
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public init<S>(_ title: S, text: Binding<String>) where S : StringProtocol {
        self.sui = SecureField(title, text: text)
        self.signalTitle = title
        self.signalPrompt = nil
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalSecureField where Label == Text {

    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, onCommit: @escaping () -> Void) {
        self.sui = SecureField(titleKey, text: text)
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }

    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Renamed SecureField.init(_:text:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter.")
    public init<S>(_ title: S, text: Binding<String>, onCommit: @escaping () -> Void) where S : StringProtocol {
        self.sui = SecureField(title, text: text, onCommit: onCommit)
        self.signalTitle = title
        self.signalPrompt = nil
    }
}
