//
//  NavigationObserver.swift
//  SignalTestBed
//
//  Created by Brandon Sneed on 12/30/25.
//

import UIKit

/// Dead simple swizzler to see what UIViewController lifecycle events we can catch
/// from SwiftUI navigation. No framework dependencies, just print statements.
class NavigationObserver {
    static let shared = NavigationObserver()
    
    private init() {}
    
    /// Stack of screens that are "covered" by modals but not gone
    private var coveredScreens: [ScreenInfo] = []
    
    /// Track the current visible screen so we know what's being covered
    private var currentScreen: ScreenInfo?
    
    func start() {
        // Lifecycle swizzles
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.viewDidAppear(_:)),
            swizzled: #selector(UIViewController.swizzled_viewDidAppear(_:))
        )
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.viewWillDisappear(_:)),
            swizzled: #selector(UIViewController.swizzled_viewWillDisappear(_:))
        )
        
        // Presentation swizzles
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.present(_:animated:completion:)),
            swizzled: #selector(UIViewController.swizzled_present(_:animated:completion:))
        )
        swizzle(
            cls: UIViewController.self,
            original: #selector(UIViewController.dismiss(animated:completion:)),
            swizzled: #selector(UIViewController.swizzled_dismiss(animated:completion:))
        )
        
        print("🔧 NavigationObserver: Swizzling active")
    }
    
    private func swizzle(cls: AnyClass, original: Selector, swizzled: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, original),
              let swizzledMethod = class_getInstanceMethod(cls, swizzled) else {
            print("❌ Failed to swizzle \(original)")
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    // MARK: - Screen Tracking
    
    func screenAppeared(_ vc: UIViewController) {
        let info = ScreenInfo.extract(from: vc)
        
        // Filter out container noise
        guard !info.isContainerNoise else { return }
        
        currentScreen = info
        
        print("📱 ENTERED: \(info.bestName)")
        printDetails(info)
    }
    
    func screenDisappearing(_ vc: UIViewController) {
        let info = ScreenInfo.extract(from: vc)
        
        // Filter out container noise
        guard !info.isContainerNoise else { return }
        
        print("👋 LEFT: \(info.bestName)")
        
        // Don't try to detect modal dismiss here - too unreliable
        // We rely on DismissalDetector for swipe-to-dismiss
        // and we'll add dismiss() swizzle for programmatic dismiss
    }
    
    func modalWillPresent(from presentingVC: UIViewController, to presentedVC: UIViewController) {
        // Use currentScreen - we already know what's visible!
        if let coveredInfo = currentScreen {
            coveredScreens.append(coveredInfo)
            print("📥 COVERED: \(coveredInfo.bestName) (modal presenting)")
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
    
    private func checkForReturnToCoveredScreen(dismissedVC: UIViewController) {
        // Small delay to let the dismissal complete
        DispatchQueue.main.async { [weak self] in
            self?.returnToCoveredScreenIfNeeded()
        }
    }
    
    private func returnToCoveredScreenIfNeeded() {
        guard let returnTo = coveredScreens.popLast() else { return }
        
        print("🔙 RETURNED TO: \(returnTo.bestName)")
        printDetails(returnTo)
        currentScreen = returnTo
    }
    
    private func findActualContentScreen(from vc: UIViewController) -> ScreenInfo? {
        // Walk down to find the actual content, not containers
        if let nav = vc as? UINavigationController,
           let visible = nav.visibleViewController {
            return ScreenInfo.extract(from: visible)
        }
        if let tab = vc as? UITabBarController,
           let selected = tab.selectedViewController {
            return findActualContentScreen(from: selected)
        }
        return ScreenInfo.extract(from: vc)
    }
    
    private func printDetails(_ info: ScreenInfo) {
        print("   ├─ class: \(info.className)")
        print("   ├─ title: \(info.title ?? "nil")")
        print("   ├─ navTitle: \(info.navItemTitle ?? "nil")")
        print("   ├─ swiftUIName: \(info.swiftUIViewName ?? "nil")")
        print("   ├─ accLabel: \(info.accessibilityLabel ?? "nil")")
        print("   └─ accId: \(info.accessibilityIdentifier ?? "nil")")
    }
}

// MARK: - Associated Object Keys

private struct AssociatedKeys {
    static var dismissalDetector = "dismissalDetector"
}

// MARK: - Dismissal Detector (for swipe-to-dismiss)

class DismissalDetector: NSObject, UIAdaptivePresentationControllerDelegate {
    weak var observer: NavigationObserver?
    
    init(observer: NavigationObserver) {
        self.observer = observer
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("🔍 Swipe dismiss detected")
        observer?.modalDidDismiss()
    }
}

// MARK: - UIViewController Swizzled Methods

extension UIViewController {
    @objc func swizzled_viewDidAppear(_ animated: Bool) {
        // Call original implementation
        swizzled_viewDidAppear(animated)
        NavigationObserver.shared.screenAppeared(self)
    }
    
    @objc func swizzled_viewWillDisappear(_ animated: Bool) {
        // Call original implementation
        swizzled_viewWillDisappear(animated)
        NavigationObserver.shared.screenDisappearing(self)
    }
    
    @objc func swizzled_present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        // Notify observer before presenting
        NavigationObserver.shared.modalWillPresent(from: self, to: viewControllerToPresent)
        
        // Call original implementation
        swizzled_present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    @objc func swizzled_dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        let className = String(describing: type(of: self))
        let hasPresenting = self.presentingViewController != nil
        let hasPresented = self.presentedViewController != nil
        print("🔬 dismiss() called on \(className) | presentingVC: \(hasPresenting) | presentedVC: \(hasPresented)")
        
        // Call original implementation
        swizzled_dismiss(animated: flag, completion: {
            completion?()
            // Fire if this VC was presented (has a presentingViewController)
            // OR if this VC was presenting something (has a presentedViewController)
            if hasPresenting || hasPresented {
                print("🔍 Programmatic dismiss detected")
                NavigationObserver.shared.modalDidDismiss()
            }
        })
    }
}

// MARK: - Screen Info

/// Extracts whatever useful info we can from a UIViewController
struct ScreenInfo {
    let className: String
    let title: String?
    let navItemTitle: String?
    let swiftUIViewName: String?
    let accessibilityLabel: String?
    let accessibilityIdentifier: String?
    
    /// Is this just a container VC that we should ignore?
    var isContainerNoise: Bool {
        let noiseClasses = [
            "UIKitTabBarController",
            "UIKitNavigationController", 
            "TabHostingController",
            "UITrackingElementWindowController",
            "PresentationHostingController",
            "UIInputWindowController",
            "UIEditingOverlayViewController"
        ]
        
        // Direct class name match
        if noiseClasses.contains(className) {
            return true
        }
        
        // Root hosting controller (not NavigationStack content)
        // This is the wrapper around the whole app, not actual screens
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
        
        return ScreenInfo(
            className: className,
            title: vc.title,
            navItemTitle: vc.navigationItem.title,
            swiftUIViewName: swiftUIName,
            accessibilityLabel: vc.view.accessibilityLabel,
            accessibilityIdentifier: vc.view.accessibilityIdentifier
        )
    }
    
    /// Try to extract a SwiftUI view name from UIHostingController's generic type
    /// e.g. "UIHostingController<ProductDetailView>" -> "ProductDetailView"
    /// e.g. "UIHostingController<ModifiedContent<HomeView, _EnvironmentKeyWritingModifier<...>>>" -> "HomeView"
    private static func extractSwiftUIViewName(from className: String) -> String? {
        // Quick bail if not a hosting controller
        guard className.contains("HostingController") || className.contains("Hosting") else {
            return nil
        }
        
        // Try to find the first meaningful view name inside the generics
        // Look for pattern: SomethingView or Something that looks like a view name
        
        // First, try to get content between < and >
        guard let startIndex = className.firstIndex(of: "<"),
              let endIndex = className.lastIndex(of: ">") else {
            return nil
        }
        
        let genericContent = String(className[className.index(after: startIndex)..<endIndex])
        
        // Try to extract the first "word" that looks like a View name
        // Split on < and , to get potential view names
        let components = genericContent
            .replacingOccurrences(of: ">", with: ",")
            .replacingOccurrences(of: "<", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Look for something that ends in "View" or is a simple PascalCase name
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
            
            // If it ends in View, that's probably our target
            if component.hasSuffix("View") {
                return component
            }
            
            // If it's a simple PascalCase identifier, might be a view
            if component.first?.isUppercase == true && 
               !component.contains(".") &&
               component.count > 2 {
                return component
            }
        }
        
        // Fallback to AnyView if that's all we have
        if genericContent.contains("AnyView") {
            return "AnyView"
        }
        
        return nil
    }
}
