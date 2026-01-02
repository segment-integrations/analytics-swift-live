//
//  InteractionSwizzler.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 12/30/25.
//

#if canImport(UIKit) && !os(watchOS)

import UIKit
import Segment
import ObjectiveC

/// Unified swizzler for all UI interactions.
/// Captures interactions for:
/// - UIControl subclasses: UISwitch, UISlider, UIStepper, UISegmentedControl,
///   UIDatePicker, UIPageControl, UIColorWell, UITextField, UIButton
/// - UIPickerView (delegate-based)
/// - Cell selection: UITableViewCell, UICollectionViewCell
/// - Tab selection: UITabBarController
///
/// Does NOT emit signals for SwiftUI-backed controls - those are handled by
/// Signal* wrappers (SignalToggle, SignalSlider, etc.) via onChange.
internal class InteractionSwizzler {
    static let shared = InteractionSwizzler()
    private var controlHandle: Swizzler.SwizzleHandle?
    private var tableViewCellHandle: Swizzler.SwizzleHandle?
    private var collectionViewCellHandle: Swizzler.SwizzleHandle?
    private var tabBarHandle: Swizzler.SwizzleHandle?
    private var pickerViewHandle: Swizzler.SwizzleHandle?
    @Atomic private var isRunning = false
    
    private init() {}
    
    func start() {
        guard !isRunning else { return }
        _isRunning.set(true)
        
        // Swizzle UIControl.sendActions(for:) for all control interactions
        controlHandle = Swizzler.swizzle(
            originalClass: UIControl.self,
            originalSelector: #selector(UIControl.sendActions(for:)),
            swizzledSelector: #selector(UIControl.signals_sendActions(for:))
        )
        
        // Swizzle UITableViewCell.setSelected(_:animated:) for table cell selection
        tableViewCellHandle = Swizzler.swizzle(
            originalClass: UITableViewCell.self,
            originalSelector: #selector(UITableViewCell.setSelected(_:animated:)),
            swizzledSelector: #selector(UITableViewCell.signals_setSelected(_:animated:))
        )
        
        // Swizzle UICollectionViewCell.isSelected setter for collection cell selection
        collectionViewCellHandle = Swizzler.swizzle(
            originalClass: UICollectionViewCell.self,
            originalSelector: #selector(setter: UICollectionViewCell.isSelected),
            swizzledSelector: #selector(UICollectionViewCell.signals_setIsSelected(_:))
        )
        
        // Swizzle UITabBarController for tab selection
        let tabSelector = Selector(("_setSelectedViewController:"))
        tabBarHandle = Swizzler.swizzle(
            originalClass: UITabBarController.self,
            originalSelector: tabSelector,
            swizzledSelector: #selector(UITabBarController.signals_setSelectedViewController(_:))
        )
        
        // Swizzle UIPickerView.setDelegate: for picker selection
        pickerViewHandle = Swizzler.swizzle(
            originalClass: UIPickerView.self,
            originalSelector: #selector(setter: UIPickerView.delegate),
            swizzledSelector: #selector(UIPickerView.signals_setDelegate(_:))
        )
    }
    
    func stop() {
        if var handle = controlHandle {
            handle.restore()
        }
        controlHandle = nil
        
        if var handle = tableViewCellHandle {
            handle.restore()
        }
        tableViewCellHandle = nil
        
        if var handle = collectionViewCellHandle {
            handle.restore()
        }
        collectionViewCellHandle = nil
        
        if var handle = tabBarHandle {
            handle.restore()
        }
        tabBarHandle = nil
        
        if var handle = pickerViewHandle {
            handle.restore()
        }
        pickerViewHandle = nil
        
        _isRunning.set(false)
    }
}

// MARK: - UIControl Swizzled Methods

extension UIControl {
    @objc dynamic func signals_sendActions(for controlEvents: UIControl.Event) {
        // Call original implementation first
        signals_sendActions(for: controlEvents)
        
        // If this is SwiftUI-backed, bail out - Signal* wrappers handle it via onChange
        let source = ControlSignalSource.detect(for: self)
        if source == .autoSwiftUI {
            return
        }
        
        // Dispatch based on control type and event
        if controlEvents.contains(.valueChanged) {
            handleValueChanged()
        }
        
        if controlEvents.contains(.editingDidEnd) {
            handleEditingDidEnd()
        }
        
        if controlEvents.contains(.touchUpInside) {
            handleTouchUpInside()
        }
    }
    
    // MARK: - Value Changed Handlers
    
    private func handleValueChanged() {
        switch self {
        case let toggle as UISwitch:
            emitToggleSignal(toggle)
        case let slider as UISlider:
            emitSliderSignal(slider)
        case let stepper as UIStepper:
            emitStepperSignal(stepper)
        case let segmented as UISegmentedControl:
            emitSegmentedControlSignal(segmented)
        case let datePicker as UIDatePicker:
            emitDatePickerSignal(datePicker)
        case let pageControl as UIPageControl:
            emitPageControlSignal(pageControl)
        default:
            // iOS 14+ controls
            if #available(iOS 14.0, *) {
                if let colorWell = self as? UIColorWell {
                    emitColorWellSignal(colorWell)
                }
            }
        }
    }
    
    private func handleEditingDidEnd() {
        switch self {
        case let textField as UITextField:
            emitTextFieldSignal(textField)
        default:
            break
        }
    }
    
    private func handleTouchUpInside() {
        switch self {
        case let button as UIButton:
            emitButtonSignal(button)
        default:
            break
        }
    }
    
    // MARK: - Signal Emitters
    
    private func emitToggleSignal(_ toggle: UISwitch) {
        let title = extractTitle() ?? toggle.accessibilityLabel
        var data: [String: Any] = [
            "action": "toggled",
            "value": toggle.isOn
        ]
        addAccessibilityInfo(to: &data)
        
        let signal = InteractionSignal(
            component: "Toggle",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func emitButtonSignal(_ button: UIButton) {
        let title = extractTitle() ?? button.accessibilityLabel ?? button.currentTitle
        var data: [String: Any] = [
            "action": "tap"
        ]
        addAccessibilityInfo(to: &data)
        
        let signal = InteractionSignal(
            component: "Button",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func emitSliderSignal(_ slider: UISlider) {
        let title = extractTitle() ?? slider.accessibilityLabel
        var data: [String: Any] = [
            "action": "changed",
            "value": slider.value,
            "minimum": slider.minimumValue,
            "maximum": slider.maximumValue
        ]
        addAccessibilityInfo(to: &data)
        
        let signal = InteractionSignal(
            component: "Slider",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func emitStepperSignal(_ stepper: UIStepper) {
        let title = extractTitle() ?? stepper.accessibilityLabel
        var data: [String: Any] = [
            "action": "changed",
            "value": stepper.value,
            "minimum": stepper.minimumValue,
            "maximum": stepper.maximumValue,
            "step": stepper.stepValue
        ]
        addAccessibilityInfo(to: &data)
        
        let signal = InteractionSignal(
            component: "Stepper",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func emitSegmentedControlSignal(_ segmented: UISegmentedControl) {
        let title = extractTitle() ?? segmented.accessibilityLabel
        let selectedTitle = segmented.titleForSegment(at: segmented.selectedSegmentIndex)
        
        var data: [String: Any] = [
            "action": "selected",
            "selectedIndex": segmented.selectedSegmentIndex,
            "segmentCount": segmented.numberOfSegments
        ]
        if let selectedTitle = selectedTitle {
            data["selectedTitle"] = selectedTitle
        }
        addAccessibilityInfo(to: &data)
        
        let signal = InteractionSignal(
            component: "SegmentedControl",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func emitDatePickerSignal(_ datePicker: UIDatePicker) {
        let title = extractTitle() ?? datePicker.accessibilityLabel
        let formatter = ISO8601DateFormatter()
        
        var data: [String: Any] = [
            "action": "changed",
            "value": formatter.string(from: datePicker.date),
            "mode": datePickerModeString(datePicker.datePickerMode)
        ]
        addAccessibilityInfo(to: &data)
        
        let signal = InteractionSignal(
            component: "DatePicker",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func emitPageControlSignal(_ pageControl: UIPageControl) {
        let title = extractTitle() ?? pageControl.accessibilityLabel
        var data: [String: Any] = [
            "action": "changed",
            "currentPage": pageControl.currentPage,
            "numberOfPages": pageControl.numberOfPages
        ]
        addAccessibilityInfo(to: &data)
        
        let signal = InteractionSignal(
            component: "PageControl",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    @available(iOS 14.0, *)
    private func emitColorWellSignal(_ colorWell: UIColorWell) {
        let title = extractTitle() ?? colorWell.accessibilityLabel
        var data: [String: Any] = [
            "action": "changed"
        ]
        
        if let color = colorWell.selectedColor {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            data["value"] = [
                "red": red,
                "green": green,
                "blue": blue,
                "alpha": alpha
            ]
        }
        addAccessibilityInfo(to: &data)
        
        let signal = InteractionSignal(
            component: "ColorPicker",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func emitTextFieldSignal(_ textField: UITextField) {
        let title = extractTitle() ?? textField.accessibilityLabel ?? textField.placeholder
        
        var data: [String: Any] = [
            "action": "edited",
            "secure": textField.isSecureTextEntry
        ]
        
        // Don't include actual text for secure fields - just metadata
        if textField.isSecureTextEntry {
            data["value"] = ""  // Never include secure text
        }
        data["isEmpty"] = textField.text?.isEmpty ?? true
        data["characterCount"] = textField.text?.count ?? 0
        
        if let placeholder = textField.placeholder, !placeholder.isEmpty {
            data["placeholder"] = placeholder
        }
        addAccessibilityInfo(to: &data)
        
        let signal = InteractionSignal(
            component: textField.isSecureTextEntry ? "SecureField" : "TextField",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    // MARK: - Helpers
    
    private func datePickerModeString(_ mode: UIDatePicker.Mode) -> String {
        switch mode {
        case .time: return "time"
        case .date: return "date"
        case .dateAndTime: return "dateAndTime"
        case .countDownTimer: return "countDownTimer"
        case .yearAndMonth: return "yearAndMonth"
        @unknown default: return "unknown"
        }
    }
    
    private func addAccessibilityInfo(to data: inout [String: Any]) {
        if let label = accessibilityLabel, !label.isEmpty {
            data["accessibilityLabel"] = label
        }
        if let identifier = accessibilityIdentifier, !identifier.isEmpty {
            data["accessibilityIdentifier"] = identifier
        }
    }
    
    /// Attempts to extract a meaningful title for the control
    fileprivate func extractTitle() -> String? {
        // Check accessibility label first
        if let label = accessibilityLabel, !label.isEmpty {
            return label
        }
        
        // Try accessibility identifier
        if let identifier = accessibilityIdentifier, !identifier.isEmpty {
            return identifier
        }
        
        // Walk up to find a cell or container, then search for labels
        if let title = findLabelInContainer() {
            return title
        }
        
        return nil
    }
    
    /// Walks up the hierarchy to find a container, then searches for labels within it
    private func findLabelInContainer() -> String? {
        var current: UIView? = superview
        
        while let view = current {
            let typeName = String(describing: type(of: view))
            
            // Stop at cell boundaries or common containers
            if typeName.contains("Cell") ||
               typeName.contains("TableViewCell") ||
               typeName.contains("CollectionViewCell") {
                return findFirstLabel(in: view, excluding: self)
            }
            
            current = view.superview
        }
        
        return nil
    }
    
    /// Recursively searches a view hierarchy for the first UILabel with text
    fileprivate func findFirstLabel(in view: UIView, excluding: UIView) -> String? {
        if view === excluding { return nil }
        
        if let label = view as? UILabel,
           let text = label.text,
           !text.isEmpty {
            return text
        }
        
        for subview in view.subviews {
            if let found = findFirstLabel(in: subview, excluding: excluding) {
                return found
            }
        }
        
        return nil
    }
}

// MARK: - UITableViewCell Swizzled Methods

extension UITableViewCell {
    @objc dynamic func signals_setSelected(_ selected: Bool, animated: Bool) {
        // Call original implementation first
        signals_setSelected(selected, animated: animated)
        
        // Only emit on selection, not deselection
        guard selected else { return }
        
        // If this is SwiftUI-backed, bail out
        let source = ControlSignalSource.detect(for: self)
        if source == .autoSwiftUI {
            return
        }
        
        let title = extractCellTitle()
        var data: [String: Any] = [
            "action": "selected",
            "isEditing": isEditing,
            "showingDeleteConfirmation": showingDeleteConfirmation
        ]
        
        // Try to get index path from parent table view
        if let tableView = findParentTableView(),
           let indexPath = tableView.indexPath(for: self) {
            data["section"] = indexPath.section
            data["row"] = indexPath.row
        }
        
        if let identifier = accessibilityIdentifier, !identifier.isEmpty {
            data["accessibilityIdentifier"] = identifier
        }
        
        let signal = InteractionSignal(
            component: "TableViewCell",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func extractCellTitle() -> String? {
        // Check accessibility label first
        if let label = accessibilityLabel, !label.isEmpty {
            return label
        }
        
        // Try textLabel (standard cell)
        if let text = textLabel?.text, !text.isEmpty {
            return text
        }
        
        // Find first UILabel in hierarchy
        return findFirstLabel(in: contentView)
    }
    
    private func findFirstLabel(in view: UIView) -> String? {
        if let label = view as? UILabel,
           let text = label.text,
           !text.isEmpty {
            return text
        }
        
        for subview in view.subviews {
            if let found = findFirstLabel(in: subview) {
                return found
            }
        }
        
        return nil
    }
    
    private func findParentTableView() -> UITableView? {
        var current: UIView? = superview
        while let view = current {
            if let tableView = view as? UITableView {
                return tableView
            }
            current = view.superview
        }
        return nil
    }
}

// MARK: - UICollectionViewCell Swizzled Methods

extension UICollectionViewCell {
    @objc dynamic func signals_setIsSelected(_ selected: Bool) {
        // Call original implementation first
        signals_setIsSelected(selected)
        
        // Only emit on selection, not deselection
        guard selected else { return }
        
        // If this is SwiftUI-backed, bail out
        let source = ControlSignalSource.detect(for: self)
        if source == .autoSwiftUI {
            return
        }
        
        let title = extractCellTitle()
        var data: [String: Any] = [
            "action": "selected"
        ]
        
        // Try to get index path from parent collection view
        if let collectionView = findParentCollectionView(),
           let indexPath = collectionView.indexPath(for: self) {
            data["section"] = indexPath.section
            data["item"] = indexPath.item
        }
        
        if let identifier = accessibilityIdentifier, !identifier.isEmpty {
            data["accessibilityIdentifier"] = identifier
        }
        
        let signal = InteractionSignal(
            component: "CollectionViewCell",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func extractCellTitle() -> String? {
        // Check accessibility label first
        if let label = accessibilityLabel, !label.isEmpty {
            return label
        }
        
        // Find first UILabel in hierarchy
        return findFirstLabel(in: contentView)
    }
    
    private func findFirstLabel(in view: UIView) -> String? {
        if let label = view as? UILabel,
           let text = label.text,
           !text.isEmpty {
            return text
        }
        
        for subview in view.subviews {
            if let found = findFirstLabel(in: subview) {
                return found
            }
        }
        
        return nil
    }
    
    private func findParentCollectionView() -> UICollectionView? {
        var current: UIView? = superview
        while let view = current {
            if let collectionView = view as? UICollectionView {
                return collectionView
            }
            current = view.superview
        }
        return nil
    }
}

// MARK: - UITabBarController Swizzled Methods

extension UITabBarController {
    @objc dynamic func signals_setSelectedViewController(_ viewController: UIViewController?) {
        // Get index before we call original
        var oldIndex = selectedIndex
        // On first time through, it's some giant uninitialized value
        // If it's over 100, assume we're at initial state
        if oldIndex > 100 { oldIndex = 0 }
        let newIndex = viewControllers?.firstIndex(of: viewController ?? UIViewController()) ?? NSNotFound
        
        // Call original implementation
        self.signals_setSelectedViewController(viewController)
        
        // Only emit if we have a valid index change
        if newIndex != NSNotFound && newIndex != oldIndex {
            var data: [String: Any] = [
                "action": "tabSelected",
                "previousTab": oldIndex,
                "selectedTab": newIndex
            ]
            
            // Try to get tab names if available
            if let items = tabBar.items {
                if newIndex < items.count {
                    let newItem = items[newIndex]
                    if let title = newItem.accessibilityLabel ?? newItem.title {
                        data["selectedTabName"] = title
                    }
                }
                
                if oldIndex < items.count {
                    let oldItem = items[oldIndex]
                    if let title = oldItem.accessibilityLabel ?? oldItem.title {
                        data["previousTabName"] = title
                    }
                }
            }
            
            // Detect if this is SwiftUI TabView or UIKit UITabBarController
            let source = detectSource()
            
            let signal = InteractionSignal(
                component: "TabBar",
                title: nil,
                data: data
            )
            Signals.emit(signal: signal, source: source)
        }
    }
    
    /// Detects if this UITabBarController is hosted by SwiftUI
    private func detectSource() -> SignalSource {
        // First check the tabBarController's own view hierarchy
        if let source = checkViewHierarchy(view) {
            return source
        }
        
        // Also check if any child VCs are SwiftUI hosting controllers
        for vc in viewControllers ?? [] {
            let className = String(describing: type(of: vc))
            if className.contains("HostingController") {
                return .autoSwiftUI
            }
        }
        
        return .autoUIKit
    }
    
    private func checkViewHierarchy(_ view: UIView?) -> SignalSource? {
        var current: UIView? = view?.superview
        
        while let v = current {
            let typeName = String(describing: type(of: v))
            
            if typeName.contains("UIKitPlatformViewHost") ||
               typeName.contains("PlatformViewRepresentableAdaptor") ||
               typeName.contains("HostingView") {
                return .autoSwiftUI
            }
            
            current = v.superview
        }
        
        return nil
    }
}

// MARK: - UIPickerView Swizzled Methods & Delegate Proxy

/// Storage for original delegates (weak references)
private var originalDelegateKey: UInt8 = 0

extension UIPickerView {
    @objc dynamic func signals_setDelegate(_ delegate: UIPickerViewDelegate?) {
        if let delegate = delegate {
            // Check if this is SwiftUI-backed
            let source = ControlSignalSource.detect(for: self)
            if source == .autoSwiftUI {
                // Don't wrap SwiftUI delegates - let SignalPicker handle it
                signals_setDelegate(delegate)
                return
            }
            
            // Create proxy that wraps the original delegate
            let proxy = PickerViewDelegateProxy(originalDelegate: delegate, pickerView: self)
            
            // Store reference to keep proxy alive (associated object)
            objc_setAssociatedObject(self, &originalDelegateKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // Set proxy as delegate
            signals_setDelegate(proxy)
        } else {
            // Clear associated proxy when delegate is nil
            objc_setAssociatedObject(self, &originalDelegateKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            signals_setDelegate(nil)
        }
    }
}

/// Proxy that intercepts UIPickerViewDelegate calls to emit signals
private class PickerViewDelegateProxy: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    weak var originalDelegate: UIPickerViewDelegate?
    weak var originalDataSource: UIPickerViewDataSource?
    weak var pickerView: UIPickerView?
    
    init(originalDelegate: UIPickerViewDelegate, pickerView: UIPickerView) {
        self.originalDelegate = originalDelegate
        self.originalDataSource = originalDelegate as? UIPickerViewDataSource
        self.pickerView = pickerView
        super.init()
    }
    
    // MARK: - Signal Emission
    
    private func emitPickerSignal(row: Int, component: Int) {
        guard let pickerView = pickerView else { return }
        
        let title = extractTitle(for: pickerView)
        var data: [String: Any] = [
            "action": "selected",
            "selectedRow": row,
            "component": component,
            "numberOfComponents": pickerView.numberOfComponents
        ]
        
        // Try to get the title of the selected row
        if let rowTitle = originalDelegate?.pickerView?(pickerView, titleForRow: row, forComponent: component) {
            data["selectedTitle"] = rowTitle
        } else if let attributedTitle = originalDelegate?.pickerView?(pickerView, attributedTitleForRow: row, forComponent: component) {
            data["selectedTitle"] = attributedTitle.string
        }
        
        // Add accessibility info
        if let label = pickerView.accessibilityLabel, !label.isEmpty {
            data["accessibilityLabel"] = label
        }
        if let identifier = pickerView.accessibilityIdentifier, !identifier.isEmpty {
            data["accessibilityIdentifier"] = identifier
        }
        
        let signal = InteractionSignal(
            component: "Picker",
            title: title,
            data: data
        )
        Signals.emit(signal: signal, source: .autoUIKit)
    }
    
    private func extractTitle(for pickerView: UIPickerView) -> String? {
        if let label = pickerView.accessibilityLabel, !label.isEmpty {
            return label
        }
        if let identifier = pickerView.accessibilityIdentifier, !identifier.isEmpty {
            return identifier
        }
        // Try to find a label in the superview hierarchy
        return findLabelInSuperview(of: pickerView)
    }
    
    private func findLabelInSuperview(of view: UIView) -> String? {
        var current: UIView? = view.superview
        while let parent = current {
            // Look for labels that might be titles for this picker
            for subview in parent.subviews {
                if let label = subview as? UILabel,
                   let text = label.text,
                   !text.isEmpty,
                   subview !== view {
                    return text
                }
            }
            current = parent.superview
        }
        return nil
    }
    
    // MARK: - UIPickerViewDelegate (Intercepted)
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Emit signal first
        emitPickerSignal(row: row, component: component)
        
        // Forward to original delegate
        originalDelegate?.pickerView?(pickerView, didSelectRow: row, inComponent: component)
    }
    
    // MARK: - UIPickerViewDelegate (Forwarded)
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return originalDelegate?.pickerView?(pickerView, titleForRow: row, forComponent: component)
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return originalDelegate?.pickerView?(pickerView, attributedTitleForRow: row, forComponent: component)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        // This is required if the original delegate implements it
        if let view = originalDelegate?.pickerView?(pickerView, viewForRow: row, forComponent: component, reusing: view) {
            return view
        }
        // Fallback - return empty view (shouldn't happen if delegate implements titleForRow)
        return UIView()
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return originalDelegate?.pickerView?(pickerView, rowHeightForComponent: component) ?? 44.0
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return originalDelegate?.pickerView?(pickerView, widthForComponent: component) ?? 0
    }
    
    // MARK: - UIPickerViewDataSource (Forwarded)
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return originalDataSource?.numberOfComponents(in: pickerView) ?? 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return originalDataSource?.pickerView(pickerView, numberOfRowsInComponent: component) ?? 0
    }
    
    // MARK: - Message Forwarding for Other Methods
    
    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        return originalDelegate?.responds(to: aSelector) ?? false
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if originalDelegate?.responds(to: aSelector) == true {
            return originalDelegate
        }
        return super.forwardingTarget(for: aSelector)
    }
}

#endif
