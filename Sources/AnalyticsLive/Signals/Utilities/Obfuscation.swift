//
//  File.swift
//  
//
//  Created by Brandon Sneed on 3/11/24.
//

import Foundation
import Segment

public protocol JSONObfuscation {
    func obfuscated() -> any RawSignal
}

extension LocalDataSignal: JSONObfuscation {
    public func obfuscated() -> any RawSignal {
        var working = self
        let wData = working.data
        let obfuscated = obfuscate(working.data.data)
        working.data = LocalData(action: wData.action, identifier: wData.identifier, data: obfuscated)
        return working
    }
}

extension InstrumentationSignal: JSONObfuscation {
    public func obfuscated() -> any RawSignal {
        var working = self
        let wData = working.data
        let obfuscated = obfuscate(working.data.rawEvent)
        let data = InstrumentationData(type: wData.type, rawEvent: obfuscated)
        working.data = data
        return working
    }
}

extension NetworkSignal: JSONObfuscation {
    public func obfuscated() -> any RawSignal {
        var working = self
        let wData = working.data
        let obfuscated = obfuscate(working.data.body)
        let data = NetworkSignal.NetworkData(
            action: wData.action,
            url: wData.url,
            body: obfuscated,
            contentType: wData.contentType,
            method: wData.method,
            status: wData.status,
            ok: wData.ok,
            requestId: wData.requestId
        )
        working.data = data
        return working
    }
}

extension JSONObfuscation {
    func obfuscate(_ data: JSON?) -> JSON? {
        guard let data else { return data }
        
        switch data {
        case .null:
            return JSON.null
        case .bool(let b):
            return obfuscate(b)
        case .number(let n):
            return obfuscate(n)
        case .string(let s):
            return obfuscate(s)
        case .array(let a):
            return obfuscate(a)
        case .object(let o):
            return obfuscate(o)
        }
    }
    
    func obfuscate(_ value: Bool) -> JSON? {
        return try? JSON("true/false")
    }
    
    func obfuscate(_ value: Decimal) -> JSON? {
        var strResult = ""
        let str = value.toString()
        let split = str.components(separatedBy: ".")
        if let left = split.first {
            strResult += String(repeating: "9", count: left.count)
            if split.count > 1 {
                if let right = split.last {
                    strResult += "." + String(repeating: "9", count: right.count)
                }
            }
        } else {
            strResult = "999.99"
        }
        if let decimal = Decimal(string: strResult) {
            return try? JSON(decimal)
        } else {
            return try? JSON(999.99)
        }
    }
    
    func obfuscate(_ value: String) -> JSON? {
        var result = ""
        for character in value {
            if character.isLetter {
                result += "X"
            } else if character.isNumber {
                result += "9"
            } else {
                // If the character is neither a letter nor a number, keep it as it is.
                result += String(character)
            }
        }
        return try? JSON(result)
    }
    
    func obfuscate(_ values: [JSON]) -> JSON? {
        var array = [JSON]()
        for v in values {
            if let o = obfuscate(v) {
                array.append(o)
            }
        }
        return try? JSON(array)
    }
    
    func obfuscate(_ values: [String: JSON]) -> JSON? {
        var object = [String: JSON]()
        for (k, v) in values {
            if let o = obfuscate(v) {
                object[k] = o
            }
        }
        return try? JSON(object)
    }
}
