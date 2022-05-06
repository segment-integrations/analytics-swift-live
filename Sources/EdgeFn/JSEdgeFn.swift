//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/5/22.
//

import Foundation
import JavaScriptCore
import Substrata
import UIKit

@objc
public protocol JSEdgeFnExports: JSExport {
    // JS doesn't have enums, so we need to convert type;
    // See `EdgeFnType` on the JS side.
    init(type: String, destination: String?)
    
    func update(_ settings: JSObject, _ initial: Bool)
    func execute(_ event: JSObject) -> JSObject?
    func identify(_ event: JSObject) -> JSObject?
    func track(_ event: JSObject) -> JSObject?
    func group(_ event: JSObject) -> JSObject?
    func alias(_ event: JSObject) -> JSObject?
    func screen(_ event: JSObject) -> JSObject?
    func reset()
    func flush()
}

@objc
public class JSEdgeFn: NSObject, JSEdgeFnExports, JSConvertible {
    weak var edgeFn: EdgeFn? = nil
    
    required public init(type: String, destination: String?) {
        /*switch type {
            
        }
        self.edgeFn = EdgeFn(*/
    }
    
    public func update(_ settings: [String : Any], _ initial: Bool) {
        
    }
    
    public func execute(_ event: [String : Any]) -> [String : Any]? {
        return nil
    }
    
    public func identify(_ event: [String : Any]) -> [String : Any]? {
        return nil
    }
    
    public func track(_ event: [String : Any]) -> [String : Any]? {
        return nil
    }
    
    public func group(_ event: [String : Any]) -> [String : Any]? {
        return nil
    }
    
    public func alias(_ event: [String : Any]) -> [String : Any]? {
        return nil
    }
    
    public func screen(_ event: [String : Any]) -> [String : Any]? {
        return nil
    }
    
    public func reset() {
        
    }
    
    public func flush() {
        
    }
    
    
}
