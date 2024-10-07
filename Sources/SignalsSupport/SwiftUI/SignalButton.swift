//
//  SignalButton.swift
//  SegmentShop
//
//  Created by Brandon Sneed on 2/1/24.
//

import Foundation
import SwiftUI
import Segment

extension LocalizedStringKey {
    // I don't know how palatable this is.
    var string: String {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String ?? "unknown"
    }
}

public protocol SignalingUI {
    static func controlType() -> String
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalButton<Label>: SignalingUI, View where Label : View {
    internal let sui: SwiftUI.Button<Label>
    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label, file: String = #file, function: String = #function, line: Int = #line) {
        let lbl = Self.extractLabel(label(), file, function, line)
        self.sui = SwiftUI.Button(action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: lbl)
            Signals.emit(signal: signal, source: .autoSwiftUI)
        }, label: label)
    }

    public init(signalLabel: String?, action: @escaping () -> Void, @ViewBuilder label: () -> Label, file: String = #file, function: String = #function, line: Int = #line) {
        let lbl = signalLabel ?? Self.extractLabel(label(), file, function, line)
        self.sui = SwiftUI.Button(action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: lbl)
            Signals.emit(signal: signal, source: .autoSwiftUI)
        }, label: label)
    }

    @MainActor public var body: some View {
        return sui
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
        return "Button"
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalButton where Label == Text {
    public init(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) {
        self.sui = SwiftUI.Button(titleKey, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: titleKey.string)
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }

    public init<S>(_ title: S, action: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.Button(title, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: String(title))
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) {
        self.sui = SwiftUI.Button(titleKey, systemImage: systemImage, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: titleKey.string)
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }

    public init<S>(_ title: S, systemImage: String, action: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.Button(title, systemImage: systemImage, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: String(title))
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, image: ImageResource, action: @escaping () -> Void) {
        self.sui = SwiftUI.Button(titleKey, image: image, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: titleKey.string)
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }
    
    public init<S>(_ title: S, image: ImageResource, action: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.Button(title, image: image, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: String(title))
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalButton where Label == PrimitiveButtonStyleConfiguration.Label {
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public init(_ configuration: PrimitiveButtonStyleConfiguration, signalLabel: String) {
        // TODO: i have no idea what to do here.
        self.sui = SwiftUI.Button(configuration)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalButton {
    public init(role: ButtonRole?, action: @escaping () -> Void, @ViewBuilder label: () -> Label, file: String = #file, function: String = #function, line: Int = #line) {
        let lbl = Self.extractLabel(label(), file, function, line)
        self.sui = SwiftUI.Button(role: role, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: lbl)
            Signals.emit(signal: signal, source: .autoSwiftUI)
        }, label: label)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalButton where Label == Text {
    public init(_ titleKey: LocalizedStringKey, role: ButtonRole?, action: @escaping () -> Void) {
        self.sui = SwiftUI.Button(titleKey, role: role, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: titleKey.string)
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }
    
    public init<S>(_ title: S, role: ButtonRole?, action: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.Button(title, role: role, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: String(title))
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, systemImage: String, role: ButtonRole?, action: @escaping () -> Void) {
        self.sui = SwiftUI.Button(titleKey, systemImage: systemImage, role: role, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: titleKey.string)
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }

    public init<S>(_ title: S, systemImage: String, role: ButtonRole?, action: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.Button(title, systemImage: systemImage, role: role, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: String(title))
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalButton where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, image: ImageResource, role: ButtonRole?, action: @escaping () -> Void) {
        self.sui = SwiftUI.Button(titleKey, image: image, role: role, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: titleKey.string)
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }

    public init<S>(_ title: S, image: ImageResource, role: ButtonRole?, action: @escaping () -> Void) where S : StringProtocol {
        self.sui = SwiftUI.Button(title, image: image, role: role, action: {
            action()
            let signal = InteractionSignal(component: Self.controlType(), title: String(title))
            Signals.emit(signal: signal, source: .autoSwiftUI)
        })
    }
}

