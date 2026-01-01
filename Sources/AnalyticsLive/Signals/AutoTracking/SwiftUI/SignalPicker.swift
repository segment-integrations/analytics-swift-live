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
}
#endif
