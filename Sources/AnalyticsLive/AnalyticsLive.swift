//
//  Analytics-Live.swift
//  
//
//  Created by Brandon Sneed on 9/6/24.
//

import Foundation
import Segment
@_exported import AnalyticsLiveCore

#if DEBUG
public let ____analytics_live_debug = ____setSignalsDebugging(value: true)
#else
public let ____analytics_live_debug = ____setSignalsDebugging(value: false)
#endif
