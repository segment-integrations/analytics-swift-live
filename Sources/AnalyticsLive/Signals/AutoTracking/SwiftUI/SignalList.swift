//
//  SignalList.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/5/25.
//

import SwiftUI

// MARK: - Selection Tracking Enum

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
internal enum ListSelectionType<SelectionValue: Hashable> {
    case none
    case multiOptional(Binding<Set<SelectionValue>>?)
    case singleOptional(Binding<SelectionValue?>?)
    case singleRequired(Binding<SelectionValue>)
}

// MARK: - SignalList

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SignalList<SelectionValue, Content>: SignalingUI, View
    where SelectionValue: Hashable, Content: View {
    
    let sui: SwiftUI.List<SelectionValue, Content>
    let selectionType: ListSelectionType<SelectionValue>
    
    public var body: some View {
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            ListSelectionObserver(list: sui, selectionType: selectionType)
        } else {
            // iOS 13 fallback - no onChange available, just passthrough
            sui
        }
    }
    
    @inline(__always)
    static public func controlType() -> String {
        return "List"
    }
}

// MARK: - Edit Mode Change Modifiers

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private extension View {
    func onEditModeChange(_ action: @escaping (Bool) -> Void) -> some View {
        #if os(iOS)
        self.modifier(EditModeChangeModifier(action: action))
        #else
        self
        #endif
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private extension View {
    func onEditModeChangeLegacy(_ action: @escaping (Bool) -> Void) -> some View {
        #if os(iOS)
        self.modifier(EditModeChangeModifierLegacy(action: action))
        #else
        self
        #endif
    }
}

#if os(iOS)
@available(iOS 17.0, *)
private struct EditModeChangeModifier: ViewModifier {
    @Environment(\.editMode) private var editMode
    let action: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: editMode?.wrappedValue) { oldValue, newValue in
                let wasEditing = oldValue == .active
                let isEditing = newValue == .active
                if wasEditing != isEditing {
                    action(isEditing)
                }
            }
    }
}

@available(iOS 14.0, *)
private struct EditModeChangeModifierLegacy: ViewModifier {
    @Environment(\.editMode) private var editMode
    let action: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: editMode?.wrappedValue) { newValue in
                action(newValue == .active)
            }
    }
}
#endif

// MARK: - Selection Observer (internal helper)

/// Internal view that observes editMode to distinguish user-initiated deselection
/// from system-triggered clearing when exiting edit mode.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
internal struct ListSelectionObserver<SelectionValue, Content>: View
    where SelectionValue: Hashable, Content: View {
    
    let list: SwiftUI.List<SelectionValue, Content>
    let selectionType: ListSelectionType<SelectionValue>
    
    #if os(iOS)
    @Environment(\.editMode) private var editMode
    #endif
    
    var body: some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            bodyWithModernOnChange
        } else {
            bodyWithLegacyOnChange
        }
    }
    
    // MARK: - Current Selection Helper
    
    /// Get the current selection as strings for signal emission
    private var currentSelectionStrings: [String] {
        switch selectionType {
        case .none:
            return []
        case .multiOptional(let binding):
            guard let binding = binding else { return [] }
            return Array(binding.wrappedValue).map { String(describing: $0) }
        case .singleOptional(let binding):
            guard let binding = binding, let value = binding.wrappedValue else { return [] }
            return [String(describing: value)]
        case .singleRequired(let binding):
            return [String(describing: binding.wrappedValue)]
        }
    }
    
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @ViewBuilder
    private var bodyWithModernOnChange: some View {
        switch selectionType {
        case .none:
            list
                .onEditModeChange { isEditing in
                    emitEditModeSignal(isEditing: isEditing)
                }
        case .multiOptional(let binding):
            if let binding = binding {
                list
                    .onChange(of: binding.wrappedValue) { oldValue, newValue in
                        emitMultiSelectionSignal(old: oldValue, new: newValue)
                    }
                    .onEditModeChange { isEditing in
                        emitEditModeSignal(isEditing: isEditing)
                    }
            } else {
                list
            }
        case .singleOptional(let binding):
            if let binding = binding {
                list
                    .onChange(of: binding.wrappedValue) { oldValue, newValue in
                        emitSingleSelectionSignal(old: oldValue, new: newValue)
                    }
                    .onEditModeChange { isEditing in
                        emitEditModeSignal(isEditing: isEditing)
                    }
            } else {
                list
            }
        case .singleRequired(let binding):
            list
                .onChange(of: binding.wrappedValue) { oldValue, newValue in
                    emitSingleSelectionSignal(old: oldValue, new: newValue)
                }
                .onEditModeChange { isEditing in
                    emitEditModeSignal(isEditing: isEditing)
                }
        }
    }
    
    @ViewBuilder
    private var bodyWithLegacyOnChange: some View {
        switch selectionType {
        case .none:
            list
                .onEditModeChangeLegacy { isEditing in
                    emitEditModeSignal(isEditing: isEditing)
                }
        case .multiOptional(let binding):
            if let binding = binding {
                list
                    .onChange(of: binding.wrappedValue) { newValue in
                        emitMultiSelectionSignalLegacy(new: newValue)
                    }
                    .onEditModeChangeLegacy { isEditing in
                        emitEditModeSignal(isEditing: isEditing)
                    }
            } else {
                list
            }
        case .singleOptional(let binding):
            if let binding = binding {
                list
                    .onChange(of: binding.wrappedValue) { newValue in
                        emitSingleSelectionSignalLegacy(new: newValue)
                    }
                    .onEditModeChangeLegacy { isEditing in
                        emitEditModeSignal(isEditing: isEditing)
                    }
            } else {
                list
            }
        case .singleRequired(let binding):
            list
                .onChange(of: binding.wrappedValue) { newValue in
                    emitSingleSelectionSignalLegacy(new: newValue)
                }
                .onEditModeChangeLegacy { isEditing in
                    emitEditModeSignal(isEditing: isEditing)
                }
        }
    }
    
    // MARK: - Edit Mode Signal
    
    private func emitEditModeSignal(isEditing: Bool) {
        var data: [String: Any] = [
            "action": isEditing ? "edit_mode_entered" : "edit_mode_exited"
        ]
        
        // Include current selection on exit (captured before system clears it)
        if !isEditing {
            let selection = currentSelectionStrings
            if !selection.isEmpty {
                data["finalSelection"] = selection
                data["finalSelectionCount"] = selection.count
            }
        }
        
        let signal = InteractionSignal(
            component: "List",
            title: nil,
            data: data
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    // MARK: - Edit Mode Check
    
    /// Returns true if we should suppress this empty selection signal.
    /// On iOS, when exiting edit mode, the system auto-clears the selection binding.
    /// We want to suppress that system-triggered clear but allow user-initiated deselection.
    private var shouldSuppressEmptySelection: Bool {
        #if os(iOS)
        // If editMode is not .active, the system is clearing selection on edit mode exit
        // If editMode IS .active, the user deliberately deselected everything
        return editMode?.wrappedValue != .active
        #else
        // On macOS, selection isn't tied to edit mode the same way
        return false
        #endif
    }
    
    // MARK: - Signal Emission
    
    private func emitMultiSelectionSignal(old: Set<SelectionValue>, new: Set<SelectionValue>) {
        // Suppress system-triggered clear on edit mode exit
        if new.isEmpty && shouldSuppressEmptySelection {
            return
        }
        
        let action: String
        if new.isEmpty && !old.isEmpty {
            action = "deselected_all"
        } else if new.count > old.count {
            action = "item_selected"
        } else if new.count < old.count {
            action = "item_deselected"
        } else {
            action = "selection_changed"
        }
        
        let signal = InteractionSignal(
            component: "List",
            title: nil,
            data: [
                "action": action,
                "selectedCount": new.count,
                "selectedItems": Array(new).map { String(describing: $0) }
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    private func emitMultiSelectionSignalLegacy(new: Set<SelectionValue>) {
        // Suppress system-triggered clear on edit mode exit
        if new.isEmpty && shouldSuppressEmptySelection {
            return
        }
        
        let signal = InteractionSignal(
            component: "List",
            title: nil,
            data: [
                "action": new.isEmpty ? "deselected_all" : "selection_changed",
                "selectedCount": new.count,
                "selectedItems": Array(new).map { String(describing: $0) }
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    private func emitSingleSelectionSignal(old: SelectionValue?, new: SelectionValue?) {
        // Suppress system-triggered clear on edit mode exit
        if new == nil && shouldSuppressEmptySelection {
            return
        }
        
        let action: String
        if new == nil {
            action = "deselected"
        } else if old == nil {
            action = "selected"
        } else {
            action = "selection_changed"
        }
        
        let signal = InteractionSignal(
            component: "List",
            title: nil,
            data: [
                "action": action,
                "selectedItem": new.map { String(describing: $0) } as Any
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
    
    private func emitSingleSelectionSignalLegacy(new: SelectionValue?) {
        // Suppress system-triggered clear on edit mode exit
        if new == nil && shouldSuppressEmptySelection {
            return
        }
        
        let signal = InteractionSignal(
            component: "List",
            title: nil,
            data: [
                "action": new == nil ? "deselected" : "selected",
                "selectedItem": new.map { String(describing: $0) } as Any
            ]
        )
        Signals.emit(signal: signal, source: .autoSwiftUI)
    }
}


// MARK: - Static Content with Selection

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalList {
    public init(selection: Binding<Set<SelectionValue>>?, @ViewBuilder content: () -> Content) {
        self.sui = SwiftUI.List(selection: selection, content: content)
        self.selectionType = .multiOptional(selection)
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init(selection: Binding<SelectionValue?>?, @ViewBuilder content: () -> Content) {
        self.sui = SwiftUI.List(selection: selection, content: content)
        self.selectionType = .singleOptional(selection)
    }
    
    #if os(macOS)
    @available(macOS 13.0, *)
    @_disfavoredOverload
    public init(selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
        self.sui = SwiftUI.List(selection: selection, content: content)
        self.selectionType = .singleRequired(selection)
    }
    #endif
}

// MARK: - Data-Driven (Identifiable) with Selection

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalList {
    public init<Data, RowContent>(
        _ data: Data,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, Data.Element.ID, RowContent>,
            Data: RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    #if os(macOS)
    @available(macOS 13.0, *)
    @_disfavoredOverload
    public init<Data, RowContent>(
        _ data: Data,
        selection: Binding<SelectionValue>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, Data.Element.ID, RowContent>,
            Data: RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, selection: selection, rowContent: rowContent)
        self.selectionType = .singleRequired(selection)
    }
    #endif
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<Data, RowContent>(
        _ data: Data,
        selection: Binding<SelectionValue?>?,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, Data.Element.ID, RowContent>,
            Data: RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, selection: selection, rowContent: rowContent)
        self.selectionType = .singleOptional(selection)
    }
}

// MARK: - Data-Driven (Explicit ID) with Selection

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalList {
    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, ID, RowContent>,
            Data: RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    #if os(macOS)
    @available(macOS 13.0, *)
    @_disfavoredOverload
    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        selection: Binding<SelectionValue>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, ID, RowContent>,
            Data: RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, selection: selection, rowContent: rowContent)
        self.selectionType = .singleRequired(selection)
    }
    #endif
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        selection: Binding<SelectionValue?>?,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, ID, RowContent>,
            Data: RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, selection: selection, rowContent: rowContent)
        self.selectionType = .singleOptional(selection)
    }
}

// MARK: - Hierarchical (OutlineGroup) with Selection

@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalList {
    public init<Data, RowContent>(
        _ data: Data,
        children: KeyPath<Data.Element, Data?>,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == OutlineGroup<Data, Data.Element.ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    #if os(macOS)
    @available(macOS 13.0, *)
    @_disfavoredOverload
    public init<Data, RowContent>(
        _ data: Data,
        children: KeyPath<Data.Element, Data?>,
        selection: Binding<SelectionValue>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == OutlineGroup<Data, Data.Element.ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .singleRequired(selection)
    }
    #endif
    
    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        children: KeyPath<Data.Element, Data?>,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == OutlineGroup<Data, ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    #if os(macOS)
    @available(macOS 13.0, *)
    @_disfavoredOverload
    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        children: KeyPath<Data.Element, Data?>,
        selection: Binding<SelectionValue>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == OutlineGroup<Data, ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .singleRequired(selection)
    }
    #endif
}

// MARK: - Mutable Binding<Data> with Selection

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalList {
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<LazyMapSequence<Data.Indices, (Data.Index, Data.Element.ID)>, Data.Element.ID, RowContent>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        selection: Binding<SelectionValue?>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<LazyMapSequence<Data.Indices, (Data.Index, Data.Element.ID)>, Data.Element.ID, RowContent>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, selection: selection, rowContent: rowContent)
        self.selectionType = .singleOptional(selection)
    }
    
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<LazyMapSequence<Data.Indices, (Data.Index, ID)>, ID, RowContent>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, id: id, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        selection: Binding<SelectionValue?>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<LazyMapSequence<Data.Indices, (Data.Index, ID)>, ID, RowContent>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, id: id, selection: selection, rowContent: rowContent)
        self.selectionType = .singleOptional(selection)
    }
}

// MARK: - Mutable Binding<Data> Hierarchical with Selection

@available(iOS 15.0, macOS 12.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalList {
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        children: WritableKeyPath<Data.Element, Data?>,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == OutlineGroup<Binding<Data>, Data.Element.ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    #if os(macOS)
    @available(macOS 13.0, *)
    @_disfavoredOverload
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        children: WritableKeyPath<Data.Element, Data?>,
        selection: Binding<SelectionValue>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == OutlineGroup<Binding<Data>, Data.Element.ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .singleRequired(selection)
    }
    #endif
    
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        children: WritableKeyPath<Data.Element, Data?>,
        selection: Binding<SelectionValue?>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == OutlineGroup<Binding<Data>, Data.Element.ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .singleOptional(selection)
    }
    
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        children: WritableKeyPath<Data.Element, Data?>,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == OutlineGroup<Binding<Data>, ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    #if os(macOS)
    @available(macOS 13.0, *)
    @_disfavoredOverload
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        children: WritableKeyPath<Data.Element, Data?>,
        selection: Binding<SelectionValue>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == OutlineGroup<Binding<Data>, ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .singleRequired(selection)
    }
    #endif
    
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        children: WritableKeyPath<Data.Element, Data?>,
        selection: Binding<SelectionValue?>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == OutlineGroup<Binding<Data>, ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, children: children, selection: selection, rowContent: rowContent)
        self.selectionType = .singleOptional(selection)
    }
}

// MARK: - EditActions with Selection

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalList {
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        editActions: EditActions<Data>,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<IndexedIdentifierCollection<Data, Data.Element.ID>, Data.Element.ID, EditableCollectionContent<RowContent, Data>>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, editActions: editActions, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    #if os(macOS)
    @_disfavoredOverload
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        editActions: EditActions<Data>,
        selection: Binding<SelectionValue>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<IndexedIdentifierCollection<Data, Data.Element.ID>, Data.Element.ID, EditableCollectionContent<RowContent, Data>>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, editActions: editActions, selection: selection, rowContent: rowContent)
        self.selectionType = .singleRequired(selection)
    }
    #endif
    
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        editActions: EditActions<Data>,
        selection: Binding<SelectionValue?>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<IndexedIdentifierCollection<Data, Data.Element.ID>, Data.Element.ID, EditableCollectionContent<RowContent, Data>>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, editActions: editActions, selection: selection, rowContent: rowContent)
        self.selectionType = .singleOptional(selection)
    }
    
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        editActions: EditActions<Data>,
        selection: Binding<Set<SelectionValue>>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<IndexedIdentifierCollection<Data, ID>, ID, EditableCollectionContent<RowContent, Data>>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, id: id, editActions: editActions, selection: selection, rowContent: rowContent)
        self.selectionType = .multiOptional(selection)
    }
    
    #if os(macOS)
    @_disfavoredOverload
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        editActions: EditActions<Data>,
        selection: Binding<SelectionValue>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<IndexedIdentifierCollection<Data, ID>, ID, EditableCollectionContent<RowContent, Data>>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, id: id, editActions: editActions, selection: selection, rowContent: rowContent)
        self.selectionType = .singleRequired(selection)
    }
    #endif
    
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        editActions: EditActions<Data>,
        selection: Binding<SelectionValue?>?,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<IndexedIdentifierCollection<Data, ID>, ID, EditableCollectionContent<RowContent, Data>>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, id: id, editActions: editActions, selection: selection, rowContent: rowContent)
        self.selectionType = .singleOptional(selection)
    }
}

// MARK: - No Selection (SelectionValue == Never)

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SignalList where SelectionValue == Never {
    // Static content
    public init(@ViewBuilder content: () -> Content) {
        self.sui = SwiftUI.List(content: content)
        self.selectionType = .none
    }
    
    // Data-driven (Identifiable)
    public init<Data, RowContent>(
        _ data: Data,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, Data.Element.ID, RowContent>,
            Data: RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, rowContent: rowContent)
        self.selectionType = .none
    }
    
    // Data-driven (explicit ID)
    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, ID, RowContent>,
            Data: RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, rowContent: rowContent)
        self.selectionType = .none
    }
    
    // Range-based
    /* Unable to silence warning, but swiftUI also has it i'm told */
    /*public init<RowContent>(
        _ data: Range<Int>,
        @ViewBuilder rowContent: @escaping (Int) -> RowContent
    ) where Content == ForEach<Range<Int>, Int, RowContent>,
            RowContent: View {
        self.sui = SwiftUI.List(data, rowContent: rowContent)
        self.selectionType = .none
    }*/
}

// MARK: - No Selection Hierarchical

@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalList where SelectionValue == Never {
    public init<Data, RowContent>(
        _ data: Data,
        children: KeyPath<Data.Element, Data?>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == OutlineGroup<Data, Data.Element.ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, children: children, rowContent: rowContent)
        self.selectionType = .none
    }
    
    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        children: KeyPath<Data.Element, Data?>,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == OutlineGroup<Data, ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, children: children, rowContent: rowContent)
        self.selectionType = .none
    }
}

// MARK: - No Selection Mutable Binding<Data>

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SignalList where SelectionValue == Never {
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<LazyMapSequence<Data.Indices, (Data.Index, Data.Element.ID)>, Data.Element.ID, RowContent>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, rowContent: rowContent)
        self.selectionType = .none
    }
    
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<LazyMapSequence<Data.Indices, (Data.Index, ID)>, ID, RowContent>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, id: id, rowContent: rowContent)
        self.selectionType = .none
    }
}

// MARK: - No Selection Mutable Binding<Data> Hierarchical

@available(iOS 15.0, macOS 12.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SignalList where SelectionValue == Never {
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        children: WritableKeyPath<Data.Element, Data?>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == OutlineGroup<Binding<Data>, Data.Element.ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable {
        self.sui = SwiftUI.List(data, children: children, rowContent: rowContent)
        self.selectionType = .none
    }
    
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        children: WritableKeyPath<Data.Element, Data?>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == OutlineGroup<Binding<Data>, ID, RowContent, RowContent, DisclosureGroup<RowContent, OutlineSubgroupChildren>>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View {
        self.sui = SwiftUI.List(data, id: id, children: children, rowContent: rowContent)
        self.selectionType = .none
    }
}

// MARK: - No Selection EditActions

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension SignalList where SelectionValue == Never {
    public init<Data, RowContent>(
        _ data: Binding<Data>,
        editActions: EditActions<Data>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<IndexedIdentifierCollection<Data, Data.Element.ID>, Data.Element.ID, EditableCollectionContent<RowContent, Data>>,
            Data: MutableCollection & RandomAccessCollection,
            RowContent: View,
            Data.Element: Identifiable,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, editActions: editActions, rowContent: rowContent)
        self.selectionType = .none
    }
    
    public init<Data, ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        editActions: EditActions<Data>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where Content == ForEach<IndexedIdentifierCollection<Data, ID>, ID, EditableCollectionContent<RowContent, Data>>,
            Data: MutableCollection & RandomAccessCollection,
            ID: Hashable,
            RowContent: View,
            Data.Index: Hashable {
        self.sui = SwiftUI.List(data, id: id, editActions: editActions, rowContent: rowContent)
        self.selectionType = .none
    }
}
