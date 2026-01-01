//
//  SignalSecureField.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/22/24.
//

import SwiftUI
import Foundation

// MARK: - SignalSecureFieldFocused Modifier

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal struct SignalSecureFieldFocused: ViewModifier {
    @FocusState private var isFocused: Bool
    let title: String?
    let characterCountExtractor: () -> Int
    
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
        let count = characterCountExtractor()
        let signal = InteractionSignal(
            component: "SecureField",
            title: title,
            data: [
                "focused": focused,
                "isEmpty": count == 0,
                "characterCount": count
                // Note: value intentionally omitted for security
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
}

// MARK: - SignalSecureField

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalSecureField<Label>: SignalingUI, View where Label: View {
    let sui: SwiftUI.SecureField<Label>
    let extractedTitle: String?
    let characterCountExtractor: () -> Int
    
    public var body: some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            sui.modifier(SignalSecureFieldFocused(
                title: extractedTitle,
                characterCountExtractor: characterCountExtractor
            ))
        } else {
            // Pre-iOS 15: no FocusState, just show the field without signals
            sui
        }
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "SecureField"
    }
}

// MARK: - Basic Text Binding (iOS 15+)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalSecureField where Label == Text {
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>) {
        self.sui = SwiftUI.SecureField(titleKey, text: text, prompt: nil)
        self.extractedTitle = titleKey.string
        self.characterCountExtractor = { text.wrappedValue.count }
    }
    
    public init<S>(_ title: S, text: Binding<String>) where S: StringProtocol {
        self.sui = SwiftUI.SecureField(title, text: text, prompt: nil)
        self.extractedTitle = String(title)
        self.characterCountExtractor = { text.wrappedValue.count }
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, text: Binding<String>) {
        self.sui = SwiftUI.SecureField(titleResource, text: text, prompt: nil)
        self.extractedTitle = titleResource.string
        self.characterCountExtractor = { text.wrappedValue.count }
    }
}

// MARK: - Text Binding with Prompt (iOS 15+)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalSecureField where Label == Text {
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text?) {
        self.sui = SwiftUI.SecureField(titleKey, text: text, prompt: prompt)
        self.extractedTitle = titleKey.string
        self.characterCountExtractor = { text.wrappedValue.count }
    }
    
    public init<S>(_ title: S, text: Binding<String>, prompt: Text?) where S: StringProtocol {
        self.sui = SwiftUI.SecureField(title, text: text, prompt: prompt)
        self.extractedTitle = String(title)
        self.characterCountExtractor = { text.wrappedValue.count }
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, text: Binding<String>, prompt: Text?) {
        self.sui = SwiftUI.SecureField(titleResource, text: text, prompt: prompt)
        self.extractedTitle = titleResource.string
        self.characterCountExtractor = { text.wrappedValue.count }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalSecureField {
    public init(text: Binding<String>, prompt: Text? = nil, @ViewBuilder label: () -> Label) {
        self.sui = SwiftUI.SecureField(text: text, prompt: prompt, label: label)
        self.extractedTitle = Self.extractLabel(label())
        self.characterCountExtractor = { text.wrappedValue.count }
    }
}

// MARK: - Deprecated onCommit Variants

@available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) instead.")
@available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) instead.")
@available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) instead.")
@available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Use View.onSubmit(of:_:) instead.")
extension SignalSecureField where Label == Text {
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, onCommit: @escaping () -> Void) {
        self.sui = SwiftUI.SecureField(titleKey, text: text, onCommit: onCommit)
        self.extractedTitle = titleKey.string
        self.characterCountExtractor = { text.wrappedValue.count }
    }
    
    public init<S>(_ title: S, text: Binding<String>, onCommit: @escaping () -> Void) where S: StringProtocol {
        self.sui = SwiftUI.SecureField(title, text: text, onCommit: onCommit)
        self.extractedTitle = String(title)
        self.characterCountExtractor = { text.wrappedValue.count }
    }
}
