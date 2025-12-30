//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/15/24.
//

import Foundation
import SwiftUI

// These aliases need to go into the containing app. They're included here
// simply as a placeholder and are not exported.

// Selection & Input Controls
typealias Button = SignalButton
typealias TextField = SignalTextField
typealias SecureField = SignalSecureField
typealias Picker = SignalPicker
typealias Toggle = SignalToggle
#if !os(tvOS)
typealias Slider = SignalSlider
typealias Stepper = SignalStepper
#endif

// List & Collection Views
typealias List = SignalList
//typealias ScrollView = SignalScrollView
//@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
//typealias TabView = SignalTabView
