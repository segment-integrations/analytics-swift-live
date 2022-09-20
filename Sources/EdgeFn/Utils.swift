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
        return dictionary
    }
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
