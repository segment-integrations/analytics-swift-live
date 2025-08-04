//
//  SignalUINavController.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 2/7/25.
//

#if canImport(UIKit) && !os(watchOS)

import UIKit
import ObjectiveC
import Segment

internal class NavigationSwizzler {
    static let shared = NavigationSwizzler()
    private var pushHandle: Swizzler.SwizzleHandle?
    private var popHandle: Swizzler.SwizzleHandle?
    private var popToVCHandle: Swizzler.SwizzleHandle?
    private var popToRootHandle: Swizzler.SwizzleHandle?
    @Atomic private var isRunning = false
    
    func start() {
        if isRunning {
            return
        }
        _isRunning.set(true)
        
        // Push tracking
        let pushSelector = #selector(UINavigationController.pushViewController(_:animated:))
        pushHandle = Swizzler.swizzle(originalClass: UINavigationController.self,
                                      originalSelector: pushSelector,
                                      swizzledSelector: #selector(UINavigationController.swizzled_pushViewController(_:animated:)))
        
        // Pop tracking
        let popSelector = #selector(UINavigationController.popViewController(animated:))
        popHandle = Swizzler.swizzle(originalClass: UINavigationController.self,
                                     originalSelector: popSelector,
                                     swizzledSelector: #selector(UINavigationController.swizzled_popViewController(animated:)))
        
        // Pop to specific VC tracking
        let popToVCSelector = #selector(UINavigationController.popToViewController(_:animated:))
        popToVCHandle = Swizzler.swizzle(originalClass: UINavigationController.self,
                                        originalSelector: popToVCSelector,
                                        swizzledSelector: #selector(UINavigationController.swizzled_popToViewController(_:animated:)))
        // Pop to root tracking
        let popToRootSelector = #selector(UINavigationController.popToRootViewController(animated:))
        popToRootHandle = Swizzler.swizzle(originalClass: UINavigationController.self,
                                          originalSelector: popToRootSelector,
                                          swizzledSelector: #selector(UINavigationController.swizzled_popToRootViewController(animated:)))
    }
    
    func stop() {
        if var handle = pushHandle {
            handle.restore()
        }
        if var handle = popHandle {
            handle.restore()
        }
        if var handle = popToRootHandle {
            handle.restore()
        }
        if var handle = popToVCHandle {
            handle.restore()
        }
        _isRunning.set(false)
    }
}

extension UINavigationController {
    private func getScreenName(from viewController: UIViewController?) -> String? {
        return viewController?.accessibilityLabel ?? viewController?.title ?? viewController?.navigationItem.title
    }
    
    private func emitNavigationSignal(to currentVC: UIViewController?, from previousVC: UIViewController?, fallback: String) {
        let navSignal = NavigationSignal(
            currentScreen: getScreenName(from: currentVC) ?? fallback,
            previousScreen: getScreenName(from: previousVC)
        )
        Signals.emit(signal: navSignal, source: .autoUIKit)
    }
    
    @objc dynamic func swizzled_pushViewController(_ viewController: UIViewController, animated: Bool) {
        let fromVC = topViewController
        self.swizzled_pushViewController(viewController, animated: animated)
        emitNavigationSignal(to: viewController, from: fromVC, fallback: "Unknown <push>")
    }

    @objc dynamic func swizzled_popViewController(animated: Bool) -> UIViewController? {
        let fromVC = topViewController
        let toVC = viewControllers.count > 1 ? viewControllers[viewControllers.count - 2] : nil
        let result = self.swizzled_popViewController(animated: animated)
        emitNavigationSignal(to: toVC, from: fromVC, fallback: "Unknown <pop>")
        return result
    }

    @objc dynamic func swizzled_popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let fromVC = topViewController
        let result = self.swizzled_popToViewController(viewController, animated: animated)
        emitNavigationSignal(to: viewController, from: fromVC, fallback: "Unknown <popTo>")
        return result
    }
    
    @objc dynamic func swizzled_popToRootViewController(animated: Bool) -> [UIViewController]? {
        let fromVC = topViewController
        let rootVC = viewControllers.first
        let result = self.swizzled_popToRootViewController(animated: animated)
        emitNavigationSignal(to: rootVC, from: fromVC, fallback: "Unknown <popToRoot>")
        return result
    }
}

#else

import Segment

internal class NavigationSwizzler {
    static let shared = NavigationSwizzler()
    @Atomic private var isRunning = false
    
    func start() {
        if isRunning {
            return
        }
        _isRunning.set(true)
        
        // TODO: Implement AppKit navigation tracking when needed
        // Will likely use NSSplitViewController or similar
    }
    
    func stop() {
        _isRunning.set(false)
    }
}

#endif
