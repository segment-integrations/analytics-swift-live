//
//  ControlSignalSource.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 12/30/25.
//

#if canImport(UIKit) && !os(watchOS)

import UIKit

/// Detects whether a UIKit control is being used directly in a UIKit app
/// or is wrapped by SwiftUI (via UIViewRepresentable or similar).
///
/// This allows universal swizzlers to work for both UIKit and SwiftUI apps
/// while reporting the correct SignalSource.
public struct ControlSignalSource {
    
    /// Determines the appropriate SignalSource for a UIView by walking up
    /// its ancestor chain looking for SwiftUI hosting views.
    ///
    /// - Parameter view: The UIKit view to check
    /// - Returns: `.autoSwiftUI` if the view is hosted by SwiftUI, `.autoUIKit` otherwise
    public static func detect(for view: UIView) -> SignalSource {
        var current: UIView? = view.superview
        
        while let v = current {
            let typeName = String(describing: type(of: v))
            
            // These indicate the view is hosted within SwiftUI
            if typeName.contains("UIKitPlatformViewHost") ||
               typeName.contains("PlatformViewRepresentableAdaptor") ||
               typeName.contains("HostingView") {
                return .autoSwiftUI
            }
            
            current = v.superview
        }
        
        return .autoUIKit
    }
    
    /// Convenience method that accepts an optional view
    ///
    /// - Parameter view: The UIKit view to check (optional)
    /// - Returns: `.autoSwiftUI` if the view is hosted by SwiftUI, `.autoUIKit` otherwise
    public static func detect(for view: UIView?) -> SignalSource {
        guard let view = view else { return .autoUIKit }
        return detect(for: view)
    }
}

#endif
