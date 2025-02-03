//
//  ContentView.swift
//  BasicExample
//
//  Created by Brandon Sneed on 9/26/24.
//

import SwiftUI
import Segment

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Track Event") {
                Analytics.main.track(name: "Button Clicked")
            }
            Button("Identify Event") {
                Analytics.main.identify(userId: "Robbie Ray Rana")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
