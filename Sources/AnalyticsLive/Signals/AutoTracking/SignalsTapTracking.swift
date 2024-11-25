//
//  SignalsTapTracking.swift
//  Shopify
//
//  Created by Brandon Sneed on 9/27/22.
//

#if os(iOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)

import Foundation
import UIKit
import Segment

class SignalsTapTracking: UtilityPlugin {
    let key: String = "SignalsTapTrackingPlugin"
    
    func configure(analytics: Analytics) {
        self.analytics = analytics
    }
    
    let type = PluginType.utility
    weak var analytics: Analytics? = nil
    
    init() {
        setupUIKitHooks()
    }

    internal func setupUIKitHooks() {
        swizzle(forClass: UIApplication.self,
                original: #selector(UIApplication.sendEvent(_:)),
                new: #selector(UIApplication.seg__sendEvent(_:))
        )
    }
    
    public func execute<T: RawEvent>(event: T?) -> T? {
        // do nothing.
        return event
    }
}

extension SignalsTapTracking {
    private func swizzle(forClass: AnyClass, original: Selector, new: Selector) {
        guard let originalMethod = class_getInstanceMethod(forClass, original) else { return }
        guard let swizzledMethod = class_getInstanceMethod(forClass, new) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension UIApplication {
    internal func getKeyWindow() -> UIWindow? {
        
        UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
    }

    @objc public func seg__sendEvent(_ event: UIEvent) {
        if let window = self.getKeyWindow() {
            if let x = event.touches(for: window)?.first {
                let control = String(describing: x.view.self)
                var title: String?
                
                switch x.view {
                case let v as UIButton:
                    title = v.currentTitle
                case .none:
                    break
                case .some(_):
                    break
                }
                
                Signals.emit(signal: InteractionSignal(component: control, title: title), source: .autoUIKit)
            }
        }
        seg__sendEvent(event)
    }
}

#endif
