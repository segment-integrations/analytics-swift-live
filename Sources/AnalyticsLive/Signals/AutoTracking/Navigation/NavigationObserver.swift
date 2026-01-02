//
//  NavigationObserver.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 12/30/25.
//

#if canImport(UIKit) && !os(watchOS)

import UIKit
import Segment

/// Observes navigation events via UIViewController lifecycle swizzling.
/// Works with both UIKit and SwiftUI apps - no wrapper types needed.
public class NavigationObserver {
    public static let shared = NavigationObserver()
    
    private init() {}
    
    /// Stack of screens that are "covered" by modals but not gone
    private var coveredScreens: [ScreenInfo] = []
    
    /// Track the current visible screen so we know what's being covered
    private var currentScreen: ScreenInfo?
    
    /// Whether swizzling is active
    @Atomic private var isRunning = false
    
    /// Enable debug logging to console
    public var debugLogging = false
    
    public func start() {
        guard !isRunning else { return }
        _isRunning.set(true)
        
        // Lifecycle swizzles
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.viewDidAppear(_:)),
            swizzled: #selector(UIViewController.signals_viewDidAppear(_:))
        )
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.viewWillDisappear(_:)),
            swizzled: #selector(UIViewController.signals_viewWillDisappear(_:))
        )
        
        // Presentation swizzles
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.present(_:animated:completion:)),
            swizzled: #selector(UIViewController.signals_present(_:animated:completion:))
        )
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.dismiss(animated:completion:)),
            swizzled: #selector(UIViewController.signals_dismiss(animated:completion:))
        )
        
        log("🔧 NavigationObserver: Started")
    }
    
    public func stop() {
        guard isRunning else { return }
        
        // Swap back to originals
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.signals_viewDidAppear(_:)),
            swizzled: #selector(UIViewController.viewDidAppear(_:))
        )
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.signals_viewWillDisappear(_:)),
            swizzled: #selector(UIViewController.viewWillDisappear(_:))
        )
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.signals_present(_:animated:completion:)),
            swizzled: #selector(UIViewController.present(_:animated:completion:))
        )
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.signals_dismiss(animated:completion:)),
            swizzled: #selector(UIViewController.dismiss(animated:completion:))
        )
        
        _isRunning.set(false)
        coveredScreens.removeAll()
        currentScreen = nil
        
        log("🔧 NavigationObserver: Stopped")
    }
    
    private func swizzle(cls: AnyClass, original: Selector, swizzled: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, original),
              let swizzledMethod = class_getInstanceMethod(cls, swizzled) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    // MARK: - Screen Tracking
    
    func screenAppeared(_ vc: UIViewController) {
        let info = ScreenInfo.extract(from: vc)
        
        // Filter out container noise
        guard !info.isContainerNoise else { return }
        
        let prev = currentScreen
        currentScreen = info
        
        // Emit navigation signal with full screen data
        let source: SignalSource = info.isSwiftUI ? .autoSwiftUI : .autoUIKit
        let signal = NavigationSignal(
            currentScreen: info.toScreenData(),
            previousScreen: prev?.toScreenData()
        )
        Signals.emit(signal: signal, source: source)
        
        log("📱 ENTERED: \(info.bestName)")
    }
    
    func screenDisappearing(_ vc: UIViewController) {
        let info = ScreenInfo.extract(from: vc)
        
        // Filter out container noise
        guard !info.isContainerNoise else { return }
        
        log("👋 LEFT: \(info.bestName)")
    }
    
    func modalWillPresent(from presentingVC: UIViewController, to presentedVC: UIViewController) {
        // Use currentScreen - we already know what's visible!
        if let coveredInfo = currentScreen {
            coveredScreens.append(coveredInfo)
            log("📥 COVERED: \(coveredInfo.bestName)")
        }
        
        // Set up dismissal detection for swipe-to-dismiss
        if let presentationController = presentedVC.presentationController {
            let detector = DismissalDetector(observer: self)
            presentationController.delegate = detector
            // Store it so it doesn't get deallocated
            objc_setAssociatedObject(presentedVC, &AssociatedKeys.dismissalDetector, detector, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func modalDidDismiss() {
        returnToCoveredScreenIfNeeded()
    }
    
    private func returnToCoveredScreenIfNeeded() {
        guard let returnTo = coveredScreens.popLast() else { return }
        
        let prev = currentScreen
        currentScreen = returnTo
        
        // Emit navigation signal for returning to covered screen with full data
        let source: SignalSource = returnTo.isSwiftUI ? .autoSwiftUI : .autoUIKit
        let signal = NavigationSignal(
            currentScreen: returnTo.toScreenData(),
            previousScreen: prev?.toScreenData()
        )
        Signals.emit(signal: signal, source: source)
        
        log("🔙 RETURNED TO: \(returnTo.bestName)")
    }
    
    private func log(_ message: String) {
        if debugLogging {
            print(message)
        }
    }
}

// MARK: - Associated Object Keys

private struct AssociatedKeys {
    static var dismissalDetector: UInt8 = 0
}

// MARK: - Dismissal Detector (for swipe-to-dismiss)

class DismissalDetector: NSObject, UIAdaptivePresentationControllerDelegate {
    weak var observer: NavigationObserver?
    
    init(observer: NavigationObserver) {
        self.observer = observer
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        observer?.modalDidDismiss()
    }
}

// MARK: - UIViewController Swizzled Methods

extension UIViewController {
    @objc func signals_viewDidAppear(_ animated: Bool) {
        // Call original implementation
        signals_viewDidAppear(animated)
        NavigationObserver.shared.screenAppeared(self)
    }
    
    @objc func signals_viewWillDisappear(_ animated: Bool) {
        // Call original implementation
        signals_viewWillDisappear(animated)
        NavigationObserver.shared.screenDisappearing(self)
    }
    
    @objc func signals_present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        // Notify observer before presenting
        NavigationObserver.shared.modalWillPresent(from: self, to: viewControllerToPresent)
        
        // Call original implementation
        signals_present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    @objc func signals_dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        let hasPresenting = self.presentingViewController != nil
        let hasPresented = self.presentedViewController != nil
        
        // Call original implementation
        signals_dismiss(animated: flag, completion: {
            completion?()
            // Fire if this VC was presented or was presenting something
            if hasPresenting || hasPresented {
                NavigationObserver.shared.modalDidDismiss()
            }
        })
    }
}

// MARK: - Screen Info

/// Extracts useful info from a UIViewController for screen identification
struct ScreenInfo {
    let className: String
    let title: String?
    let navItemTitle: String?
    let swiftUIViewName: String?
    let accessibilityLabel: String?
    let accessibilityIdentifier: String?
    let isSwiftUI: Bool
    
    /// Is this just a container VC that we should ignore?
    var isContainerNoise: Bool {
        let noiseClasses = [
            // UIKit containers
            "UINavigationController",
            "UITabBarController",
            // SwiftUI internal containers
            "UIKitTabBarController",
            "UIKitNavigationController", 
            "TabHostingController",
            "UITrackingElementWindowController",
            "PresentationHostingController",
            "UIInputWindowController",
            "UIEditingOverlayViewController",
            // Keyboard-related VCs
            "_UICursorAccessoryViewController",
            "UICompatibilityInputViewController",
            "UISystemInputAssistantViewController",
            "UIPredictionViewController",
            "UISystemKeyboardDockController",
            "UIEditingOverlayViewController",
            "UIKeyboardHiddenViewController"
        ]
        
        // Direct class name match
        if noiseClasses.contains(className) {
            return true
        }
        
        // Filter private Apple VCs (start with _UI)
        if className.hasPrefix("_UI") {
            return true
        }
        
        // Filter system keyboard/input related VCs
        if className.hasPrefix("UISystem") && (className.contains("Keyboard") || className.contains("Input")) {
            return true
        }
        
        // Root hosting controller (not NavigationStack content)
        if className.hasPrefix("UIHostingController<") && 
           className.contains("RootModifier") {
            return true
        }
        
        return false
    }
    
    /// Best effort at a meaningful screen name
    var bestName: String {
        // Priority order:
        // 1. Navigation item title (set via .navigationTitle() in SwiftUI)
        // 2. View controller title
        // 3. Accessibility label
        // 4. Accessibility identifier
        // 5. Extracted SwiftUI view name from generic soup
        // 6. Raw class name
        if let navTitle = navItemTitle, !navTitle.isEmpty {
            return navTitle
        }
        if let title = title, !title.isEmpty {
            return title
        }
        if let accLabel = accessibilityLabel, !accLabel.isEmpty {
            return accLabel
        }
        if let accId = accessibilityIdentifier, !accId.isEmpty {
            return accId
        }
        if let swiftUIName = swiftUIViewName, swiftUIName != "AnyView" {
            return swiftUIName
        }
        return className
    }
    
    static func extract(from vc: UIViewController) -> ScreenInfo {
        let className = String(describing: type(of: vc))
        let swiftUIName = extractSwiftUIViewName(from: className)
        let isSwiftUI = className.contains("HostingController")
        
        return ScreenInfo(
            className: className,
            title: vc.title,
            navItemTitle: vc.navigationItem.title,
            swiftUIViewName: swiftUIName,
            accessibilityLabel: vc.view?.accessibilityLabel,
            accessibilityIdentifier: vc.view?.accessibilityIdentifier,
            isSwiftUI: isSwiftUI
        )
    }
    
    /// Convert to NavigationSignal.ScreenData for signal emission
    func toScreenData() -> NavigationSignal.ScreenData {
        return NavigationSignal.ScreenData(
            name: bestName,
            className: className,
            title: title,
            navTitle: navItemTitle,
            swiftUIViewName: swiftUIViewName,
            accessibilityLabel: accessibilityLabel,
            accessibilityIdentifier: accessibilityIdentifier
        )
    }
    
    /// Try to extract a SwiftUI view name from UIHostingController's generic type
    private static func extractSwiftUIViewName(from className: String) -> String? {
        guard className.contains("HostingController") || className.contains("Hosting") else {
            return nil
        }
        
        guard let startIndex = className.firstIndex(of: "<"),
              let endIndex = className.lastIndex(of: ">") else {
            return nil
        }
        
        let genericContent = String(className[className.index(after: startIndex)..<endIndex])
        
        let components = genericContent
            .replacingOccurrences(of: ">", with: ",")
            .replacingOccurrences(of: "<", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        for component in components {
            // Skip internal SwiftUI types
            if component.hasPrefix("_") || 
               component.contains("Modifier") ||
               component.contains("Content") ||
               component == "Never" ||
               component == "Text" ||
               component == "Optional" ||
               component == "AnyView" {
                continue
            }
            
            if component.hasSuffix("View") {
                return component
            }
            
            if component.first?.isUppercase == true && 
               !component.contains(".") &&
               component.count > 2 {
                return component
            }
        }
        
        if genericContent.contains("AnyView") {
            return "AnyView"
        }
        
        return nil
    }
}

#endif
