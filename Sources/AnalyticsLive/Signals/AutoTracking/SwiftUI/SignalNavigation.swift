//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/16/24.
//

import Foundation
import SwiftUI

internal class SignalNavCache {
    enum NavEntry {
        case root(String)
        case screen(String)
        case none
        
        var name: String {
            switch self {
            case .root(let s):
                return s
            case .screen(let s):
                return s
            case .none:
                return ""
            }
        }
    }
    
    var screens: [NavEntry]
    
    init() {
        self.screens = []
        push(root: "Root", source: .autoSwiftUI)
    }
    
    func push(root: String, source: SignalSource = .autoSwiftUI) {
        if case .root = current {
            let signalLeave = NavigationSignal(action: .leaving, screen: current.name)
            Signals.shared.emit(signal: signalLeave, source: .autoSwiftUI)
        }
        
        if case .none = current {
            screens.append(.root(root))
            let signalEnter = NavigationSignal(action: .entering, screen: current.name)
            Signals.shared.emit(signal: signalEnter, source: source)
        }
    }
    
    func push(screenName: String) {
        let signalLeave = NavigationSignal(action: .leaving, screen: current.name)
        Signals.shared.emit(signal: signalLeave, source: .autoSwiftUI)
        screens.append(.screen(screenName))
        let signalEnter = NavigationSignal(action: .entering, screen: current.name)
        Signals.shared.emit(signal: signalEnter, source: .autoSwiftUI)
    }
    
    func pop() {
        if screens.count == 2 {
            let signalLeave = NavigationSignal(action: .leaving, screen: current.name)
            Signals.shared.emit(signal: signalLeave, source: .autoSwiftUI)
            screens.removeLast()
        }
        
        if case .root = current {
            let signalEnter = NavigationSignal(action: .entering, screen: current.name)
            Signals.shared.emit(signal: signalEnter, source: .autoSwiftUI)
        }
    }
    
    var current: NavEntry { return screens.last ?? .none }
    static let shared = SignalNavCache()
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@MainActor public struct SignalNavigationStack<Data, Root> : View where Root : View {
    let sui:  SwiftUI.NavigationStack<Data, Root>
    
    @MainActor public init(@ViewBuilder root: () -> Root) where Data == NavigationPath {
        sui = SwiftUI.NavigationStack(root: root)
        let label = "Root"
        SignalNavCache.shared.push(root: label)
    }
    
    @MainActor public init(path: Binding<NavigationPath>, @ViewBuilder root: () -> Root) where Data == NavigationPath {
        sui = SwiftUI.NavigationStack(path: path, root: root)
        let label = "Root"
        SignalNavCache.shared.push(root: label)
    }
    
    @MainActor public init(path: Binding<Data>, @ViewBuilder root: () -> Root) where Data : MutableCollection, Data : RandomAccessCollection, Data : RangeReplaceableCollection, Data.Element : Hashable {
        sui = SwiftUI.NavigationStack(path: path, root: root)
        let label = "Root"
        SignalNavCache.shared.push(root: label)
    }

    @MainActor public var body: some View {
        return sui
    }
}

struct SignalNavContainerView<Content: View>: View {
    let content: Content
    let label: String

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        content.onAppear {
            SignalNavCache.shared.push(screenName: label)
        }.onDisappear {
            SignalNavCache.shared.pop()
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalNavigationLink<Label, Destination> : View where Label : View, Destination : View {
    internal let title: String
    let destination: Destination?
    let type: String?
    let label: Label?
    
    @MainActor public var body: some View {
        SwiftUI.NavigationLink(
            destination: SignalNavContainerView(label: title) {
                destination
            }, label: {
                label
            })
    }
    
    static func extractScreen(_ label: Label, _ file: String? = nil, _ function: String? = nil, _ line: Int? = nil) -> String {
        let s = String(describing: label)
        var result: String
        
        let label = describe(label: s)
        if let label {
            result = label
        } else {
            if let file, let function, let line {
                result = "Unknown Screen @ \(file), \(function), line \(line)"
            } else {
                result = "Unknown Screen"
            }
        }
        return result
    }
    
    public init(@ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label, file: String = #file, function: String = #function, line: Int = #line) {
        self.title = Self.extractScreen(label(), file, function, line)
        self.type = Destination.structName()
        self.destination = destination()
        self.label = label()
    }
    
    public init(signalLabel: String?, @ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label, file: String = #file, function: String = #function, line: Int = #line) {
        self.title = signalLabel ?? Self.extractScreen(label(), file, function, line)
        self.type = Destination.structName()
        self.destination = destination()
        self.label = label()
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    public init(destination: Destination, @ViewBuilder label: () -> Label, file: String = #file, function: String = #function, line: Int = #line) {
        self.title = Self.extractScreen(label(), file, function, line)
        self.type = Destination.structName()
        self.destination = destination
        self.label = label()
    }
    
    public init(signalLabel: String?, destination: Destination, @ViewBuilder label: () -> Label, file: String = #file, function: String = #function, line: Int = #line) {
        self.title = signalLabel ?? Self.extractScreen(label(), file, function, line)
        self.type = Destination.structName()
        self.destination = destination
        self.label = label()
    }
    
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init(isActive: Binding<Bool>, @ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {
        self.title = Self.extractScreen(label())
        self.type = Destination.structName()
        self.destination = destination()
        self.label = label()
    }
    
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init<V>(tag: V, selection: Binding<V?>, @ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) where V : Hashable {
        self.title = Self.extractScreen(label())
        self.type = Destination.structName()
        self.destination = destination()
        self.label = label()
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    public init(destination: Destination, @ViewBuilder label: () -> Label) {
        self.title = Self.extractScreen(label())
        self.type = Destination.structName()
        self.destination = destination
        self.label = label()
    }
    
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init(destination: Destination, isActive: Binding<Bool>, @ViewBuilder label: () -> Label){
        self.title = Self.extractScreen(label())
        self.type = Destination.structName()
        self.destination = destination
        self.label = label()
    }
    
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init<V>(destination: Destination, tag: V, selection: Binding<V?>, @ViewBuilder label: () -> Label) where V : Hashable {
        self.title = Self.extractScreen(label())
        self.type = Destination.structName()
        self.destination = destination
        self.label = label()
    }
}


@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalNavigationLink where Destination == Never {
    public init<P>(value: P?, @ViewBuilder label: () -> Label) where P : Hashable {
        self.title = Self.extractScreen(label())
        self.type = nil
        self.label = label()
        self.destination = nil
    }

    public init<P>(_ titleKey: LocalizedStringKey, value: P?) where Label == Text, P : Hashable {
        self.title = titleKey.string
        self.type = nil
        self.destination = nil
        self.label = nil
    }

    public init<S, P>(_ title: S, value: P?) where Label == Text, S : StringProtocol, P : Hashable {
        self.title = describe(label: title) ?? ""
        self.type = nil
        self.destination = nil
        self.label = nil
    }

    public init<P>(value: P?, @ViewBuilder label: () -> Label) where P : Decodable, P : Encodable, P : Hashable {
        self.title = Self.extractScreen(label())
        self.type = nil
        self.label = label()
        self.destination = nil
    }

    public init<P>(_ titleKey: LocalizedStringKey, value: P?) where Label == Text, P : Decodable, P : Encodable, P : Hashable {
        self.title = titleKey.string
        self.type = nil
        self.label = nil
        self.destination = nil
    }

    public init<S, P>(_ title: S, value: P?) where Label == Text, S : StringProtocol, P : Decodable, P : Encodable, P : Hashable {
        self.title = describe(label: title) ?? ""
        self.type = nil
        self.destination = nil
        self.label = nil
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalNavigationLink where Label == Text {
    
    public init(_ titleKey: LocalizedStringKey, @ViewBuilder destination: () -> Destination) {
        self.title = titleKey.string
        self.type = Destination.structName()
        self.destination = destination()
        self.label = nil
    }
    
    public init<S>(_ title: S, @ViewBuilder destination: () -> Destination) where S : StringProtocol {
        self.title = describe(label: title) ?? ""
        self.type = nil
        self.destination = nil
        self.label = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init(_ titleKey: LocalizedStringKey, isActive: Binding<Bool>, @ViewBuilder destination: () -> Destination) {
        self.title = titleKey.string
        self.type = Destination.structName()
        self.destination = destination()
        self.label = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init<S>(_ title: S, isActive: Binding<Bool>, @ViewBuilder destination: () -> Destination) where S : StringProtocol {
        self.title = describe(label: title) ?? ""
        self.type = Destination.structName()
        self.destination = destination()
        self.label = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init<V>(_ titleKey: LocalizedStringKey, tag: V, selection: Binding<V?>, @ViewBuilder destination: () -> Destination) where V : Hashable {
        self.title = titleKey.string
        self.type = Destination.structName()
        self.destination = destination()
        self.label = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init<S, V>(_ title: S, tag: V, selection: Binding<V?>, @ViewBuilder destination: () -> Destination) where S : StringProtocol, V : Hashable {
        self.title = describe(label: title) ?? ""
        self.type = Destination.structName()
        self.destination = destination()
        self.label = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    public init(_ titleKey: LocalizedStringKey, destination: Destination) {
        self.title = describe(label: titleKey) ?? ""
        self.type = Destination.structName()
        self.destination = destination
        self.label = nil
    }
    
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(tvOS, introduced: 13.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(watchOS, introduced: 6.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    @available(visionOS, introduced: 1.0, deprecated: 100000.0, message: "Pass a closure as the destination")
    public init<S>(_ title: S, destination: Destination) where S : StringProtocol {
        self.title = describe(label: title) ?? ""
        self.type = Destination.structName()
        self.destination = destination
        self.label = nil
    }

    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init(_ titleKey: LocalizedStringKey, destination: Destination, isActive: Binding<Bool>) {
        self.title = titleKey.string
        self.type = Destination.structName()
        self.destination = destination
        self.label = nil
    }

    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init<S>(_ title: S, destination: Destination, isActive: Binding<Bool>) where S : StringProtocol {
        self.title = describe(label: title) ?? ""
        self.type = Destination.structName()
        self.destination = nil
        self.label = nil
    }

    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init<V>(_ titleKey: LocalizedStringKey, destination: Destination, tag: V, selection: Binding<V?>) where V : Hashable {
        self.title = titleKey.string
        self.type = Destination.structName()
        self.destination = destination
        self.label = nil
    }

    @available(iOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(macOS, introduced: 10.15, deprecated: 13.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(tvOS, introduced: 13.0, deprecated: 16.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(watchOS, introduced: 6.0, deprecated: 9.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
    public init<S, V>(_ title: S, destination: Destination, tag: V, selection: Binding<V?>) where S : StringProtocol, V : Hashable {
        self.title = describe(label: title) ?? ""
        self.type = Destination.structName()
        self.destination = destination
        self.label = nil
    }
}
