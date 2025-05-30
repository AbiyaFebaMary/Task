//
//  ContentView.swift
//  SwiftUITask
//
//  Created by AbiyaFeba on 28/05/25.
//

import SwiftUI
import Combine
import UIKit
import SwiftData

// MARK: - Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SpeciesViewModel()
    @State private var showingFilterSheet = false
    @State private var selectedFilter: ConservationStatus? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {

                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color(red: 0.9, green: 0.9, blue: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchBarSection
                    contentSection
                }
            }
            .navigationTitle("Wildlife Species")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingFilterSheet = true }) {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { 
                        withAnimation {
                            viewModel.refresh() 
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                filterView
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
    
    // MARK: - UI Components
    private var searchBarSection: some View {
        SearchBar(text: $viewModel.searchText)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(Material.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .zIndex(1)
    }
    
    private var contentSection: some View {
        ZStack {

            Color.clear
                .contentShape(Rectangle())
                .edgesIgnoringSafeArea(.bottom)
                .onTapGesture { hideKeyboard() }
            
            if viewModel.filteredSpecies.isEmpty && !viewModel.isLoading {
                emptyResultsView
                    .transition(.opacity)
            } else {
                speciesListView
                    .transition(.opacity)
            }
            
            if let errorMessage = viewModel.errorMessage, !viewModel.filteredSpecies.isEmpty {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.85))
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3), value: viewModel.errorMessage)
                .zIndex(2)
            }
            
            if viewModel.isLoading && viewModel.filteredSpecies.isEmpty {
                loadingView
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: viewModel.filteredSpecies.isEmpty)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Discovering Species...")
                .font(.headline)
                .foregroundColor(.primary.opacity(0.8))
        }
        .frame(width: 200, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 24) {
            // Animated icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                
                Image(systemName: !viewModel.searchText.isEmpty ? "magnifyingglass" : 
                      (viewModel.errorMessage != nil ? "exclamationmark.triangle" : "leaf"))
                    .font(.system(size: 45, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 10)
            
            if !viewModel.searchText.isEmpty {
                Text("No species found matching '\(viewModel.searchText)'")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                
                Text("Try adjusting your search criteria or check for typos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    withAnimation {
                        viewModel.searchText = ""
                    }
                }) {
                    Label("Clear Search", systemImage: "xmark.circle")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                
            } else if viewModel.errorMessage != nil {
                Text("Unable to load species")
                    .font(.title3.bold())
                
                Text(viewModel.errorMessage ?? "Unknown error")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    withAnimation {
                        viewModel.refresh()
                    }
                }) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                
            } else {
                Text("No species available")
                    .font(.title3.bold())
                
                Text("Pull down to refresh or tap the refresh button")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    withAnimation {
                        viewModel.refresh()
                    }
                }) {
                    Label("Refresh Now", systemImage: "arrow.clockwise")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var speciesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.filteredSpecies.enumerated()), id: \.element.id) { index, species in
                    SpeciesRow(species: species)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Material.regularMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, index == 0 ? 8 : 0)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .onAppear {
                            // Load more data when reaching the end
                            if species.id == viewModel.filteredSpecies.last?.id && viewModel.hasMorePages {
                                viewModel.loadNextPage()
                            }
                        }
                }
                
                if viewModel.isLoading && !viewModel.filteredSpecies.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.blue)
                            .scaleEffect(1.2)
                            .padding()
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
                
                if !viewModel.hasMorePages && !viewModel.filteredSpecies.isEmpty {
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.horizontal, 60)
                        
                        Text("End of results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 16)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.filteredSpecies.count)
        }
        .refreshable {
            viewModel.refresh()
        }
    }
    
    private var filterView: some View {
        NavigationStack {
            List {
                Section(header: Text("Conservation Status")) {
                    Button("All") {
                        selectedFilter = nil
                        showingFilterSheet = false
                    }
                    .foregroundColor(selectedFilter == nil ? .blue : .primary)
                    
                    ForEach(ConservationStatus.allCases, id: \.self) { status in
                        Button {
                            selectedFilter = status
                            showingFilterSheet = false
                        } label: {
                            HStack {
                                Text(status.rawValue)
                                Spacer()
                                Text(status.description)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(selectedFilter == status ? .blue : .primary)
                    }
                }
            }
            .navigationTitle("Filter Species")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
                .autocorrectionDisabled(true)
                .onTapGesture { 
                    isEditing = true 
                    showingSearchTips = true
                }
            
            if !text.isEmpty {
                clearButton
            }
            
            if isEditing {
                cancelButton
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray6)))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var clearButton: some View {
        Button(action: { text = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
                .padding(4)
        }
    }
    
    private var cancelButton: some View {
        Button(action: {
            text = ""
            isEditing = false
            showingSearchTips = false
            hideKeyboard()
        }) {
            Text("Cancel")
                .foregroundColor(.blue)
                .padding(.horizontal, 4)
        }
        .transition(.move(edge: .trailing))
        .animation(.default, value: isEditing)
    }
    
    private var searchTips: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Search Tips:")
                .font(.caption.bold())
            Text("• Search by name or scientific name")
                .font(.caption)
            Text("• Search by group (e.g., 'MAMMALIA')")
                .font(.caption)
            Text("• Search by conservation status (e.g., 'CR', 'EN')")
                .font(.caption)
            
            Button("Hide Tips") {
                showingSearchTips = false
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray6)))
        .padding(.top, 4)
        .transition(.opacity)
        .animation(.easeInOut, value: showingSearchTips)
    }
}


// MARK: - Conservation Status Enum
enum ConservationStatus: String, CaseIterable {
    case CR, EN, VU, NT, LC, EX, EW, DD, NE
    
    var description: String {
        switch self {
        case .CR: return "Critically Endangered"
        case .EN: return "Endangered"
        case .VU: return "Vulnerable"
        case .NT: return "Near Threatened"
        case .LC: return "Least Concern"
        case .EX: return "Extinct"
        case .EW: return "Extinct in the Wild"
        case .DD: return "Data Deficient"
        case .NE: return "Not Evaluated"
        }
    }
    
    var color: Color {
        switch self {
        case .CR: return Color(red: 0.85, green: 0.1, blue: 0.1)
        case .EN: return Color(red: 0.95, green: 0.5, blue: 0.1)
        case .VU: return Color(red: 0.95, green: 0.85, blue: 0.1)
        case .NT: return Color(red: 0.1, green: 0.6, blue: 0.9)
        case .LC: return Color(red: 0.1, green: 0.75, blue: 0.45)
        case .EX, .EW: return Color(red: 0.6, green: 0.1, blue: 0.6)
        case .DD, .NE: return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }
}

// MARK: - Species Row Component
struct SpeciesRow: View {
    let species: Species
    @State private var showDetails = false
    @State private var heartbeat = false
    
    private var statusColor: Color {
        if let status = ConservationStatus(rawValue: species.conservationStatus) {
            return status.color
        }
        return .gray
    }
    
    private var statusDescription: String {
        if let status = ConservationStatus(rawValue: species.conservationStatus) {
            return status.description
        }
        return species.conservationStatus
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Left side with icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: getIconForGroup(species.group))
                        .font(.system(size: 22))
                        .foregroundColor(statusColor)
                        .scaleEffect(heartbeat ? 1.1 : 1.0)
                        .animation(
                            heartbeat ? 
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true) : 
                                Animation.default,
                            value: heartbeat
                        )
                }
                .padding(.top, 4)
                
                // Middle with species info
                speciesInfoSection
                
                Spacer()
                
                // Right side with conservation status
                conservationStatusSection
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showDetails.toggle()
                }
            }
            .onAppear {
                if species.conservationStatus == "CR" || species.conservationStatus == "EN" {
                    heartbeat = true
                }
            }
            
            if showDetails {
                detailsSection
            }
        }
    }
    
    private func getIconForGroup(_ group: String) -> String {
        switch group.lowercased() {
        case "mammalia":
            return "hare.fill"
        case "aves":
            return "bird.fill"
        case "reptilia":
            return "tortoise.fill"
        case "amphibia":
            return "lizard.fill"
        case "pisces", "actinopterygii", "chondrichthyes":
            return "fish.fill"
        case "insecta":
            return "ant.fill"
        case "plantae", "flora":
            return "leaf.fill"
        default:
            return "pawprint.fill"
        }
    }
    
    private var speciesInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(species.commonName)
                .font(.headline)
                .lineLimit(1)
            
            Text(species.scientificName)
                .font(.subheadline)
                .italic()
                .foregroundColor(.gray)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                infoTag(text: species.group.capitalized, icon: "leaf.fill")
                infoTag(text: species.isoCode, icon: "globe")
            }
        }
    }
    
    private var conservationStatusSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(species.conservationStatus)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(statusColor)
                        .shadow(color: statusColor.opacity(0.4), radius: 2, x: 0, y: 1)
                )
            
            Text(statusDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.top, 8)
            
            // Conservation status card
            HStack(spacing: 16) {
                // Status indicator
                ZStack {
                    Circle()
                        .stroke(statusColor, lineWidth: 2)
                        .frame(width: 60, height: 60)
                    
                    VStack(spacing: 2) {
                        Text(species.conservationStatus)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(statusColor)
                        
                        if species.conservationStatus == "CR" || species.conservationStatus == "EN" {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(statusColor)
                                .font(.system(size: 12))
                        }
                    }
                }
                
                // Status description
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusDescription)
                        .font(.headline)
                        .foregroundColor(statusColor)
                    
                    Text(getConservationMessage(species.conservationStatus))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.1))
            )
            .padding(.horizontal, 12)
            
            // Species details
            VStack(alignment: .leading, spacing: 8) {
                detailRow(title: "Common Name", value: species.commonName, icon: "text.book.closed")
                detailRow(title: "Scientific Name", value: species.scientificName, icon: "doc.text.magnifyingglass")
                detailRow(title: "Group", value: species.group.capitalized, icon: getIconForGroup(species.group))
                detailRow(title: "ISO Code", value: species.isoCode, icon: "globe")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Close button
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showDetails = false
                    }
                } label: {
                    Label("Close", systemImage: "chevron.up")
                        .font(.footnote.bold())
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 4)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
        ))
    }
    
    private func getConservationMessage(_ status: String) -> String {
        switch status {
        case "CR":
            return "Facing an extremely high risk of extinction in the wild."
        case "EN":
            return "Facing a very high risk of extinction in the wild."
        case "VU":
            return "Facing a high risk of extinction in the wild."
        case "NT":
            return "Likely to qualify for a threatened category in the near future."
        case "LC":
            return "Widespread and abundant, at low risk of extinction."
        case "EX":
            return "No known living individuals remaining."
        case "EW":
            return "Survives only in captivity or as a naturalized population."
        default:
            return "Conservation status information not available."
        }
    }
    
    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
    
    private func infoTag(text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    ContentView()
}
