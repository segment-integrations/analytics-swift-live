//
//  File.swift
//  
//
//  Created by Brandon Sneed on 3/18/24.
//

import Foundation
import Segment

public class SessionRecorder: SignalBroadcaster {
    public weak var analytics: Analytics? = nil
    
    public var signals = [any RawSignal]()
    public let recordingURL: URL
    
    public init(recordingFile: String) {
        self.recordingURL = URL(string: Self.getDocumentsDirectory().absoluteString + "\(recordingFile)")!
        
        print("Recording session at: \(recordingURL)")
    }
    
    public func added(signal: any RawSignal) {
        signals.append(signal)
        encode()
    }
    
    public func relay() {
        // do nothing
    }
}

extension SessionRecorder {
    func encode() {
        let json = try? JSON(signals)
        if let value = json?.prettyPrint() {
            let data = value.data(using: .utf8)
            try? data?.write(to: self.recordingURL)
        }
    }
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
