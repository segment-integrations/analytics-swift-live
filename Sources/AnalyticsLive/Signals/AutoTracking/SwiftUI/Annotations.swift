//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/20/24.
//

import Foundation
import SwiftUI
import Segment

public struct SignalAnnotation: ViewModifier {
    let text: String
    init(_ text: String) {
        self.text = text
    }
    public func body(content: Content) -> some View {
        content
    }
}

extension View {
    public func signalAnnotation(_ text: String) -> some View {
        return modifier(SignalAnnotation(text))
    }
    
    public func signalAnnotation(state: Bool, true trueText: String, false falseText: String) -> some View {
        if state {
            return modifier(SignalAnnotation(trueText))
        } else {
            return modifier(SignalAnnotation(falseText))
        }
    }
    
    public func signalAnnotation<T>(state: T, text: (T) -> String) -> some View {
        let t = text(state)
        return modifier(SignalAnnotation(t))
    }
}



