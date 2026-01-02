//
//  SignalButton.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/1/24.
//

import Foundation
import SwiftUI

// MARK: - SignalButton

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalButton<Label>: SignalingUI, View where Label: View {
    let sui: SwiftUI.Button<Label>
    let extractedTitle: String?
    
    public var body: some View {
        sui
    }
    
    private static func wrappedAction(title: String?, action: @escaping () -> Void) -> () -> Void {
        return {
            action()
            emitSignal(title: title)
        }
    }
    
    private static func emitSignal(title: String?) {
        let signal = InteractionSignal(
            component: controlType(),
            title: title,
            data: ["action": "tapped"]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Button"
    }
}

// MARK: - Basic Initializers

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalButton {
    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.extractedTitle = Self.extractLabel(label())
        self.sui = SwiftUI.Button(action: Self.wrappedAction(title: extractedTitle, action: action), label: label)
    }
}

// MARK: - Text Label Variants

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalButton where Label == Text {
    public init(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.sui = SwiftUI.Button(titleKey, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    public init<S>(_ title: S, action: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.sui = SwiftUI.Button(title, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, action: @escaping () -> Void) {
        self.extractedTitle = titleResource.string
        self.sui = SwiftUI.Button(titleResource, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
}

// MARK: - Label with systemImage Variants (iOS 14+)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.sui = SwiftUI.Button(titleKey, systemImage: systemImage, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    public init<S>(_ title: S, systemImage: String, action: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.sui = SwiftUI.Button(title, systemImage: systemImage, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, systemImage: String, action: @escaping () -> Void) {
        self.extractedTitle = titleResource.string
        self.sui = SwiftUI.Button(titleResource, systemImage: systemImage, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
}

// MARK: - Label with ImageResource Variants (iOS 17+)

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, image: ImageResource, action: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.sui = SwiftUI.Button(titleKey, image: image, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    public init<S>(_ title: S, image: ImageResource, action: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.sui = SwiftUI.Button(title, image: image, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public init(_ titleResource: LocalizedStringResource, image: ImageResource, action: @escaping () -> Void) {
        self.extractedTitle = titleResource.string
        self.sui = SwiftUI.Button(titleResource, image: image, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
}

// MARK: - Role Variants (iOS 15+)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalButton {
    public init(role: ButtonRole?, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.extractedTitle = Self.extractLabel(label())
        self.sui = SwiftUI.Button(role: role, action: Self.wrappedAction(title: extractedTitle, action: action), label: label)
    }
}

// MARK: - Role + Text Variants (iOS 15+)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalButton where Label == Text {
    public init(_ titleKey: LocalizedStringKey, role: ButtonRole?, action: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.sui = SwiftUI.Button(titleKey, role: role, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    public init<S>(_ title: S, role: ButtonRole?, action: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.sui = SwiftUI.Button(title, role: role, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, role: ButtonRole?, action: @escaping () -> Void) {
        self.extractedTitle = titleResource.string
        self.sui = SwiftUI.Button(titleResource, role: role, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
}

// MARK: - Role + systemImage Variants (iOS 15+)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, systemImage: String, role: ButtonRole?, action: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.sui = SwiftUI.Button(titleKey, systemImage: systemImage, role: role, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    public init<S>(_ title: S, systemImage: String, role: ButtonRole?, action: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.sui = SwiftUI.Button(title, systemImage: systemImage, role: role, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, systemImage: String, role: ButtonRole?, action: @escaping () -> Void) {
        self.extractedTitle = titleResource.string
        self.sui = SwiftUI.Button(titleResource, systemImage: systemImage, role: role, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
}

// MARK: - Role + ImageResource Variants (iOS 17+)

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, image: ImageResource, role: ButtonRole?, action: @escaping () -> Void) {
        self.extractedTitle = titleKey.string
        self.sui = SwiftUI.Button(titleKey, image: image, role: role, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    public init<S>(_ title: S, image: ImageResource, role: ButtonRole?, action: @escaping () -> Void) where S: StringProtocol {
        self.extractedTitle = String(title)
        self.sui = SwiftUI.Button(title, image: image, role: role, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
    
    public init(_ titleResource: LocalizedStringResource, image: ImageResource, role: ButtonRole?, action: @escaping () -> Void) {
        self.extractedTitle = titleResource.string
        self.sui = SwiftUI.Button(titleResource, image: image, role: role, action: Self.wrappedAction(title: extractedTitle, action: action))
    }
}

// MARK: - DefaultButtonLabel Variant (iOS 26+)

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
extension SignalButton where Label == DefaultButtonLabel {
    public init(role: ButtonRole, action: @escaping () -> Void) {
        self.extractedTitle = nil
        self.sui = SwiftUI.Button(role: role, action: Self.wrappedAction(title: nil, action: action))
    }
}

// MARK: - PrimitiveButtonStyleConfiguration (passthrough, no signal)

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalButton where Label == PrimitiveButtonStyleConfiguration.Label {
    public init(_ configuration: PrimitiveButtonStyleConfiguration) {
        self.sui = SwiftUI.Button(configuration)
        self.extractedTitle = nil
        #if DEBUG
        print("""
        [SignalButton] PrimitiveButtonStyleConfiguration buttons don't expose a label or action for signal capture.
        To track this interaction, use SignalButton at the call site instead of inside your PrimitiveButtonStyle:
            SignalButton("Title") { action() }
                .buttonStyle(MyCustomStyle())
        """)
        #endif
    }
}

// MARK: - AppIntent Variants (iOS 17+, passthrough with instructions)

#if canImport(AppIntents)
import AppIntents

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton where Label == Text {
    public init(_ titleKey: LocalizedStringKey, intent: some AppIntent) {
        self.sui = SwiftUI.Button(titleKey, intent: intent)
        self.extractedTitle = titleKey.string
        Self.printAppIntentInstructions(title: extractedTitle)
    }
    
    public init(_ titleResource: LocalizedStringResource, intent: some AppIntent) {
        self.sui = SwiftUI.Button(titleResource, intent: intent)
        self.extractedTitle = titleResource.string
        Self.printAppIntentInstructions(title: extractedTitle)
    }
    
    public init<S>(_ title: S, intent: some AppIntent) where S: StringProtocol {
        self.sui = SwiftUI.Button(title, intent: intent)
        self.extractedTitle = String(title)
        Self.printAppIntentInstructions(title: extractedTitle)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton {
    public init(role: ButtonRole?, intent: some AppIntent, @ViewBuilder label: () -> Label) {
        self.sui = SwiftUI.Button(role: role, intent: intent, label: label)
        self.extractedTitle = Self.extractLabel(label())
        Self.printAppIntentInstructions(title: extractedTitle)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton where Label == Text {
    public init(_ titleKey: LocalizedStringKey, role: ButtonRole?, intent: some AppIntent) {
        self.sui = SwiftUI.Button(titleKey, role: role, intent: intent)
        self.extractedTitle = titleKey.string
        Self.printAppIntentInstructions(title: extractedTitle)
    }
    
    public init(_ titleResource: LocalizedStringResource, role: ButtonRole?, intent: some AppIntent) {
        self.sui = SwiftUI.Button(titleResource, role: role, intent: intent)
        self.extractedTitle = titleResource.string
        Self.printAppIntentInstructions(title: extractedTitle)
    }
    
    public init(_ title: some StringProtocol, role: ButtonRole?, intent: some AppIntent) {
        self.sui = SwiftUI.Button(title, role: role, intent: intent)
        self.extractedTitle = String(title)
        Self.printAppIntentInstructions(title: extractedTitle)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, systemImage: String, role: ButtonRole? = nil, intent: some AppIntent) {
        self.sui = SwiftUI.Button(titleKey, systemImage: systemImage, role: role, intent: intent)
        self.extractedTitle = titleKey.string
        Self.printAppIntentInstructions(title: extractedTitle)
    }
    
    public init(_ titleResource: LocalizedStringResource, systemImage: String, role: ButtonRole? = nil, intent: some AppIntent) {
        self.sui = SwiftUI.Button(titleResource, systemImage: systemImage, role: role, intent: intent)
        self.extractedTitle = titleResource.string
        Self.printAppIntentInstructions(title: extractedTitle)
    }
    
    public init(_ title: some StringProtocol, systemImage: String, role: ButtonRole? = nil, intent: some AppIntent) {
        self.sui = SwiftUI.Button(title, systemImage: systemImage, role: role, intent: intent)
        self.extractedTitle = String(title)
        Self.printAppIntentInstructions(title: extractedTitle)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, image: ImageResource, role: ButtonRole? = nil, intent: some AppIntent) {
        self.sui = SwiftUI.Button(titleKey, image: image, role: role, intent: intent)
        self.extractedTitle = titleKey.string
        Self.printAppIntentInstructions(title: extractedTitle)
    }
    
    public init(_ titleResource: LocalizedStringResource, image: ImageResource, role: ButtonRole? = nil, intent: some AppIntent) {
        self.sui = SwiftUI.Button(titleResource, image: image, role: role, intent: intent)
        self.extractedTitle = titleResource.string
        Self.printAppIntentInstructions(title: extractedTitle)
    }
    
    public init(_ title: some StringProtocol, image: ImageResource, role: ButtonRole? = nil, intent: some AppIntent) {
        self.sui = SwiftUI.Button(title, image: image, role: role, intent: intent)
        self.extractedTitle = String(title)
        Self.printAppIntentInstructions(title: extractedTitle)
    }
}

// MARK: - AppIntent Instructions Helper

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton {
    fileprivate static func printAppIntentInstructions(title: String?) {
        #if DEBUG
        let titleDisplay = title ?? "<unknown>"
        print("""
        [SignalButton] AppIntent buttons don't support automatic signal capture.
        Button title: "\(titleDisplay)"
        To track this interaction, add Signals.emit() in your AppIntent's perform() method:
            Signals.emit(signal: InteractionSignal(component: "Button", title: "\(titleDisplay)"))
        """)
        #endif
    }
}

#endif
