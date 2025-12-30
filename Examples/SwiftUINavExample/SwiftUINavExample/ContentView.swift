//
//  ContentView.swift
//  SwiftUINavExample
//
//  Created by Brandon Sneed on 12/30/25.
//

import SwiftUI

// MARK: - Main Tab View

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Navigation", systemImage: "arrow.triangle.turn.up.right.diamond") {
                NavigationTestView()
            }
            Tab("Sheets", systemImage: "square.stack") {
                SheetTestView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}

// MARK: - Navigation Tests

struct NavigationTestView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Basic NavigationLink") {
                    // Classic NavigationLink with destination closure
                    NavigationLink("Detail View (closure)") {
                        DetailView(title: "From Closure")
                    }
                    
                    // NavigationLink with label
                    NavigationLink {
                        DetailView(title: "From Label Builder")
                    } label: {
                        Label("Detail View (label)", systemImage: "star")
                    }
                }
                
                Section("Value-Based Navigation") {
                    // Value-based - uses navigationDestination(for:)
                    NavigationLink("Product: iPhone", value: Product(name: "iPhone", price: 999))
                    NavigationLink("Product: MacBook", value: Product(name: "MacBook", price: 1999))
                    NavigationLink("Product: AirPods", value: Product(name: "AirPods", price: 249))
                }
                
                Section("Programmatic Navigation") {
                    Button("Push 3 screens programmatically") {
                        path.append(Product(name: "First", price: 1))
                        path.append(Product(name: "Second", price: 2))
                        path.append(Product(name: "Third", price: 3))
                    }
                    
                    Button("Go to Category -> Product") {
                        path.append(Category(name: "Electronics"))
                        path.append(Product(name: "Gadget", price: 99))
                    }
                }
                
                Section("Nested Navigation") {
                    NavigationLink("Go to List View") {
                        NestedListView()
                    }
                }
            }
            .navigationTitle("Navigation Tests")
            .navigationDestination(for: Product.self) { product in
                ProductDetailView(product: product)
            }
            .navigationDestination(for: Category.self) { category in
                CategoryView(category: category)
            }
        }
    }
}

// MARK: - Detail Views

struct DetailView: View {
    let title: String
    
    var body: some View {
        VStack {
            Text("This is \(title)")
                .font(.headline)
            Text("A basic detail view")
                .foregroundStyle(.secondary)
        }
        .navigationTitle(title)
    }
}

struct ProductDetailView: View {
    let product: Product
    
    var body: some View {
        VStack(spacing: 20) {
            Text(product.name)
                .font(.largeTitle)
            Text("$\(product.price)")
                .font(.title)
                .foregroundStyle(.green)
        }
        .navigationTitle(product.name)
    }
}

struct CategoryView: View {
    let category: Category
    
    var body: some View {
        List {
            Text("Category: \(category.name)")
            NavigationLink("View Sample Product", value: Product(name: "Sample", price: 42))
        }
        .navigationTitle(category.name)
    }
}

struct NestedListView: View {
    var body: some View {
        List {
            NavigationLink("Nested Item 1") {
                NestedDetailView(item: 1)
            }
            NavigationLink("Nested Item 2") {
                NestedDetailView(item: 2)
            }
            NavigationLink("Nested Item 3") {
                NestedDetailView(item: 3)
            }
        }
        .navigationTitle("Nested List")
    }
}

struct NestedDetailView: View {
    let item: Int
    
    var body: some View {
        Text("Nested Item \(item) Detail")
            .navigationTitle("Item \(item)")
    }
}

// MARK: - Sheet Tests

struct SheetTestView: View {
    @State private var showSheet = false
    @State private var showFullScreen = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Sheet Presentations") {
                    Button("Show Sheet") {
                        showSheet = true
                    }
                    
                    Button("Show Full Screen Cover") {
                        showFullScreen = true
                    }
                }
                
                Section("Sheet with Navigation") {
                    Button("Sheet with NavigationStack") {
                        showSheet = true
                    }
                }
            }
            .navigationTitle("Sheet Tests")
            .sheet(isPresented: $showSheet) {
                SheetContentView()
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenContentView(isPresented: $showFullScreen)
            }
        }
    }
}

struct SheetContentView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("This is a sheet!")
                    .font(.headline)
                
                NavigationLink("Navigate inside sheet") {
                    Text("Pushed inside sheet!")
                        .navigationTitle("Sheet Detail")
                }
                .padding()
            }
            .navigationTitle("Sheet View")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct FullScreenContentView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            Text("Full screen cover!")
                .navigationTitle("Full Screen")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { isPresented = false }
                    }
                }
        }
    }
}

// MARK: - Settings (No navigation title set!)

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Setting 1")
                Text("Setting 2")
                Text("Setting 3")
                
                NavigationLink("About") {
                    AboutView()
                }
            }
            // Intentionally NO navigationTitle here - let's see what we capture
        }
    }
}

struct AboutView: View {
    var body: some View {
        Text("SignalTestBed v1.0")
            .navigationTitle("About")
    }
}

// MARK: - Models

struct Product: Hashable {
    let name: String
    let price: Int
}

struct Category: Hashable {
    let name: String
}

// MARK: - Preview

#Preview {
    ContentView()
}
