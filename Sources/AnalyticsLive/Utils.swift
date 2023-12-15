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
