//
//  StorageJS.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 10/23/25.
//
import Foundation
import Substrata

internal class StorageJS: JSExport {
    static let NULL_SENTINEL = "__SENTINEL_NSDEFAULTS_NULL__"
    var userDefaults = UserDefaults(suiteName: "live.analytics.storage")
    required init() {
        super.init()
        exportMethod(named: "getValue", function: getValue)
        exportMethod(named: "setValue", function: setValue)
        exportMethod(named: "removeValue", function: removeValue)
    }
    
    func setValue(args: [JSConvertible?]) throws -> JSConvertible? {
        guard let key = args.typed(as: String.self, index: 0) else { return nil }
        let value: JSConvertible? = args.index(1)
        if isBasicType(value: value) {
            // Sanitize NSNull values before storing
            let sanitized = sanitizeForUserDefaults(value as Any)
            
            // need to do some type checking cuz some things easily translate to strings,
            // and we need to validate that it's something UserDefaults can actually take.
            if let v = sanitized as? Bool {
                userDefaults?.set(v, forKey: key)
            } else if let v = sanitized as? NSNumber {
                userDefaults?.set(v, forKey: key)
            } else if let v = sanitized as? Date {
                userDefaults?.set(v, forKey: key)
            } else if let v = sanitized as? String {
                userDefaults?.set(v, forKey: key)
            } else if let v = sanitized as? [String: Any] {
                userDefaults?.set(v, forKey: key)
            } else if let v = sanitized as? [Any] {
                userDefaults?.set(v, forKey: key)
            }
            // queries to userDefaults happen async, so make sure we're done before moving on.
            // we're already on a background thread.
            userDefaults?.synchronize()
        }
        return nil; // translates to Undefined in JS
    }

    func getValue(args: [JSConvertible?]) throws -> JSConvertible? {
        guard let key = args.typed(as: String.self, index: 0) else { return nil }
        guard let value = userDefaults?.value(forKey: key) else { return nil }
        
        // Desanitize NSNull sentinel values
        let desanitized = desanitizeFromUserDefaults(value)
        
        return convertToJSConvertible(desanitized)
    }
    
    func removeValue(args: [JSConvertible?]) throws -> JSConvertible? {
        guard let key = args.typed(as: String.self, index: 0) else { return nil }
        userDefaults?.removeObject(forKey: key)
        // queries to userDefaults happen async, so make sure we're done before moving on.
        // we're already on a background thread.
        userDefaults?.synchronize()
        return nil; // undefined in js
    }
}

extension StorageJS {
    internal func isBasicType<T>(value: T?) -> Bool {
        var result = false
        if value == nil {
            result = true
        } else {
            switch value {
            case is NSNull:
                fallthrough
            case is Array<Any>:
                fallthrough
            case is Dictionary<String, Any>:
                fallthrough
            case is Decimal:
                fallthrough
            case is NSNumber:
                fallthrough
            case is Bool:
                fallthrough
            case is Date:
                fallthrough
            case is String:
                result = true
            default:
                break
            }
        }
        return result
    }
    
    func convertToJSConvertible(_ value: Any) -> JSConvertible? {
        // Fast path - already JSConvertible
        if let v = value as? JSConvertible {
            return v
        }
        
        // Handle NSNull explicitly
        if value is NSNull {
            return NSNull()
        }
        
        // Foundation -> Swift bridging (check BEFORE Swift types)
        if let v = value as? NSNumber {
            // Check if it's actually a boolean
            let objCType = String(cString: v.objCType)
            if objCType == "c" || objCType == "B" {
                return v.boolValue
            }
            // Otherwise treat as number
            return v.doubleValue
        }
        if let v = value as? NSString {
            return v as String
        }
        
        // Direct Swift types
        if let v = value as? Bool { return v }
        if let v = value as? Int { return v }
        if let v = value as? Double { return v }
        if let v = value as? String { return v }
        if let v = value as? Date { return v }
        
        // Arrays - recursively convert each element
        if let array = value as? [Any] {
            let converted = array.compactMap { convertToJSConvertible($0) }
            return converted.isEmpty && !array.isEmpty ? nil : converted
        }
        
        // Dictionaries - recursively convert values
        if let dict = value as? [String: Any] {
            var converted: [String: JSConvertible] = [:]
            for (key, val) in dict {
                if let convertedVal = convertToJSConvertible(val) {
                    converted[key] = convertedVal
                }
            }
            return converted.isEmpty && !dict.isEmpty ? nil : converted
        }
        
        return nil
    }

    func sanitizeForUserDefaults(_ value: Any) -> Any? {
        if value is NSNull {
            return StorageJS.NULL_SENTINEL
        }
        if let array = value as? [Any] {
            return array.map { sanitizeForUserDefaults($0) ?? StorageJS.NULL_SENTINEL }
        }
        if let dict = value as? [String: Any] {
            return dict.mapValues { sanitizeForUserDefaults($0) ?? StorageJS.NULL_SENTINEL }
        }
        return value
    }

    func desanitizeFromUserDefaults(_ value: Any) -> Any {
        if let str = value as? String, str == StorageJS.NULL_SENTINEL {
            return NSNull()
        }
        if let array = value as? [Any] {
            return array.map { desanitizeFromUserDefaults($0) }
        }
        if let dict = value as? [String: Any] {
            return dict.mapValues { desanitizeFromUserDefaults($0) }
        }
        return value
    }
}
