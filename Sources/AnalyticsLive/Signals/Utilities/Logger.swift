//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/21/24.
//

import Foundation
import OSLog

func signals_emit_log(_ dict: [String: Any]) {
    #if DEBUG
    let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
    assert(data != nil, "ERROR: Unable to generate log for signal")
    guard let data else { return }
    guard let json = String(data: data, encoding: .utf8) else { return }
    print("\nSIGNAL EMITTED: \(json)\n")
    #endif
}
