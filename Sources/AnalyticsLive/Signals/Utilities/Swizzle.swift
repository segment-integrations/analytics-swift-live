//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/27/24.
//

import Foundation

internal func swizzle(forClass: AnyClass, original: Selector, new: Selector) {
    guard let originalMethod = class_getInstanceMethod(forClass, original) else { return }
    guard let swizzledMethod = class_getInstanceMethod(forClass, new) else { return }
    method_exchangeImplementations(originalMethod, swizzledMethod)
}
