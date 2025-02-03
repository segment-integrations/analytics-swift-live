//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/21/24.
//

import Foundation
import SwiftUI

internal func describe(label: String) -> String? {
    let s = label
    if let r = s.range(of: "Signals.SignalAnnotation(text:") {
        let substring = String(s[r.upperBound...])
        let annotation = substring.components(separatedBy: "\"").dropFirst().first
        return annotation
    }
    
    let label = s.components(separatedBy: "\"").dropFirst().first
    return label
}

internal func describe(label: Any?) -> String? {
    if label == nil { return nil }
    return describe(label: String(describing: label))
}

internal func describeWith(options: [Any?]) -> String? {
    var result: String? = nil
    for opt in options {
        guard let opt else { continue }
        if let s = describe(label: String(describing: opt)), s.count > 0 {
            result = s
            return result
        }
    }
    return result
}
