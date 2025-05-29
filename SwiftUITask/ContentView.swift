//
//  ContentView.swift
//  SwiftUITask
//
//  Created by AbiyaFeba on 28/05/25.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SpeciesViewModel()
        var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBarSection
                contentSection
            }
            .navigationTitle("Species")
            .onAppear(perform: loadData)
        }
    }
    
    // MARK: - UI Components
    private var searchBarSection: some View {
        SearchBar(text: $viewModel.searchText)
            .padding()
            .background(Color.white)
            .zIndex(1)
    }
    
    private var contentSection: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.bottom)
                .contentShape(Rectangle())
                .onTapGesture { hideKeyboard() }
            
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if viewModel.filteredSpecies().isEmpty {
                    emptyResultsView
                } else {
                    speciesListView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadingView: some View {
        ProgressView("Loading species...")
            .progressViewStyle(CircularProgressViewStyle())
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text("Error loading species")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(message)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: loadData)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
    
    private var emptyResultsView: some View {
        VStack {
            Text("No species found")
                .font(.headline)
            Text("Try adjusting your search criteria")
                .foregroundColor(.secondary)
        }
    }
    
    private var speciesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredSpecies()) { species in
                    SpeciesRow(species: species)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical)
        }
    }
    
    
    private func loadData() {
        if #available(iOS 15.0, *) {
            Task {
                await viewModel.fetchSpeciesAsync()
            }
        } else {
            viewModel.fetchSpecies()
        }
    }
}

// MARK: - Search Bar Component

struct SearchBar: View {
    
    @Binding var text: String
    @State private var showingSearchTips = false
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 4) {
            searchField
            
            if showingSearchTips {
                searchTips
            }
        }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search species...", text: $text)
                .onTapGesture { isEditing = true }
            
            if !text.isEmpty {
                clearButton
            }
            
            if isEditing {
                cancelButton
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var clearButton: some View {
        Button(action: { text = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
        }
    }
    
    private var cancelButton: some View {
        Button(action: {
            text = ""
            isEditing = false
            hideKeyboard()
        }) {
            Text("Cancel")
                .foregroundColor(.blue)
        }
        .transition(.move(edge: .trailing))
        .animation(.default, value: isEditing)
    }
    
    private var searchTips: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Search Tips:")
                .font(.caption.bold())
            Text("• Search by name or scientific name")
                .font(.caption)
            Text("• Search by group (e.g., 'MAMMALIA')")
                .font(.caption)
            Text("• Search by conservation status:")
                .font(.caption)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .transition(.opacity)
        .animation(.easeInOut, value: showingSearchTips)
    }
}


// MARK: - Species Row Component
struct SpeciesRow: View {
    let species: Species
    
    private var statusColor: Color {
        switch species.conservationStatus {
        case "CR": return .red
        case "EN": return .orange
        case "VU": return .yellow
        case "NT": return .blue
        case "LC": return .green
        case "EX", "EW": return .purple
        default: return .gray
        }
    }
    
    private var statusDescription: String {
        switch species.conservationStatus {
        case "CR": return "Critically Endangered"
        case "EN": return "Endangered"
        case "VU": return "Vulnerable"
        case "NT": return "Near Threatened"
        case "LC": return "Least Concern"
        case "EX": return "Extinct"
        case "EW": return "Extinct in the Wild"
        default: return species.conservationStatus
        }
    }
    
    var body: some View {
        HStack {
            speciesInfoSection
            Spacer()
            conservationStatusSection
        }
    }
    
    private var speciesInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(species.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(species.scientificName)
                .font(.subheadline)
                .italic()
                .foregroundColor(.gray)
                .lineLimit(1)
            
            HStack {
                infoTag(text: species.group.capitalized)
                infoTag(text: species.isoCode)
            }
        }
    }
    
    /// Conservation status section (right side)
    private var conservationStatusSection: some View {
        VStack(alignment: .trailing) {
            Text(species.conservationStatus)
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor)
                .cornerRadius(4)
            
            Text(statusDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func infoTag(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(.systemGray6))
            .cornerRadius(4)
    }
}

#Preview {
    ContentView()
}
