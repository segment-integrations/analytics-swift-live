//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/6/22.
//

import Foundation
import Segment

extension Encodable {
    func asDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return nil
        }

        return recoverBoolValues(from: dictionary)
    }
}

/*
 Returns a new Dictionary with recovered BOOL values. Recursively checks the backing NSObject
 of dictionary values to see if they can be cast as a BOOL. If they can be it does so and uses
 the BOOL value (true/false) instead of the NSNumber value (1/0).
 */
func recoverBoolValues(from dictionary: [String: Any]) -> [String: Any] {
    var newDict = Dictionary<String, Any>()

    for (key, value) in dictionary {
        if let boolValue = value as? Bool {
            newDict[key] = boolValue
        } else if let nestedDictionary = value as? [String: Any] {
            // Recursively check nested dictionaries
            newDict[key] = recoverBoolValues(from: nestedDictionary)
        }
    }

    return newDict
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
