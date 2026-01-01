//
//  SignalTextField.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/1/24.
//

import SwiftUI
import Foundation

// MARK: - SignalTextFieldFocused Modifier

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal struct SignalTextFieldFocused: ViewModifier {
    @FocusState private var isFocused: Bool
    let title: String?
    let valueExtractor: () -> String
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content
                .focused($isFocused)
                .onChange(of: isFocused) { oldValue, newValue in
                    emitSignal(focused: newValue)
                }
        } else {
            content
                .focused($isFocused)
                .onChange(of: isFocused) { newValue in
                    emitSignal(focused: newValue)
                }
        }
    }
    
    private func emitSignal(focused: Bool) {
        let value = valueExtractor()
        let signal = InteractionSignal(
            component: "TextField",
            title: title,
            data: [
                "focused": focused,
                "value": value,
                "isEmpty": value.isEmpty,
                "characterCount": value.count
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
}

// MARK: - SignalTextField

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalTextField<Label>: SignalingUI, View where Label: View {
    let sui: SwiftUI.TextField<Label>
    let extractedTitle: String?
    let valueExtractor: () -> String
    
    public var body: some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            sui.modifier(SignalTextFieldFocused(
                title: extractedTitle,
                valueExtractor: valueExtractor
            ))
        } else {
            // Pre-iOS 15: no FocusState, just show the field without signals
            // UIKit swizzler will catch it if they're using UIKit underneath
            sui
        }
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "TextField"
    }
}

// MARK: - Basic Text Binding (iOS 15+)
// Note: Simple init(_:text:) without prompt is iOS 26+, so we use prompt variant for backwards compatibility

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalTextField where Label == Text {
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>) {
        self.sui = SwiftUI.TextField(titleKey, text: text, prompt: nil)
        self.extractedTitle = titleKey.string
        self.valueExtractor = { text.wrappedValue }
    }
    
    public init<S>(_ title: S, text: Binding<String>) where S: StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, prompt: nil)
        self.extractedTitle = String(title)
        self.valueExtractor = { text.wrappedValue }
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, text: Binding<String>) {
        self.sui = SwiftUI.TextField(titleResource, text: text, prompt: nil)
        self.extractedTitle = titleResource.string
        self.valueExtractor = { text.wrappedValue }
    }
}

// MARK: - Text Binding with Prompt (iOS 15+)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalTextField where Label == Text {
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text?) {
        self.sui = SwiftUI.TextField(titleKey, text: text, prompt: prompt)
        self.extractedTitle = titleKey.string
        self.valueExtractor = { text.wrappedValue }
    }
    
    public init<S>(_ title: S, text: Binding<String>, prompt: Text?) where S: StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, prompt: prompt)
        self.extractedTitle = String(title)
        self.valueExtractor = { text.wrappedValue }
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, text: Binding<String>, prompt: Text?) {
        self.sui = SwiftUI.TextField(titleResource, text: text, prompt: prompt)
        self.extractedTitle = titleResource.string
        self.valueExtractor = { text.wrappedValue }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalTextField {
    public init(text: Binding<String>, prompt: Text? = nil, @ViewBuilder label: () -> Label) {
        self.sui = SwiftUI.TextField(text: text, prompt: prompt, label: label)
        self.extractedTitle = Self.extractLabel(label())
        self.valueExtractor = { text.wrappedValue }
    }
}

// MARK: - Text Binding with Axis (iOS 16+)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalTextField where Label == Text {
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, axis: Axis) {
        self.sui = SwiftUI.TextField(titleKey, text: text, axis: axis)
        self.extractedTitle = titleKey.string
        self.valueExtractor = { text.wrappedValue }
    }
    
    public init<S>(_ title: S, text: Binding<String>, axis: Axis) where S: StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, axis: axis)
        self.extractedTitle = String(title)
        self.valueExtractor = { text.wrappedValue }
    }
    
    public init(_ titleResource: LocalizedStringResource, text: Binding<String>, axis: Axis) {
        self.sui = SwiftUI.TextField(titleResource, text: text, axis: axis)
        self.extractedTitle = titleResource.string
        self.valueExtractor = { text.wrappedValue }
    }
    
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text?, axis: Axis) {
        self.sui = SwiftUI.TextField(titleKey, text: text, prompt: prompt, axis: axis)
        self.extractedTitle = titleKey.string
        self.valueExtractor = { text.wrappedValue }
    }
    
    public init<S>(_ title: S, text: Binding<String>, prompt: Text?, axis: Axis) where S: StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, prompt: prompt, axis: axis)
        self.extractedTitle = String(title)
        self.valueExtractor = { text.wrappedValue }
    }
    
    public init(_ titleResource: LocalizedStringResource, text: Binding<String>, prompt: Text?, axis: Axis) {
        self.sui = SwiftUI.TextField(titleResource, text: text, prompt: prompt, axis: axis)
        self.extractedTitle = titleResource.string
        self.valueExtractor = { text.wrappedValue }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalTextField {
    public init(text: Binding<String>, prompt: Text? = nil, axis: Axis, @ViewBuilder label: () -> Label) {
        self.sui = SwiftUI.TextField(text: text, prompt: prompt, axis: axis, label: label)
        self.extractedTitle = Self.extractLabel(label())
        self.valueExtractor = { text.wrappedValue }
    }
}

// MARK: - Value with ParseableFormatStyle (iOS 15+)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalTextField where Label == Text {
    public init<F>(_ titleKey: LocalizedStringKey, value: Binding<F.FormatInput>, format: F, prompt: Text? = nil) where F: ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(titleKey, value: value, format: format, prompt: prompt)
        self.extractedTitle = titleKey.string
        self.valueExtractor = { format.format(value.wrappedValue) }
    }
    
    public init<S, F>(_ title: S, value: Binding<F.FormatInput>, format: F, prompt: Text? = nil) where S: StringProtocol, F: ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(title, value: value, format: format, prompt: prompt)
        self.extractedTitle = String(title)
        self.valueExtractor = { format.format(value.wrappedValue) }
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init<F>(_ titleResource: LocalizedStringResource, value: Binding<F.FormatInput>, format: F, prompt: Text? = nil) where F: ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(titleResource, value: value, format: format, prompt: prompt)
        self.extractedTitle = titleResource.string
        self.valueExtractor = { format.format(value.wrappedValue) }
    }
    
    // Optional FormatInput variants
    public init<F>(_ titleKey: LocalizedStringKey, value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil) where F: ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(titleKey, value: value, format: format, prompt: prompt)
        self.extractedTitle = titleKey.string
        self.valueExtractor = { 
            if let v = value.wrappedValue {
                return format.format(v)
            }
            return ""
        }
    }
    
    public init<S, F>(_ title: S, value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil) where S: StringProtocol, F: ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(title, value: value, format: format, prompt: prompt)
        self.extractedTitle = String(title)
        self.valueExtractor = { 
            if let v = value.wrappedValue {
                return format.format(v)
            }
            return ""
        }
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init<F>(_ titleResource: LocalizedStringResource, value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil) where F: ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(titleResource, value: value, format: format, prompt: prompt)
        self.extractedTitle = titleResource.string
        self.valueExtractor = { 
            if let v = value.wrappedValue {
                return format.format(v)
            }
            return ""
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalTextField {
    public init<F>(value: Binding<F.FormatInput>, format: F, prompt: Text? = nil, @ViewBuilder label: () -> Label) where F: ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(value: value, format: format, prompt: prompt, label: label)
        self.extractedTitle = Self.extractLabel(label())
        self.valueExtractor = { format.format(value.wrappedValue) }
    }
    
    public init<F>(value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil, @ViewBuilder label: () -> Label) where F: ParseableFormatStyle, F.FormatOutput == String {
        self.sui = SwiftUI.TextField(value: value, format: format, prompt: prompt, label: label)
        self.extractedTitle = Self.extractLabel(label())
        self.valueExtractor = { 
            if let v = value.wrappedValue {
                return format.format(v)
            }
            return ""
        }
    }
}

// MARK: - Value with Formatter (iOS 13+)

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalTextField where Label == Text {
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter) {
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter)
        self.extractedTitle = titleKey.string
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
    }
    
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter) where S: StringProtocol {
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter)
        self.extractedTitle = String(title)
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init<V>(_ titleResource: LocalizedStringResource, value: Binding<V>, formatter: Formatter) {
        self.sui = SwiftUI.TextField(titleResource, value: value, formatter: formatter)
        self.extractedTitle = titleResource.string
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalTextField where Label == Text {
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter, prompt: Text?) {
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter, prompt: prompt)
        self.extractedTitle = titleKey.string
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
    }
    
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter, prompt: Text?) where S: StringProtocol {
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter, prompt: prompt)
        self.extractedTitle = String(title)
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init<V>(_ titleResource: LocalizedStringResource, value: Binding<V>, formatter: Formatter, prompt: Text?) {
        self.sui = SwiftUI.TextField(titleResource, value: value, formatter: formatter, prompt: prompt)
        self.extractedTitle = titleResource.string
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalTextField {
    public init<V>(value: Binding<V>, formatter: Formatter, prompt: Text? = nil, @ViewBuilder label: () -> Label) {
        self.sui = SwiftUI.TextField(value: value, formatter: formatter, prompt: prompt, label: label)
        self.extractedTitle = Self.extractLabel(label())
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
    }
}

// MARK: - Deprecated onEditingChanged/onCommit Variants (iOS 13+)
// These wrap the callbacks to emit signals

@available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) and FocusState instead.")
@available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) and FocusState instead.")
@available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) and FocusState instead.")
@available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) and FocusState instead.")
extension SignalTextField where Label == Text {
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, onEditingChanged: @escaping (Bool) -> Void, onCommit: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.valueExtractor = { text.wrappedValue }
        let title = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(titleKey, text: text, onEditingChanged: { focused in
            Self.emitSignalStatic(title: title, focused: focused, valueExtractor: extractor)
            onEditingChanged(focused)
        }, onCommit: onCommit)
    }
    
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, onEditingChanged: @escaping (Bool) -> Void) {
        self.extractedTitle = titleKey.string
        self.valueExtractor = { text.wrappedValue }
        let title = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(titleKey, text: text, onEditingChanged: { focused in
            Self.emitSignalStatic(title: title, focused: focused, valueExtractor: extractor)
            onEditingChanged(focused)
        })
    }
    
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, onCommit: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.valueExtractor = { text.wrappedValue }
        let title = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(titleKey, text: text, onEditingChanged: { focused in
            Self.emitSignalStatic(title: title, focused: focused, valueExtractor: extractor)
        }, onCommit: onCommit)
    }
    
    public init<S>(_ title: S, text: Binding<String>, onEditingChanged: @escaping (Bool) -> Void, onCommit: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.valueExtractor = { text.wrappedValue }
        let titleStr = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(title, text: text, onEditingChanged: { focused in
            Self.emitSignalStatic(title: titleStr, focused: focused, valueExtractor: extractor)
            onEditingChanged(focused)
        }, onCommit: onCommit)
    }
    
    public init<S>(_ title: S, text: Binding<String>, onEditingChanged: @escaping (Bool) -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.valueExtractor = { text.wrappedValue }
        let titleStr = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(title, text: text, onEditingChanged: { focused in
            Self.emitSignalStatic(title: titleStr, focused: focused, valueExtractor: extractor)
            onEditingChanged(focused)
        })
    }
    
    public init<S>(_ title: S, text: Binding<String>, onCommit: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.valueExtractor = { text.wrappedValue }
        let titleStr = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(title, text: text, onEditingChanged: { focused in
            Self.emitSignalStatic(title: titleStr, focused: focused, valueExtractor: extractor)
        }, onCommit: onCommit)
    }
    
    // Helper for deprecated inits that need to emit from closure context
    private static func emitSignalStatic(title: String?, focused: Bool, valueExtractor: () -> String) {
        let value = valueExtractor()
        let signal = InteractionSignal(
            component: controlType(),
            title: title,
            data: [
                "focused": focused,
                "value": value,
                "isEmpty": value.isEmpty,
                "characterCount": value.count
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
}

// MARK: - Deprecated Formatter + onEditingChanged/onCommit Variants

@available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) and FocusState instead.")
@available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) and FocusState instead.")
@available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) and FocusState instead.")
@available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) and FocusState instead.")
extension SignalTextField where Label == Text {
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter, onEditingChanged: @escaping (Bool) -> Void, onCommit: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
        let title = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter, onEditingChanged: { focused in
            Self.emitSignalStatic(title: title, focused: focused, valueExtractor: extractor)
            onEditingChanged(focused)
        }, onCommit: onCommit)
    }
    
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter, onEditingChanged: @escaping (Bool) -> Void) {
        self.extractedTitle = titleKey.string
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
        let title = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter, onEditingChanged: { focused in
            Self.emitSignalStatic(title: title, focused: focused, valueExtractor: extractor)
            onEditingChanged(focused)
        })
    }
    
    public init<V>(_ titleKey: LocalizedStringKey, value: Binding<V>, formatter: Formatter, onCommit: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
        let title = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(titleKey, value: value, formatter: formatter, onEditingChanged: { focused in
            Self.emitSignalStatic(title: title, focused: focused, valueExtractor: extractor)
        }, onCommit: onCommit)
    }
    
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter, onEditingChanged: @escaping (Bool) -> Void, onCommit: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
        let titleStr = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter, onEditingChanged: { focused in
            Self.emitSignalStatic(title: titleStr, focused: focused, valueExtractor: extractor)
            onEditingChanged(focused)
        }, onCommit: onCommit)
    }
    
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter, onEditingChanged: @escaping (Bool) -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
        let titleStr = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter, onEditingChanged: { focused in
            Self.emitSignalStatic(title: titleStr, focused: focused, valueExtractor: extractor)
            onEditingChanged(focused)
        })
    }
    
    public init<S, V>(_ title: S, value: Binding<V>, formatter: Formatter, onCommit: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.valueExtractor = { formatter.string(for: value.wrappedValue) ?? "" }
        let titleStr = self.extractedTitle
        let extractor = self.valueExtractor
        self.sui = SwiftUI.TextField(title, value: value, formatter: formatter, onEditingChanged: { focused in
            Self.emitSignalStatic(title: titleStr, focused: focused, valueExtractor: extractor)
        }, onCommit: onCommit)
    }
}

// MARK: - Text Binding with Selection (iOS 18+)

@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
@available(watchOS, unavailable)
extension SignalTextField where Label == Text {
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, selection: Binding<TextSelection?>, prompt: Text? = nil, axis: Axis? = nil) {
        self.sui = SwiftUI.TextField(titleKey, text: text, selection: selection, prompt: prompt, axis: axis)
        self.extractedTitle = titleKey.string
        self.valueExtractor = { text.wrappedValue }
    }
    
    public init<S>(_ title: S, text: Binding<String>, selection: Binding<TextSelection?>, prompt: Text? = nil, axis: Axis? = nil) where S: StringProtocol {
        self.sui = SwiftUI.TextField(title, text: text, selection: selection, prompt: prompt, axis: axis)
        self.extractedTitle = String(title)
        self.valueExtractor = { text.wrappedValue }
    }
    
    public init(_ titleResource: LocalizedStringResource, text: Binding<String>, selection: Binding<TextSelection?>, prompt: Text? = nil, axis: Axis? = nil) {
        self.sui = SwiftUI.TextField(titleResource, text: text, selection: selection, prompt: prompt, axis: axis)
        self.extractedTitle = titleResource.string
        self.valueExtractor = { text.wrappedValue }
    }
}
