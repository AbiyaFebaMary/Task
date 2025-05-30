//
//  SpeciesViewModel.swift
//  SwiftUITask
//
//  Created by AbiyaFeba on 28/05/25.
//

import Foundation
import Combine
import SwiftData
import SwiftUI

@MainActor
class SpeciesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var filteredSpecies: [Species] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var currentPage: Int = 1
    @Published var hasMorePages: Bool = true
    
    // MARK: - Private Properties
    private var apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?
    private var modelContext: ModelContext?
    private var speciesDescriptor: FetchDescriptor<Species>?
    
    // MARK: - Initialization
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        setupSearchSubscription()
        loadLocalData()
        fetchSpecies()
    }
    
    // MARK: - Public Methods
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadLocalData()
    }
    
    func loadNextPage() {
        if !isLoading && hasMorePages {
            currentPage += 1
            fetchSpecies()
        }
    }
    
    func refresh() {
        currentPage = 1
        hasMorePages = true
        fetchSpecies(forceRefresh: true)
    }
    

    
    func fetchSpecies(forceRefresh: Bool = false) {
        if isLoading && !forceRefresh { return }
        
        isLoading = true
        errorMessage = nil
        
        apiService.fetchSpecies(page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] speciesResponses in
                guard let self = self else { return }
                

                if speciesResponses.isEmpty {
                    self.hasMorePages = false
                    return
                }
                

                self.saveToSwiftData(speciesResponses: speciesResponses, page: self.currentPage)
                

                self.loadLocalData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func setupSearchSubscription() {
        searchCancellable = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applySearchFilter()
            }
    }
    
    private func loadLocalData() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Species>(sortBy: [SortDescriptor(\Species.commonName)])
            let localSpecies = try modelContext.fetch(descriptor)
            

            if currentPage == 1 && !localSpecies.isEmpty {

                if let maxPage = localSpecies.map({ $0.page }).max() {
                    currentPage = maxPage
                }
            }
            
            applySearchFilter(localSpecies: localSpecies)
        } catch {
            print("Error fetching from SwiftData: \(error)")
            errorMessage = "Failed to load saved data"
        }
    }
    
    private func saveToSwiftData(speciesResponses: [APISpeciesResponse], page: Int) {
        guard let modelContext = modelContext else { return }
        
        for response in speciesResponses {

            let descriptor = FetchDescriptor<Species>(predicate: #Predicate { $0.id == response.id })
            
            do {
                let existingSpecies = try modelContext.fetch(descriptor)
                
                if let existing = existingSpecies.first {

                    existing.commonName = response.commonName
                    existing.scientificName = response.scientificName
                    existing.group = response.group
                    existing.conservationStatus = response.conservationStatus
                    existing.isoCode = response.isoCode
                    existing.timestamp = Date()
                    existing.page = page
                } else {

                    let newSpecies = Species(from: response, page: page)
                    modelContext.insert(newSpecies)
                }
            } catch {
                print("Error saving species to SwiftData: \(error)")
            }
        }
        

        do {
            try modelContext.save()
        } catch {
            print("Error saving to SwiftData: \(error)")
        }
    }
    
    private func applySearchFilter(localSpecies: [Species]? = nil) {
        let species = localSpecies ?? (try? modelContext?.fetch(FetchDescriptor<Species>()) ?? [])
        
        if searchText.isEmpty {
            filteredSpecies = species ?? []
        } else {
            filteredSpecies = (species ?? []).filter { species in
                species.commonName.lowercased().contains(searchText.lowercased()) ||
                species.scientificName.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        print("Error fetching species: \(error)")
        

        loadLocalData()
    }
    
    private func getStatusDescription(_ code: String) -> String {
        switch code.uppercased() {
        case "CR": return "critically endangered"
        case "EN": return "endangered"
        case "VU": return "vulnerable"
        case "NT": return "near threatened"
        case "LC": return "least concern"
        case "EX": return "extinct"
        case "EW": return "extinct in the wild"
        default: return code.lowercased()
        }
    }
    

    private func getStatusCode(from description: String) -> String? {
        let lowercased = description.lowercased()
        if lowercased.contains("critically") && lowercased.contains("endangered") {
            return "CR"
        } else if lowercased.contains("endangered") {
            return "EN"
        } else if lowercased.contains("vulnerable") {
            return "VU"
        } else if lowercased.contains("near") && lowercased.contains("threatened") {
            return "NT"
        } else if lowercased.contains("least") && lowercased.contains("concern") {
            return "LC"
        } else if lowercased.contains("extinct") && lowercased.contains("wild") {
            return "EW"
        } else if lowercased.contains("extinct") {
            return "EX"
        }
        return nil
    }
}
