//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/26/24.
//

import Foundation
import SwiftUI
import Segment

// MARK: -- Manual Signal Emitters

extension Signaling {
    public func signalLocalData<T: Codable>(action: LocalDataSignal.LocalDataAction, identifier: String, model: T) {
        if let json = try? JSON(with: model) {
            let s = LocalDataSignal(action: action, identifier: identifier, data: json.dictionaryValue)
            Signals.emit(signal: s)
        }
    }
    
    public func signalLocalData(action: LocalDataSignal.LocalDataAction, identifier: String) where Self: Codable {
        if let json = try? JSON(with: self) {
            let s = LocalDataSignal(action: action, identifier: identifier, data: json.dictionaryValue)
            Signals.emit(signal: s)
        }
    }
}

extension View {
    public func signalNavigation(_ screen: String) -> some View {
        SignalNavCache.shared.push(root: screen, source: .manual)
        return self
    }
    
    public func signalInteraction(component: String, title: String, data: [String: Any]? = nil) -> some View {
        let s = InteractionSignal(component: component, title: title, data: data)
        Signals.shared.emit(signal: s, source: .manual)
        return self
    }
    
    public func signalLocalData<T: Codable>(action: LocalDataSignal.LocalDataAction, identifier: String, model: T) -> some View {
        if let json = try? JSON(with: model) {
            let s = LocalDataSignal(action: action, identifier: identifier, data: json.dictionaryValue)
            Signals.emit(signal: s)
        }
        return self
    }
}

