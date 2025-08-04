//
//  SignalUIViewController.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/7/25.
//

#if canImport(UIKit) && !os(watchOS)

import UIKit
import ObjectiveC
import SwiftUI
import Segment

internal class ModalSwizzler {
    static let shared = ModalSwizzler()
    private var presentHandle: Swizzler.SwizzleHandle?
    private var dismissHandle: Swizzler.SwizzleHandle?
    @Atomic private var isRunning = false
    internal var currentModalName: String?
    
    func start() {
        if isRunning {
            return
        }
        _isRunning.set(true)
        
        // Present tracking
        let presentSelector = #selector(UIViewController.present(_:animated:completion:))
        presentHandle = Swizzler.swizzle(originalClass: UIViewController.self,
                                       originalSelector: presentSelector,
                                       swizzledSelector: #selector(UIViewController.swizzled_present(_:animated:completion:)))
        
        // Dismiss tracking
        let dismissSelector = #selector(UIViewController.dismiss(animated:completion:))
        dismissHandle = Swizzler.swizzle(originalClass: UIViewController.self,
                                        originalSelector: dismissSelector,
                                        swizzledSelector: #selector(UIViewController.swizzled_dismiss(animated:completion:)))
    }
    
    func stop() {
        if var handle = presentHandle {
            handle.restore()
        }
        if var handle = dismissHandle {
            handle.restore()
        }
        _isRunning.set(false)
    }
}

extension UIViewController {
    private func extractBasicName(from vc: UIViewController?) -> String? {
        return vc?.accessibilityLabel ?? vc?.title ?? vc?.navigationItem.title
    }
    
    private func extractSwiftUIHostingName() -> String? {
        guard let hostingController = self as? UIHostingController<AnyView> else { return nil }
        
        let mirror = Mirror(reflecting: hostingController.rootView)
        let typeName = String(describing: mirror.subjectType)
            .replacingOccurrences(of: "ModifiedContent<", with: "")
            .replacingOccurrences(of: ", RootModifier>", with: "")
            .replacingOccurrences(of: ", _TraitWritingModifier<.*>>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "AnyView", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return typeName.isEmpty ? nil : typeName
    }
    
    var meaningfulName: String {
        // Try basic name extraction first
        if let name = extractBasicName(from: self) { return name }
        
        // If we're a nav controller, try the top VC
        if let nav = self as? UINavigationController,
           let name = extractBasicName(from: nav.topViewController) { return name }
        
        // If we have a nav controller, try its top VC
        if let name = extractBasicName(from: navigationController?.topViewController) { return name }
        
        // Try SwiftUI hosting controller
        if let name = extractSwiftUIHostingName() { return name }
        
        // Fall back to type name
        return String(describing: type(of: self))
    }
    
    @objc dynamic func swizzled_present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        let fromScreen = self.meaningfulName
        let modalScreen = viewControllerToPresent.meaningfulName
        
        self.swizzled_present(viewControllerToPresent, animated: animated, completion: completion)
        
        let navSignal = NavigationSignal(currentScreen: modalScreen, previousScreen: fromScreen)
        Signals.emit(signal: navSignal, source: .autoUIKit)
        
        ModalSwizzler.shared.currentModalName = modalScreen
    }
    
    @objc dynamic func swizzled_dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        let modalScreen = ModalSwizzler.shared.currentModalName ?? self.meaningfulName
        let backToScreen = presentingViewController?.meaningfulName
        
        self.swizzled_dismiss(animated: animated, completion: completion)
        
        let navSignal = NavigationSignal(
            currentScreen: backToScreen ?? "Unknown <dismissed>",
            previousScreen: modalScreen
        )
        Signals.emit(signal: navSignal, source: .autoUIKit)
        
        ModalSwizzler.shared.currentModalName = nil
    }
}

#endif
