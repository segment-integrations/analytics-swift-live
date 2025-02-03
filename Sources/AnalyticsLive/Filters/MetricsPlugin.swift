//
//  DestinationFilters.swift
//
//  Created by Prayansh Srivastava on 10/12/22.
//

import Foundation
//import Segment

/*
public class MetricsPlugin: SegmentPlugin {
    public let type: SegmentPluginType = .enrichment

    public var analytics: SegmentAnalytics? = nil

    private var activeDestinations = [String]()

    public init(setOfActiveDestinations: Set<String>) {
        activeDestinations = Array(setOfActiveDestinations)
    }

    public func configure(analytics: SegmentAnalytics) {
        self.analytics = analytics
    }

    public func execute<T: SegmentRawEvent>(event: T?) -> T? {
        guard var workingEvent = event else { return event }
        if var context = workingEvent.context?.dictionaryValue {
            context[keyPath: "plugins.destinations-filters"] = [
              "version": __analyticslivecore_version,
              "active": activeDestinations
            ] as [String : Any]
            do {
                workingEvent.context = try JSON(context)
            } catch {
                print("Unable to convert context to JSON: \(error)")
            }
        }
        return workingEvent
    }
}
*/
