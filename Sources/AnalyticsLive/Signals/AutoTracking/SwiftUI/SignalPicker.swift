//
//  SignalPicker.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/3/25.
//

import SwiftUI

// MARK: - SignalPicker

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalPicker<Label, SelectionValue, Content>: SignalingUI, View
    where Label: View, SelectionValue: Hashable, Content: View {
    
    let sui: SwiftUI.Picker<Label, SelectionValue, Content>
    let signalTitle: String?
    let signalSelection: Binding<SelectionValue>
    
    public var body: some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            sui.onChange(of: signalSelection.wrappedValue) { oldValue, newValue in
                emitSignal(oldValue: oldValue, newValue: newValue)
            }
        } else if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            sui.onChange(of: signalSelection.wrappedValue) { newValue in
                emitSignalLegacy(newValue: newValue)
            }
        } else {
            sui
        }
    }
    
    // MARK: - Signal Emission
    
    private func emitSignal(oldValue: SelectionValue, newValue: SelectionValue) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "value": String(describing: newValue),
                "previousValue": String(describing: oldValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    private func emitSignalLegacy(newValue: SelectionValue) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "value": String(describing: newValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Picker"
    }
    
    // MARK: - Label Extraction
    
    private static func extractTitle(from label: Label) -> String? {
        let s = String(describing: label)
        return describe(label: s)
    }
    
    private static func extractTitle(from key: LocalizedStringKey) -> String? {
        return key.string
    }
}

// MARK: - Basic Initializers (iOS 13+)

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalPicker {
    /// Creates a picker with a custom label view.
    public init(
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.Picker(selection: selection, content: content, label: label)
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: label())
    }
}

// MARK: - Text Label Initializers (iOS 13+)

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalPicker where Label == Text {
    /// Creates a picker with a localized string key label.
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(titleKey, selection: selection, content: content)
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a picker with a string label.
    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(title, selection: selection, content: content)
        self.signalSelection = selection
        self.signalTitle = String(title)
    }
    
    /// Creates a picker with a localized string resource label.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(
        _ titleResource: LocalizedStringResource,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(selection: selection, content: content) { Text(titleResource) }
        self.signalSelection = selection
        self.signalTitle = titleResource.key
    }
}

// MARK: - System Image Initializers (iOS 17+)

#if !os(watchOS)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension SignalPicker where Label == SwiftUI.Label<Text, Image> {
    /// Creates a picker with a localized string key and system image.
    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(titleKey, systemImage: systemImage, selection: selection, content: content)
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a picker with a string title and system image.
    public init<S: StringProtocol>(
        _ title: S,
        systemImage: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(title, systemImage: systemImage, selection: selection, content: content)
        self.signalSelection = selection
        self.signalTitle = String(title)
    }
}
#endif

// MARK: - Image Resource Initializers (iOS 17+)

#if !os(watchOS)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension SignalPicker where Label == SwiftUI.Label<Text, Image> {
    /// Creates a picker with a localized string key and image resource.
    public init(
        _ titleKey: LocalizedStringKey,
        image: ImageResource,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(titleKey, image: image, selection: selection, content: content)
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a picker with a string title and image resource.
    public init<S: StringProtocol>(
        _ title: S,
        image: ImageResource,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(title, image: image, selection: selection, content: content)
        self.signalSelection = selection
        self.signalTitle = String(title)
    }
    
    /// Creates a picker with a localized string resource and image resource.
    public init(
        _ titleResource: LocalizedStringResource,
        image: ImageResource,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(selection: selection, content: content) {
            SwiftUI.Label(titleResource, image: image)
        }
        self.signalSelection = selection
        self.signalTitle = titleResource.key
    }
}
#endif

// MARK: - Sources Initializers (iOS 16+)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalPicker {
    /// Creates a picker with sources binding and custom label.
    public init<C>(
        sources: C,
        selection: KeyPath<C.Element, Binding<SelectionValue>>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) where C: RandomAccessCollection {
        if let first = sources.first {
            self.signalSelection = first[keyPath: selection]
        } else {
            self.signalSelection = .constant(SelectionValue.self as! SelectionValue)
        }
        self.sui = SwiftUI.Picker(sources: sources, selection: selection, content: content, label: label)
        self.signalTitle = Self.extractTitle(from: label())
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalPicker where Label == Text {
    /// Creates a picker with sources and localized string key.
    public init<C>(
        _ titleKey: LocalizedStringKey,
        sources: C,
        selection: KeyPath<C.Element, Binding<SelectionValue>>,
        @ViewBuilder content: () -> Content
    ) where C: RandomAccessCollection {
        if let first = sources.first {
            self.signalSelection = first[keyPath: selection]
        } else {
            self.signalSelection = .constant(SelectionValue.self as! SelectionValue)
        }
        self.sui = SwiftUI.Picker(titleKey, sources: sources, selection: selection, content: content)
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a picker with sources and localized string resource.
    public init<C>(
        _ titleResource: LocalizedStringResource,
        sources: C,
        selection: KeyPath<C.Element, Binding<SelectionValue>>,
        @ViewBuilder content: () -> Content
    ) where C: RandomAccessCollection {
        if let first = sources.first {
            self.signalSelection = first[keyPath: selection]
        } else {
            self.signalSelection = .constant(SelectionValue.self as! SelectionValue)
        }
        self.sui = SwiftUI.Picker(sources: sources, selection: selection, content: content) { Text(titleResource) }
        self.signalTitle = titleResource.key
    }
    
    /// Creates a picker with sources and string title.
    public init<S, C>(
        _ title: S,
        sources: C,
        selection: KeyPath<C.Element, Binding<SelectionValue>>,
        @ViewBuilder content: () -> Content
    ) where S: StringProtocol, C: RandomAccessCollection {
        if let first = sources.first {
            self.signalSelection = first[keyPath: selection]
        } else {
            self.signalSelection = .constant(SelectionValue.self as! SelectionValue)
        }
        self.sui = SwiftUI.Picker(title, sources: sources, selection: selection, content: content)
        self.signalTitle = String(title)
    }
}

// MARK: - System Image + LocalizedStringResource (iOS 16+)

#if !os(watchOS)
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
extension SignalPicker where Label == SwiftUI.Label<Text, Image> {
    /// Creates a picker with a localized string resource and system image.
    public init(
        _ titleResource: LocalizedStringResource,
        systemImage: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Picker(selection: selection, content: content) {
            SwiftUI.Label(titleResource, systemImage: systemImage)
        }
        self.signalSelection = selection
        self.signalTitle = titleResource.key
    }
}
#endif

// MARK: - CurrentValueLabel Initializers (iOS 18+)

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension SignalPicker {
    /// Creates a picker with custom label and current value label.
    public init(
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label,
        @ViewBuilder currentValueLabel: () -> some View
    ) {
        self.sui = SwiftUI.Picker(selection: selection, content: content, label: label, currentValueLabel: currentValueLabel)
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: label())
    }
    
    /// Creates a picker with sources, custom label and current value label.
    public init<C>(
        sources: C,
        selection: KeyPath<C.Element, Binding<SelectionValue>>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label,
        @ViewBuilder currentValueLabel: () -> some View
    ) where C: RandomAccessCollection {
        if let first = sources.first {
            self.signalSelection = first[keyPath: selection]
        } else {
            self.signalSelection = .constant(SelectionValue.self as! SelectionValue)
        }
        self.sui = SwiftUI.Picker(sources: sources, selection: selection, content: content, label: label, currentValueLabel: currentValueLabel)
        self.signalTitle = Self.extractTitle(from: label())
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension SignalPicker where Label == Text {
    /// Creates a picker with localized string key and current value label.
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder currentValueLabel: () -> some View
    ) {
        self.sui = SwiftUI.Picker(titleKey, selection: selection, content: content, currentValueLabel: currentValueLabel)
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a picker with localized string resource and current value label.
    public init(
        _ titleResource: LocalizedStringResource,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder currentValueLabel: () -> some View
    ) {
        self.sui = SwiftUI.Picker(
            selection: selection,
            content: content,
            label: { Text(titleResource) },
            currentValueLabel: currentValueLabel
        )
        self.signalSelection = selection
        self.signalTitle = titleResource.key
    }
    
    /// Creates a picker with string title and current value label.
    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder currentValueLabel: () -> some View
    ) {
        self.sui = SwiftUI.Picker(title, selection: selection, content: content, currentValueLabel: currentValueLabel)
        self.signalSelection = selection
        self.signalTitle = String(title)
    }
}
