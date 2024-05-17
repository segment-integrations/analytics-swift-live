//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/6/22.
//

import Foundation
import Segment
import Substrata

func toDictionary <T: Codable> (_ event: T) -> [String: Any]? {
    guard let json = try? JSON(with: event ) else { return nil }

    return json.dictionaryValue
}

extension Decodable {
    init?(fromDictionary from: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: from, options: .prettyPrinted) else { return nil }
        let decoder = JSONDecoder()
        if let newCodable = try? decoder.decode(Self.self, from: data) {
            self = newCodable
        } else {
            return nil
        }
    }
}

extension Array {
    func toJSConvertible() -> [JSConvertible] {
        let result = self.map { value in
            if let v = value as? JSConvertible {
                return v
            } else {
                if let v = value as? [String: Any] {
                    return v.toJSConvertible()
                } else if let v = value as? [Any] {
                    return v.toJSConvertible()
                }
                return NSNull()
            }
        }
        return result
    }
}

extension Dictionary where Key == String {
    public func toJSConvertible() -> [String: JSConvertible] {
        var result = [String: JSConvertible]()
        
        result = self.mapValues({ value in
            if let v = value as? JSConvertible {
                return v
            } else {
                if let v = value as? [String: Any] {
                    return v.toJSConvertible()
                } else if let v = value as? [Any] {
                    return v.toJSConvertible()
                }
                return NSNull()
            }
        })
        
        return result
        
    }
}
