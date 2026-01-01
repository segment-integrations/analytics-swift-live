//
//  SignalDatePicker.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 1/1/26.
//

import SwiftUI

// MARK: - SignalDatePicker

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
public struct SignalDatePicker<Label>: SignalingUI, View where Label: View {
    
    let sui: SwiftUI.DatePicker<Label>
    let signalTitle: String?
    let signalSelection: Binding<Date>
    
    public var body: some View {
        if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
            sui.onChange(of: signalSelection.wrappedValue) { oldValue, newValue in
                emitSignal(oldValue: oldValue, newValue: newValue)
            }
        } else if #available(iOS 14.0, macOS 11.0, watchOS 7.0, *) {
            sui.onChange(of: signalSelection.wrappedValue) { newValue in
                emitSignalLegacy(newValue: newValue)
            }
        } else {
            sui
        }
    }
    
    // MARK: - Signal Emission
    
    private func emitSignal(oldValue: Date, newValue: Date) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "value": ISO8601DateFormatter().string(from: newValue),
                "previousValue": ISO8601DateFormatter().string(from: oldValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    private func emitSignalLegacy(newValue: Date) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "value": ISO8601DateFormatter().string(from: newValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "DatePicker"
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

// MARK: - Custom Label Initializers (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalDatePicker {
    /// Creates a date picker with a custom label.
    public init(
        selection: Binding<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date],
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.DatePicker(
            selection: selection,
            displayedComponents: displayedComponents,
            label: label
        )
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: label())
    }
    
    /// Creates a date picker with a custom label and date range.
    public init(
        selection: Binding<Date>,
        in range: ClosedRange<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date],
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.DatePicker(
            selection: selection,
            in: range,
            displayedComponents: displayedComponents,
            label: label
        )
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: label())
    }
    
    /// Creates a date picker with a custom label and partial range from.
    public init(
        selection: Binding<Date>,
        in range: PartialRangeFrom<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date],
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.DatePicker(
            selection: selection,
            in: range,
            displayedComponents: displayedComponents,
            label: label
        )
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: label())
    }
    
    /// Creates a date picker with a custom label and partial range through.
    public init(
        selection: Binding<Date>,
        in range: PartialRangeThrough<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date],
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.DatePicker(
            selection: selection,
            in: range,
            displayedComponents: displayedComponents,
            label: label
        )
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: label())
    }
}

// MARK: - Text Label Initializers (iOS 13+)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
@available(tvOS, unavailable)
extension SignalDatePicker where Label == Text {
    /// Creates a date picker with a localized string key.
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]
    ) {
        self.sui = SwiftUI.DatePicker(
            titleKey,
            selection: selection,
            displayedComponents: displayedComponents
        )
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a date picker with a string title.
    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]
    ) {
        self.sui = SwiftUI.DatePicker(
            title,
            selection: selection,
            displayedComponents: displayedComponents
        )
        self.signalSelection = selection
        self.signalTitle = String(title)
    }
    
    /// Creates a date picker with a localized string key and date range.
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Date>,
        in range: ClosedRange<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]
    ) {
        self.sui = SwiftUI.DatePicker(
            titleKey,
            selection: selection,
            in: range,
            displayedComponents: displayedComponents
        )
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a date picker with a string title and date range.
    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<Date>,
        in range: ClosedRange<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]
    ) {
        self.sui = SwiftUI.DatePicker(
            title,
            selection: selection,
            in: range,
            displayedComponents: displayedComponents
        )
        self.signalSelection = selection
        self.signalTitle = String(title)
    }
    
    /// Creates a date picker with a localized string key and partial range from.
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Date>,
        in range: PartialRangeFrom<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]
    ) {
        self.sui = SwiftUI.DatePicker(
            titleKey,
            selection: selection,
            in: range,
            displayedComponents: displayedComponents
        )
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a date picker with a string title and partial range from.
    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<Date>,
        in range: PartialRangeFrom<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]
    ) {
        self.sui = SwiftUI.DatePicker(
            title,
            selection: selection,
            in: range,
            displayedComponents: displayedComponents
        )
        self.signalSelection = selection
        self.signalTitle = String(title)
    }
    
    /// Creates a date picker with a localized string key and partial range through.
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Date>,
        in range: PartialRangeThrough<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]
    ) {
        self.sui = SwiftUI.DatePicker(
            titleKey,
            selection: selection,
            in: range,
            displayedComponents: displayedComponents
        )
        self.signalSelection = selection
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a date picker with a string title and partial range through.
    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<Date>,
        in range: PartialRangeThrough<Date>,
        displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]
    ) {
        self.sui = SwiftUI.DatePicker(
            title,
            selection: selection,
            in: range,
            displayedComponents: displayedComponents
        )
        self.signalSelection = selection
        self.signalTitle = String(title)
    }
}
