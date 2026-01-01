//
//  ContentView.swift
//  SwiftUIControlsExample
//
//  Created by Brandon Sneed on 12/30/25.
//

import SwiftUI
import AnalyticsLive

typealias Button = SignalButton
typealias TextField = SignalTextField
typealias SecureField = SignalSecureField
typealias List = SignalList

struct ContentView: View {
    // State for interactive controls
    @State private var textFieldValue = ""
    @State private var secureFieldValue = ""
    @State private var textEditorValue = "Some text"
    @State private var toggleValue = false
    @State private var sliderValue: Double = 0.5
    @State private var stepperValue: Int = 0
    @State private var pickerValue = 0
    @State private var datePickerValue = Date()
    @State private var colorPickerValue = Color.blue
    
    @State private var hierarchyOutput: String = "Tap 'Inspect Hierarchy' to analyze"
    
    var body: some View {
        NavigationStack {
            List {
                Section("Controls Under Test") {
                    // Button
                    Button("Test Button") {
                        print("Button tapped")
                    }
                    .accessibilityIdentifier("testButton")
                    
                    // TextField
                    TextField("Enter text", text: $textFieldValue)
                        .accessibilityIdentifier("testTextField")
                    
                    // SecureField
                    SecureField("Password", text: $secureFieldValue)
                        .accessibilityIdentifier("testSecureField")
                    
                    // TextEditor (needs fixed height in List)
                    TextEditor(text: $textEditorValue)
                        .frame(height: 80)
                        .accessibilityIdentifier("testTextEditor")
                    
                    // Toggle
                    SignalToggle("Test Toggle", isOn: $toggleValue)
                        .accessibilityIdentifier("testToggle")
                    
                    // Slider
                    VStack(alignment: .leading) {
                        Text("Slider: \(sliderValue, specifier: "%.2f")")
                        Slider(value: $sliderValue)
                            .accessibilityIdentifier("testSlider")
                    }
                    
                    // Stepper
                    Stepper("Value: \(stepperValue)", value: $stepperValue)
                        .accessibilityIdentifier("testStepper")
                    
                    // Picker (default/menu style)
                    Picker("Option", selection: $pickerValue) {
                        Text("Option A").tag(0)
                        Text("Option B").tag(1)
                        Text("Option C").tag(2)
                    }
                    .accessibilityIdentifier("testPicker")
                    
                    // Picker (segmented style)
                    Picker("Segmented", selection: $pickerValue) {
                        Text("A").tag(0)
                        Text("B").tag(1)
                        Text("C").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("testSegmentedPicker")
                    
                    // DatePicker
                    DatePicker("Date", selection: $datePickerValue)
                        .accessibilityIdentifier("testDatePicker")
                    
                    // ColorPicker
                    ColorPicker("Color", selection: $colorPickerValue)
                        .accessibilityIdentifier("testColorPicker")
                    
                    // Menu
                    Menu("Test Menu") {
                        Button("Action 1") { }
                        Button("Action 2") { }
                    }
                    .accessibilityIdentifier("testMenu")
                    
                    // Link
                    Link("Test Link", destination: URL(string: "https://segment.com")!)
                        .accessibilityIdentifier("testLink")
                }
                
                Section("List Selection Tests") {
                    NavigationLink("Single Selection List") {
                        SingleSelectionListView()
                    }
                    NavigationLink("Multi Selection List") {
                        MultiSelectionListView()
                    }
                    NavigationLink("Tap to Select (always edit mode)") {
                        TapToSelectListView()
                    }
                    NavigationLink("Edit Mode Selection (tap Edit first)") {
                        EditModeSelectionListView()
                    }
                }
                
                Section("Hierarchy Analysis") {
                    Button("Inspect Hierarchy") {
                        hierarchyOutput = inspectViewHierarchy()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text(hierarchyOutput)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Control Inspector")
        }
    }
    
    func inspectViewHierarchy() -> String {
        var output = ""
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return "Could not access window"
        }
        
        output += "=== UIKit View Hierarchy ===\n\n"
        output += inspectView(window, depth: 0)
        
        return output
    }
    
    func inspectView(_ view: UIView, depth: Int) -> String {
        var output = ""
        let indent = String(repeating: "  ", count: depth)
        let viewType = String(describing: type(of: view))
        
        // Highlight interesting types
        let isUIKit = viewType.hasPrefix("UI") && !viewType.contains("Hosting")
        let isHosting = viewType.contains("Hosting")
        let isSwiftUI = viewType.hasPrefix("_") || viewType.contains("SwiftUI")
        
        var marker = ""
        if isUIKit && !isHosting {
            marker = " 🟡 UIKit"
        }
        
        // Get accessibility identifier if present
        var accessId = ""
        if let id = view.accessibilityIdentifier, !id.isEmpty {
            accessId = " [id: \(id)]"
        }
        
        output += "\(indent)\(viewType)\(accessId)\(marker)\n"
        
        // Recurse into subviews
        for subview in view.subviews {
            output += inspectView(subview, depth: depth + 1)
        }
        
        return output
    }
}

// MARK: - List Selection Test Views

struct SingleSelectionListView: View {
    @State private var selection: String? = nil
    let items = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
    
    var body: some View {
        List(items, id: \.self, selection: $selection) { item in
            Text(item)
        }
        .navigationTitle("Single Selection")
        .toolbar {
            EditButton()
        }
        .onChange(of: selection) { oldValue, newValue in
            print("Single selection changed: \(String(describing: newValue))")
        }
    }
}

struct MultiSelectionListView: View {
    @State private var selection: Set<String> = []
    let items = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
    
    var body: some View {
        List(items, id: \.self, selection: $selection) { item in
            Text(item)
        }
        .navigationTitle("Multi Selection")
        .toolbar {
            EditButton()
        }
        .onChange(of: selection) { oldValue, newValue in
            print("Multi selection changed: \(newValue)")
        }
    }
}

// Tap-to-select pattern (edit mode forced on, checkmarks appear on tap)
struct TapToSelectListView: View {
    @State private var selection: Set<String> = []
    let items = ["Red", "Green", "Blue", "Yellow", "Purple"]
    
    var body: some View {
        List(items, id: \.self, selection: $selection) { item in
            Text(item)
        }
        .navigationTitle("Tap to Select")
        .environment(\.editMode, .constant(.active)) // Force edit mode for checkmarks
        .onChange(of: selection) { oldValue, newValue in
            print("Tap selection changed: \(newValue)")
        }
    }
}

// Edit mode selection - must tap Edit button to enable selection
struct EditModeSelectionListView: View {
    @State private var selection: Set<String> = []
    let items = ["Coffee", "Tea", "Juice", "Water", "Soda"]
    
    var body: some View {
        List(items, id: \.self, selection: $selection) { item in
            Text(item)
        }
        .navigationTitle("Edit Mode Selection")
        .toolbar {
            EditButton()
        }
        .onChange(of: selection) { oldValue, newValue in
            print("Edit mode selection changed: \(newValue)")
        }
    }
}

#Preview {
    ContentView()
}
