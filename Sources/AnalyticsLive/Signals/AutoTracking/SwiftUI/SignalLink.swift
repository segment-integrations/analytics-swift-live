//
//  SignalLink.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 1/1/26.
//

import SwiftUI

// MARK: - SignalLink

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct SignalLink<Label>: SignalingUI, View where Label: View {
    
    let url: URL
    let label: Label
    let signalTitle: String?
    
    public var body: some View {
        Link(destination: url) {
            label
        }
        .simultaneousGesture(TapGesture().onEnded { _ in
            emitSignal()
        })
    }
    
    private func emitSignal() {
        let signal = InteractionSignal(
            component: Self.controlType(),
            title: signalTitle,
            data: [
                "url": url.absoluteString
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Link"
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

// MARK: - Custom Label Initializer (iOS 14+)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension SignalLink {
    /// Creates a link with a custom label.
    public init(
        destination: URL,
        @ViewBuilder label: () -> Label
    ) {
        self.url = destination
        self.label = label()
        self.signalTitle = Self.extractTitle(from: self.label)
    }
}

// MARK: - Text Label Initializers (iOS 14+)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension SignalLink where Label == Text {
    /// Creates a link with a localized string key.
    public init(
        _ titleKey: LocalizedStringKey,
        destination: URL
    ) {
        self.url = destination
        self.label = Text(titleKey)
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a link with a string title.
    public init<S: StringProtocol>(
        _ title: S,
        destination: URL
    ) {
        self.url = destination
        self.label = Text(title)
        self.signalTitle = String(title)
    }
    
    /// Creates a link with a localized string resource.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public init(
        _ titleResource: LocalizedStringResource,
        destination: URL
    ) {
        self.url = destination
        self.label = Text(titleResource)
        self.signalTitle = titleResource.key
    }
}
