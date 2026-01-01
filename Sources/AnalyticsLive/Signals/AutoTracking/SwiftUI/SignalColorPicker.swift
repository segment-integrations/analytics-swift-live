//
//  SignalColorPicker.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 1/1/26.
//

#if !os(tvOS) && !os(watchOS)

import SwiftUI

// MARK: - SignalColorPicker

@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct SignalColorPicker<Label>: SignalingUI, View where Label: View {
    
    enum ColorBinding {
        case color(Binding<Color>)
        case cgColor(Binding<CGColor>)
    }
    
    let sui: SwiftUI.ColorPicker<Label>
    let signalTitle: String?
    let colorBinding: ColorBinding
    
    public var body: some View {
        switch colorBinding {
        case .color(let binding):
            if #available(iOS 17.0, macOS 14.0, *) {
                sui.onChange(of: binding.wrappedValue) { oldValue, newValue in
                    emitColorSignal(oldValue: oldValue, newValue: newValue)
                }
            } else {
                sui.onChange(of: binding.wrappedValue) { newValue in
                    emitColorSignalLegacy(newValue: newValue)
                }
            }
        case .cgColor(let binding):
            if #available(iOS 17.0, macOS 14.0, *) {
                sui.onChange(of: binding.wrappedValue) { oldValue, newValue in
                    emitCGColorSignal(oldValue: oldValue, newValue: newValue)
                }
            } else {
                sui.onChange(of: binding.wrappedValue) { newValue in
                    emitCGColorSignalLegacy(newValue: newValue)
                }
            }
        }
    }
    
    // MARK: - Signal Emission (Color)
    
    private func emitColorSignal(oldValue: Color, newValue: Color) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "value": Self.colorDescription(newValue),
                "previousValue": Self.colorDescription(oldValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    private func emitColorSignalLegacy(newValue: Color) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "value": Self.colorDescription(newValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    @available(iOS 14.0, macOS 11.0, *)
    private static func colorDescription(_ color: Color) -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "rgba(%.3f, %.3f, %.3f, %.3f)", r, g, b, a)
        #elseif canImport(AppKit)
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            return String(format: "rgba(%.3f, %.3f, %.3f, %.3f)", 
                rgbColor.redComponent, rgbColor.greenComponent, 
                rgbColor.blueComponent, rgbColor.alphaComponent)
        }
        return "unknown"
        #else
        return "unknown"
        #endif
    }
    
    // MARK: - Signal Emission (CGColor)
    
    private func emitCGColorSignal(oldValue: CGColor, newValue: CGColor) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "value": Self.cgColorDescription(newValue),
                "previousValue": Self.cgColorDescription(oldValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    private func emitCGColorSignalLegacy(newValue: CGColor) {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "value": Self.cgColorDescription(newValue)
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    private static func cgColorDescription(_ color: CGColor) -> String {
        if let components = color.components {
            return "rgba(\(components.map { String(format: "%.3f", $0) }.joined(separator: ", ")))"
        }
        return "unknown"
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "ColorPicker"
    }
    
    // MARK: - Label Extraction
    
    fileprivate static func extractTitle(from label: Label) -> String? {
        let s = String(describing: label)
        return describe(label: s)
    }
    
    fileprivate static func extractTitle(from key: LocalizedStringKey) -> String? {
        return key.string
    }
}

// MARK: - Color Custom Label Initializers (iOS 14+)

@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalColorPicker {
    /// Creates a color picker with a Color binding and custom label.
    public init(
        selection: Binding<Color>,
        supportsOpacity: Bool = true,
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.ColorPicker(
            selection: selection,
            supportsOpacity: supportsOpacity,
            label: label
        )
        self.colorBinding = .color(selection)
        self.signalTitle = Self.extractTitle(from: label())
    }
    
    /// Creates a color picker with a CGColor binding and custom label.
    public init(
        selection: Binding<CGColor>,
        supportsOpacity: Bool = true,
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.ColorPicker(
            selection: selection,
            supportsOpacity: supportsOpacity,
            label: label
        )
        self.colorBinding = .cgColor(selection)
        self.signalTitle = Self.extractTitle(from: label())
    }
}

// MARK: - Color Text Label Initializers (iOS 14+)

@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalColorPicker where Label == Text {
    /// Creates a color picker with a Color binding and localized string key.
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Color>,
        supportsOpacity: Bool = true
    ) {
        self.sui = SwiftUI.ColorPicker(
            titleKey,
            selection: selection,
            supportsOpacity: supportsOpacity
        )
        self.colorBinding = .color(selection)
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a color picker with a Color binding and string title.
    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<Color>,
        supportsOpacity: Bool = true
    ) {
        self.sui = SwiftUI.ColorPicker(
            title,
            selection: selection,
            supportsOpacity: supportsOpacity
        )
        self.colorBinding = .color(selection)
        self.signalTitle = String(title)
    }
    
    /// Creates a color picker with a CGColor binding and localized string key.
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<CGColor>,
        supportsOpacity: Bool = true
    ) {
        self.sui = SwiftUI.ColorPicker(
            titleKey,
            selection: selection,
            supportsOpacity: supportsOpacity
        )
        self.colorBinding = .cgColor(selection)
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a color picker with a CGColor binding and string title.
    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<CGColor>,
        supportsOpacity: Bool = true
    ) {
        self.sui = SwiftUI.ColorPicker(
            title,
            selection: selection,
            supportsOpacity: supportsOpacity
        )
        self.colorBinding = .cgColor(selection)
        self.signalTitle = String(title)
    }
}

#endif
