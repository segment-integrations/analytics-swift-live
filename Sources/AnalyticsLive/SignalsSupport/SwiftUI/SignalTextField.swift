//
// SignalTextField.swift
//
//
//  Created by Alan Charles on 2/21/24.
//

import SwiftUI
import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal struct SignalFocused: ViewModifier {
    @FocusState private var focused: Bool
    private var signalLabel: Any?
    private var signalTitle: Any?
    private var signalPrompt: Any?
    private var component: String
    
    init(signalLabel: Any?, signalTitle: Any?, signalPrompt: Any?, component: String) {
        self.signalLabel = signalLabel
        self.signalTitle = signalTitle
        self.signalPrompt = signalPrompt
        self.component = component
        self.focused = false
    }
    
    func body(content: Content) -> some View {
        content
            .focused($focused)
            .onChange(of: focused) { focused in
                let value = describe(label: String(describing: signalLabel))
                let title = describeWith(options: [signalPrompt, signalTitle])
                let signal = InteractionSignal(component: component, title: title, data: ["value": value ?? "", "focused": focused])
                Signals.shared.emit(signal: signal, source: .autoSwiftUI)
            }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalTextField<Label>: SignalingUI, View where Label : View {
    let sui: SwiftUI.TextField<Label>
    let signalLabel: Any
    let signalTitle: Any?
    let signalPrompt: Any?
    
    public var body: some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return sui.modifier(
                SignalFocused(
                    signalLabel: signalLabel,
                    signalTitle: signalTitle,
                    signalPrompt: signalPrompt,
                    component: Self.controlType()
                )
            )
        } else {
            // Fallback on earlier versions
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
        return "TextField"
    }
}

extension SignalTextField where Label == Text {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<F>(_ titleKey: LocalizedStringKey, value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil) where F : ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(titleKey, value: value, format: format, prompt: prompt)
        self.signalLabel = value
        self.signalTitle = titleKey
        self.signalPrompt = prompt
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<S, F>(_ title: S, value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil) where S : StringProtocol, F : ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(title, value: value, format: format, prompt: prompt)
        self.signalLabel = value
        self.signalTitle = title
        self.signalPrompt = prompt
    }
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<F>(_ titleKey: LocalizedStringKey, value: Binding<F.FormatInput>, format: F, prompt: Text? = nil) where F : ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(titleKey, value: value, format: format, prompt: prompt)
        self.signalLabel = value
        self.signalTitle = titleKey
        self.signalPrompt = prompt
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<S, F>(_ title: S, value: Binding<F.FormatInput>, format: F, prompt: Text? = nil) where S : StringProtocol, F : ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(title, value: value, format: format, prompt: prompt)
        self.signalLabel = value
        self.signalTitle = title
        self.signalPrompt = prompt
    }
}

extension SignalTextField {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<F>(value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil, @ViewBuilder label: () -> Label) where F : ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(value: value, format: format, prompt: prompt, label: label)
        self.signalLabel = value
        self.signalTitle = Self.extractLabel(label())
        self.signalPrompt = prompt
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<F>(value: Binding<F.FormatInput>, format: F, prompt: Text? = nil, @ViewBuilder label: () -> Label) where F : ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(value: value, format: format, prompt: prompt, label: label)
        self.signalLabel = value
        self.signalTitle = Self.extractLabel(label())
        self.signalPrompt = prompt
    }
}

extension SignalTextField where Label == Text {
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter, prompt: Text?) {
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter, prompt: prompt)
        self.signalLabel = value
        self.signalTitle = titleKey
        self.signalPrompt = prompt
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter, prompt: Text?) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter, prompt: prompt)
        self.signalLabel = value
        self.signalTitle = title
        self.signalPrompt = prompt
    }
}

extension SignalTextField {
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<V>(value: Binding<V>, formatter: Formatter, prompt: Text? = nil, @ViewBuilder label: () -> Label) {
        self.sui = SwiftUI.TextField(value: value, formatter: formatter, prompt: prompt, label: label)
        self.signalLabel = value
        self.signalTitle = Self.extractLabel(label())
        self.signalPrompt = prompt
    }
}

extension SignalTextField where Label == Text {
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter) {
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter)
        self.signalLabel = value
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter)
        self.signalLabel = value
        self.signalTitle = title
        self.signalPrompt = nil
    }
}


extension SignalTextField where Label == Text {
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter, onEditingChanged: @escaping (Bool) -> Void, onCommit: @escaping () -> Void) {
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter, onEditingChanged: onEditingChanged, onCommit: onCommit)
        self.signalLabel = value
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter, onEditingChanged: @escaping (Bool) -> Void) {
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter, onEditingChanged: onEditingChanged)
        self.signalLabel = value
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter, onCommit: @escaping () -> Void) {
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter, onCommit: onCommit)
        self.signalLabel = value
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter, onEditingChanged: @escaping (Bool) -> Void, onCommit: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter, onEditingChanged: onEditingChanged, onCommit: onCommit)
        self.signalLabel = value
        self.signalTitle = title
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter, onEditingChanged: @escaping (Bool) -> Void) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter, onEditingChanged: onEditingChanged)
        self.signalLabel = value
        self.signalTitle = title
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:value:formatter:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter, onCommit: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter, onCommit: onCommit)
        self.signalLabel = value
        self.signalTitle = title
        self.signalPrompt = nil
    }
}

extension SignalTextField where Label == Text {
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, axis: Axis) {
        self.sui = SwiftUI.TextField(titleKey, text: text, axis: axis)
        self.signalLabel = text
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text?, axis: Axis) {
        self.sui = SwiftUI.TextField(titleKey, text: text, prompt: prompt, axis: axis)
        self.signalLabel = text
        self.signalTitle = titleKey
        self.signalPrompt = prompt
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init<S>(_ title: S, text: Binding<String>, axis: Axis) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, axis: axis)
        self.signalLabel = text
        self.signalTitle = title
        self.signalPrompt = nil
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init<S>(_ title: S, text: Binding<String>, prompt: Text?, axis: Axis) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, prompt: prompt, axis: axis)
        self.signalLabel = text
        self.signalTitle = title
        self.signalPrompt = prompt
    }
}

extension SignalTextField {
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(text: Binding<String>, prompt: Text? = nil, axis: Axis, @ViewBuilder label: () -> Label) {
        self.sui = SwiftUI.TextField(text: text, prompt: prompt, axis: axis, label: label)
        self.signalLabel = text
        self.signalTitle = Self.extractLabel(label())
        self.signalPrompt = prompt
    }
}

extension SignalTextField where Label == Text {
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text?) {
        self.sui = SwiftUI.TextField(titleKey, text: text, prompt: prompt)
        self.signalLabel = text
        self.signalTitle = titleKey
        self.signalPrompt = prompt
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<S>(_ title: S, text: Binding<String>, prompt: Text?) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, prompt: prompt)
        self.signalLabel = text
        self.signalTitle = title
        self.signalPrompt = prompt
    }
}

extension SignalTextField {
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init(text: Binding<String>, prompt: Text? = nil, @ViewBuilder label: () -> Label) {
        self.sui = SwiftUI.TextField(text: text, prompt: prompt, label: label)
        self.signalLabel = text
        self.signalTitle = Self.extractLabel(label())
        self.signalPrompt = prompt
    }
}

extension SignalTextField where Label == Text {
    
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>) {
        self.sui = SwiftUI.TextField(titleKey, text: text)
        self.signalLabel = text
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public init<S>(_ title: S, text: Binding<String>) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text)
        self.signalLabel = text
        self.signalTitle = title
        self.signalPrompt = nil
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalTextField where Label == Text {
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, onEditingChanged: @escaping (Bool) -> Void, onCommit: @escaping () -> Void) {
        self.sui = SwiftUI.TextField(titleKey, text: text, onEditingChanged: { editing in
            let value = describe(label: String(describing: text))
            let title = describeWith(options: [titleKey])
            let signal = InteractionSignal(component: Self.controlType(), title: title, data: ["value": value ?? "", "focused": editing])
            Signals.shared.emit(signal: signal, source: .autoSwiftUI)
            onEditingChanged(editing)
        }, onCommit: onCommit)
        self.signalLabel = text
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, onEditingChanged: @escaping (Bool) -> Void) {
        self.sui = SwiftUI.TextField(titleKey, text: text, onEditingChanged: { editing in
            let value = describe(label: String(describing: text))
            let title = describeWith(options: [titleKey])
            let signal = InteractionSignal(component: Self.controlType(), title: title, data: ["value": value ?? "", "focused": editing])
            Signals.shared.emit(signal: signal, source: .autoSwiftUI)
            onEditingChanged(editing)
        })
        self.signalLabel = text
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, onCommit: @escaping () -> Void) {
        self.sui = SwiftUI.TextField(titleKey, text: text, onEditingChanged: { editing in
            let value = describe(label: String(describing: text))
            let title = describeWith(options: [titleKey])
            let signal = InteractionSignal(component: Self.controlType(), title: title, data: ["value": value ?? "", "focused": editing])
            Signals.shared.emit(signal: signal, source: .autoSwiftUI)
        }, onCommit: onCommit)
        self.signalLabel = text
        self.signalTitle = titleKey
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init<S>(_ title: S, text: Binding<String>, onEditingChanged: @escaping (Bool) -> Void, onCommit: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, onEditingChanged: { editing in
            let value = describe(label: String(describing: text))
            let title = describeWith(options: [title])
            let signal = InteractionSignal(component: Self.controlType(), title: title, data: ["value": value ?? "", "focused": editing])
            Signals.shared.emit(signal: signal, source: .autoSwiftUI)
            onEditingChanged(editing)
        }, onCommit: onCommit)
        self.signalLabel = text
        self.signalTitle = title
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init<S>(_ title: S, text: Binding<String>, onEditingChanged: @escaping (Bool) -> Void) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, onEditingChanged: { editing in
            let value = describe(label: String(describing: text))
            let title = describeWith(options: [title])
            let signal = InteractionSignal(component: Self.controlType(), title: title, data: ["value": value ?? "", "focused": editing])
            Signals.shared.emit(signal: signal, source: .autoSwiftUI)
            onEditingChanged(editing)
        })
        self.signalLabel = text
        self.signalTitle = title
        self.signalPrompt = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Renamed TextField.init(_:text:onEditingChanged:). Use View.onSubmit(of:_:) for functionality previously provided by the onCommit parameter. Use FocusState<T> and View.focused(_:equals:) for functionality previously provided by the onEditingChanged parameter.")
    public init<S>(_ title: S, text: Binding<String>, onCommit: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, onEditingChanged: { editing in
            let value = describe(label: String(describing: text))
            let title = describeWith(options: [title])
            let signal = InteractionSignal(component: Self.controlType(), title: title, data: ["value": value ?? "", "focused": editing])
            Signals.shared.emit(signal: signal, source: .autoSwiftUI)
        }, onCommit: onCommit)
        self.signalLabel = text
        self.signalTitle = title
        self.signalPrompt = nil
    }
}

