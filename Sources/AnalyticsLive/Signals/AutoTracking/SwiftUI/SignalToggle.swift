//
//  SignalToggle.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/3/25.
//

import SwiftUI
import Foundation

// MARK: - LocalizedStringResource Extension
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension LocalizedStringResource {
    /// Extract the string from a LocalizedStringResource
    var string: String {
        String(localized: self)
    }
}

// MARK: - SignalToggle

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalToggle<Label>: SignalingUI, View where Label: View {
    let sui: SwiftUI.Toggle<Label>
    let extractedTitle: String?
    let isOn: Binding<Bool>
    
    public var body: some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            sui.onChange(of: isOn.wrappedValue) { oldValue, newValue in
                emitSignal(value: newValue)
            }
        } else if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            sui.onChange(of: isOn.wrappedValue) { newValue in
                emitSignal(value: newValue)
            }
        } else {
            sui
        }
    }
    
    private func emitSignal(value: Bool) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: extractedTitle,
            data: ["action": "toggled", "value": value]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
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
        self.isOn = isOn
        self.extractedTitle = Self.extractLabel(label())
    }
}

// MARK: - Text Label Variants
extension SignalToggle where Label == Text {
    public init(_ titleKey: LocalizedStringKey, isOn: Binding<Bool>) {
        self.sui = SwiftUI.Toggle(titleKey, isOn: isOn)
        self.isOn = isOn
        self.extractedTitle = titleKey.string
    }
    
    public init<S>(_ title: S, isOn: Binding<Bool>) where S: StringProtocol {
        self.sui = SwiftUI.Toggle(title, isOn: isOn)
        self.isOn = isOn
        self.extractedTitle = String(title)
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, isOn: Binding<Bool>) {
        self.sui = SwiftUI.Toggle(titleResource, isOn: isOn)
        self.isOn = isOn
        self.extractedTitle = titleResource.string
    }
}

// MARK: - Label with systemImage Variants (iOS 14+)
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension SignalToggle where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, systemImage: String, isOn: Binding<Bool>) {
        self.sui = SwiftUI.Toggle(titleKey, systemImage: systemImage, isOn: isOn)
        self.isOn = isOn
        self.extractedTitle = titleKey.string
    }
    
    public init<S>(_ title: S, systemImage: String, isOn: Binding<Bool>) where S: StringProtocol {
        self.sui = SwiftUI.Toggle(title, systemImage: systemImage, isOn: isOn)
        self.isOn = isOn
        self.extractedTitle = String(title)
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(_ titleResource: LocalizedStringResource, systemImage: String, isOn: Binding<Bool>) {
        self.sui = SwiftUI.Toggle(titleResource, systemImage: systemImage, isOn: isOn)
        self.isOn = isOn
        self.extractedTitle = titleResource.string
    }
}

// MARK: - Label with ImageResource Variants (iOS 17+)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalToggle where Label == SwiftUI.Label<Text, Image> {
    public init(_ titleKey: LocalizedStringKey, image: ImageResource, isOn: Binding<Bool>) {
        self.sui = SwiftUI.Toggle(titleKey, image: image, isOn: isOn)
        self.isOn = isOn
        self.extractedTitle = titleKey.string
    }
    
    public init<S>(_ title: S, image: ImageResource, isOn: Binding<Bool>) where S: StringProtocol {
        self.sui = SwiftUI.Toggle(title, image: image, isOn: isOn)
        self.isOn = isOn
        self.extractedTitle = String(title)
    }
    
    public init(_ titleResource: LocalizedStringResource, image: ImageResource, isOn: Binding<Bool>) {
        self.sui = SwiftUI.Toggle(titleResource, image: image, isOn: isOn)
        self.isOn = isOn
        self.extractedTitle = titleResource.string
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
        self.isOn = isOn
        self.extractedTitle = String(describing: label)
    }
}

// MARK: - Sources Initializers (iOS 16+)

// Generic label + sources
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalToggle {
    public init<C>(sources: C, isOn: KeyPath<C.Element, Binding<Bool>>, @ViewBuilder label: () -> Label) where C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(sources: sources, isOn: isOn, label: label)
        // For sources, we use the first element's binding for change detection
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = Self.extractLabel(label())
    }
}

// Text label + sources
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalToggle where Label == Text {
    public init<C>(_ titleKey: LocalizedStringKey, sources: C, isOn: KeyPath<C.Element, Binding<Bool>>) where C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(titleKey, sources: sources, isOn: isOn)
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = titleKey.string
    }
    
    public init<C>(_ titleResource: LocalizedStringResource, sources: C, isOn: KeyPath<C.Element, Binding<Bool>>) where C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(titleResource, sources: sources, isOn: isOn)
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = titleResource.string
    }
    
    public init<S, C>(_ title: S, sources: C, isOn: KeyPath<C.Element, Binding<Bool>>) where S: StringProtocol, C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(title, sources: sources, isOn: isOn)
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = String(title)
    }
}

// Label<Text, Image> + systemImage + sources
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalToggle where Label == SwiftUI.Label<Text, Image> {
    public init<C>(_ titleKey: LocalizedStringKey, systemImage: String, sources: C, isOn: KeyPath<C.Element, Binding<Bool>>) where C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(titleKey, systemImage: systemImage, sources: sources, isOn: isOn)
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = titleKey.string
    }
    
    public init<C>(_ titleResource: LocalizedStringResource, systemImage: String, sources: C, isOn: KeyPath<C.Element, Binding<Bool>>) where C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(titleResource, systemImage: systemImage, sources: sources, isOn: isOn)
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = titleResource.string
    }
    
    public init<S, C>(_ title: S, systemImage: String, sources: C, isOn: KeyPath<C.Element, Binding<Bool>>) where S: StringProtocol, C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(title, systemImage: systemImage, sources: sources, isOn: isOn)
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = String(title)
    }
}

// Label<Text, Image> + ImageResource + sources (iOS 17+)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SignalToggle where Label == SwiftUI.Label<Text, Image> {
    public init<C>(_ titleKey: LocalizedStringKey, image: ImageResource, sources: C, isOn: KeyPath<C.Element, Binding<Bool>>) where C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(titleKey, image: image, sources: sources, isOn: isOn)
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = titleKey.string
    }
    
    public init<C>(_ titleResource: LocalizedStringResource, image: ImageResource, sources: C, isOn: KeyPath<C.Element, Binding<Bool>>) where C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(titleResource, image: image, sources: sources, isOn: isOn)
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = titleResource.string
    }
    
    public init<S, C>(_ title: S, image: ImageResource, sources: C, isOn: KeyPath<C.Element, Binding<Bool>>) where S: StringProtocol, C: RandomAccessCollection {
        self.sui = SwiftUI.Toggle(title, image: image, sources: sources, isOn: isOn)
        if let first = sources.first {
            self.isOn = first[keyPath: isOn]
        } else {
            self.isOn = .constant(false)
        }
        self.extractedTitle = String(title)
    }
}
