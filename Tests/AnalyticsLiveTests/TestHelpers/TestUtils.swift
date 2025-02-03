//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/9/22.
//

import Foundation
import XCTest
@testable import Segment

func waitUntilStarted(analytics: Analytics?) {
    guard let analytics = analytics else { return }
    // wait until the startup queue has emptied it's events.
    if let startupQueue = analytics.find(pluginType: StartupQueue.self) {
        while startupQueue.running != true {
            RunLoop.main.run(until: Date.distantPast)
        }
    }
}

enum NetworkError: Error {
    case failed(URLError.Code)
}

class MyDestination: DestinationPlugin {
    var timeline: Timeline
    let type: PluginType
    let key: String
    weak var analytics: Analytics?
    let trackCompletion: (() -> Bool)?

    let disabled: Bool
    var receivedInitialUpdate: Int = 0

    init(disabled: Bool = false, trackCompletion: (() -> Bool)? = nil) {
        self.key = "MyDestination"
        self.type = .destination
        self.timeline = Timeline()
        self.trackCompletion = trackCompletion
        self.disabled = disabled
    }

    func update(settings: Settings, type: UpdateType) {
        if type == .initial { receivedInitialUpdate += 1 }
        if disabled == false {
            // add ourselves to the settings
            analytics?.manuallyEnableDestination(plugin: self)
        }
    }

    func track(event: TrackEvent) -> TrackEvent? {
        var returnEvent: TrackEvent? = event
        if let completion = trackCompletion {
            if !completion() {
                returnEvent = nil
            }
        }
        return returnEvent
    }
}

class OutputReaderPlugin: Plugin {
    let type: PluginType
    weak var analytics: Analytics?
    
    var events = [RawEvent]()
    var lastEvent: RawEvent? = nil
    
    init() {
        self.type = .after
    }
    
    func execute<T>(event: T?) -> T? where T : RawEvent {
        if let e = event {
            events.append(e)
            lastEvent = e
            print("TYPE: \(String(describing: e.type)), newEventCount = \(events.count)")
        }
        return event
    }
}

func differences(dict1: [String: Any], dict2: [String: Any]) -> [String: Any] {
    var diffs: [String: Any] = [:]
    
    for (key, value1) in dict1 {
        if let value2 = dict2[key] {
            // Check if both values are dictionaries, then recurse
            if let nestedDict1 = value1 as? [String: Any], let nestedDict2 = value2 as? [String: Any] {
                let nestedDiffs = differences(dict1: nestedDict1, dict2: nestedDict2)
                if !nestedDiffs.isEmpty {
                    diffs[key] = nestedDiffs
                }
            }
            // If the values are not dictionaries but are equal, do nothing
            else if "\(value1)" != "\(value2)" {
                // If values are not equal, store the difference
                diffs[key] = (value1, value2)
            }
        } else {
            // If the key only exists in dict1
            diffs[key] = (value1, NSNull())
        }
    }
    
    // Find keys that only exist in dict2
    for (key, value2) in dict2 {
        if dict1[key] == nil {
            diffs[key] = (NSNull(), value2)
        }
    }
    
    return diffs
}

// MARK: - memory leak detection

struct TimedOutError: Error, Equatable {}
public func waitForTaskCompletion<R>(
    withTimeoutInSeconds timeout: UInt64,
    _ task: @escaping () async throws -> R
) async throws -> R {
    return try await withThrowingTaskGroup(of: R.self) { group in
        await withUnsafeContinuation { continuation in
            group.addTask {
                continuation.resume()
                return try await task()
            }
        }
        group.addTask {
            await Task.yield()
            try await Task.sleep(nanoseconds: timeout * 1_000_000_000)
            throw TimedOutError()
        }
        defer { group.cancelAll() }
        return try await group.next()!
    }
}

extension XCTestCase {
    func checkIfLeaked(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            if instance != nil {
                print("Instance \(String(describing: instance)) is not nil")
            }
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak!", file: file, line: line)
        }
    }
    
    func waitUntilFinished(analytics: Analytics?, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak analytics] in
            let instance = try await waitForTaskCompletion(withTimeoutInSeconds: 3) {
                while analytics != nil {
                    DispatchQueue.main.sync {
                        RunLoop.current.run(until: .distantPast)
                    }
                }
                return analytics
            }
            XCTAssertNil(instance, "Analytics should have been deallocated. It's likely a memory leak!", file: file, line: line)
        }
    }
}
