//
//  SignalMenu.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 1/1/26.
//

import SwiftUI

// MARK: - SignalMenu

/// A wrapper around SwiftUI Menu that emits signals for primaryAction.
///
/// Note: Menu items (Buttons inside the menu) should use SignalButton to emit their own signals.
/// SignalMenu itself only tracks the `primaryAction` (iOS 15+) which fires when tapping
/// the menu directly rather than long-pressing to show the menu.
@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct SignalMenu<Label, Content>: SignalingUI, View
    where Label: View, Content: View {
    
    let sui: SwiftUI.Menu<Label, Content>
    let signalTitle: String?
    
    public var body: some View {
        sui
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "Menu"
    }
    
    // MARK: - Signal Emission
    
    private static func emitPrimaryActionSignal(title: String?) {
        let signal = InteractionSignal(
            component: controlType(),
            title: title,
            data: [
                "action": "primary_action"
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
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

// MARK: - Custom Label Initializers (iOS 14+)

@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalMenu {
    /// Creates a menu with custom label.
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.sui = SwiftUI.Menu(content: content, label: label)
        self.signalTitle = Self.extractTitle(from: label())
    }
}

// MARK: - Primary Action Initializers (iOS 15+)

@available(iOS 15.0, macOS 12.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalMenu {
    /// Creates a menu with custom label and primary action.
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label,
        primaryAction: @escaping () -> Void
    ) {
        let title = Self.extractTitle(from: label())
        self.sui = SwiftUI.Menu(
            content: content,
            label: label,
            primaryAction: {
                primaryAction()
                Self.emitPrimaryActionSignal(title: title)
            }
        )
        self.signalTitle = title
    }
}

// MARK: - Text Label Initializers (iOS 14+)

@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalMenu where Label == Text {
    /// Creates a menu with a localized string key label.
    public init(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Menu(titleKey, content: content)
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a menu with a string label.
    public init<S: StringProtocol>(
        _ title: S,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Menu(title, content: content)
        self.signalTitle = String(title)
    }
}

// MARK: - Text Label with Primary Action (iOS 15+)

@available(iOS 15.0, macOS 12.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalMenu where Label == Text {
    /// Creates a menu with a localized string key label and primary action.
    public init(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder content: () -> Content,
        primaryAction: @escaping () -> Void
    ) {
        let title = Self.extractTitle(from: titleKey)
        self.sui = SwiftUI.Menu(
            titleKey,
            content: content,
            primaryAction: {
                primaryAction()
                Self.emitPrimaryActionSignal(title: title)
            }
        )
        self.signalTitle = title
    }
    
    /// Creates a menu with a string label and primary action.
    public init<S: StringProtocol>(
        _ title: S,
        @ViewBuilder content: () -> Content,
        primaryAction: @escaping () -> Void
    ) {
        let titleString = String(title)
        self.sui = SwiftUI.Menu(
            title,
            content: content,
            primaryAction: {
                primaryAction()
                Self.emitPrimaryActionSignal(title: titleString)
            }
        )
        self.signalTitle = titleString
    }
}

// MARK: - System Image Initializers (iOS 17+)

#if !os(tvOS) && !os(watchOS)
@available(iOS 17.0, macOS 14.0, *)
extension SignalMenu where Label == SwiftUI.Label<Text, Image> {
    /// Creates a menu with a localized string key and system image.
    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Menu(titleKey, systemImage: systemImage, content: content)
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a menu with a string title and system image.
    public init<S: StringProtocol>(
        _ title: S,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Menu(
            content: content,
            label: { SwiftUI.Label(String(title), systemImage: systemImage) }
        )
        self.signalTitle = String(title)
    }
    
    /// Creates a menu with a localized string key, system image, and primary action.
    @available(iOS 17.0, macOS 14.0, *)
    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder content: () -> Content,
        primaryAction: @escaping () -> Void
    ) {
        let title = Self.extractTitle(from: titleKey)
        self.sui = SwiftUI.Menu(
            titleKey,
            systemImage: systemImage,
            content: content,
            primaryAction: {
                primaryAction()
                Self.emitPrimaryActionSignal(title: title)
            }
        )
        self.signalTitle = title
    }
    
    /// Creates a menu with a string title, system image, and primary action.
    @available(iOS 17.0, macOS 14.0, *)
    public init<S: StringProtocol>(
        _ title: S,
        systemImage: String,
        @ViewBuilder content: () -> Content,
        primaryAction: @escaping () -> Void
    ) {
        let titleString = String(title)
        self.sui = SwiftUI.Menu(
            content: content,
            label: { SwiftUI.Label(titleString, systemImage: systemImage) },
            primaryAction: {
                primaryAction()
                Self.emitPrimaryActionSignal(title: titleString)
            }
        )
        self.signalTitle = titleString
    }
}
#endif

// MARK: - Image Resource Initializers (iOS 17+)

#if !os(tvOS) && !os(watchOS)
@available(iOS 17.0, macOS 14.0, *)
extension SignalMenu where Label == SwiftUI.Label<Text, Image> {
    /// Creates a menu with a localized string key and image resource.
    public init(
        _ titleKey: LocalizedStringKey,
        image: ImageResource,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Menu(titleKey, image: image, content: content)
        self.signalTitle = Self.extractTitle(from: titleKey)
    }
    
    /// Creates a menu with a string title and image resource.
    public init<S: StringProtocol>(
        _ title: S,
        image: ImageResource,
        @ViewBuilder content: () -> Content
    ) {
        self.sui = SwiftUI.Menu(
            content: content,
            label: { SwiftUI.Label(String(title), image: image) }
        )
        self.signalTitle = String(title)
    }
    
    /// Creates a menu with a localized string key, image resource, and primary action.
    public init(
        _ titleKey: LocalizedStringKey,
        image: ImageResource,
        @ViewBuilder content: () -> Content,
        primaryAction: @escaping () -> Void
    ) {
        let title = Self.extractTitle(from: titleKey)
        self.sui = SwiftUI.Menu(
            titleKey,
            image: image,
            content: content,
            primaryAction: {
                primaryAction()
                Self.emitPrimaryActionSignal(title: title)
            }
        )
        self.signalTitle = title
    }
    
    /// Creates a menu with a string title, image resource, and primary action.
    public init<S: StringProtocol>(
        _ title: S,
        image: ImageResource,
        @ViewBuilder content: () -> Content,
        primaryAction: @escaping () -> Void
    ) {
        let titleString = String(title)
        self.sui = SwiftUI.Menu(
            content: content,
            label: { SwiftUI.Label(titleString, image: image) },
            primaryAction: {
                primaryAction()
                Self.emitPrimaryActionSignal(title: titleString)
            }
        )
        self.signalTitle = titleString
    }
}
#endif
