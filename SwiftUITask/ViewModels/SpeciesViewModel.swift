//
//  SpeciesViewModel.swift
//  SwiftUITask
//
//  Created by AbiyaFeba on 28/05/25.
//


import Foundation
import Combine
import SwiftUI

// MARK: - Species View Model
final class SpeciesViewModel: ObservableObject {

    @Published var searchText = ""
    @Published private(set) var species: [Species] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    
    init(apiService: APIService = APIService()) {
        self.apiService = apiService
        setupBindings()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        #if DEBUG
        print("ViewModel received error: \(error)")
        #endif
        
        if let apiError = error as? APIError {
            errorMessage = apiError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchSpecies() {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchSpecies()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.handleError(error)
                }
            } receiveValue: { [weak self] speciesArray in
                guard let self = self else { return }
                #if DEBUG
                print("Received species: \(speciesArray.count)")
                #endif
                self.species = speciesArray
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    @available(iOS 15.0, *)
    func fetchSpeciesAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let speciesArray = try await apiService.fetchSpeciesAsync()
            species = speciesArray
            #if DEBUG
            print("Async received species: \(speciesArray.count)")
            #endif
        } catch {
            handleError(error)
        }
        
        isLoading = false
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
    
    // Helper method to get status code from description
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
    
    func filteredSpecies() -> [Species] {
        if searchText.isEmpty {
            return species
        }
        
        let lowercasedSearchText = searchText.lowercased()
        
        let possibleStatusCode = getStatusCode(from: lowercasedSearchText)
        
        return species.filter { species in
            if species.name.lowercased().contains(lowercasedSearchText) {
                return true
            }
            
            if species.scientificName.lowercased().contains(lowercasedSearchText) {
                return true
            }
            
            if species.group.lowercased().contains(lowercasedSearchText) {
                return true
            }
            
            if species.isoCode.lowercased().contains(lowercasedSearchText) {
                return true
            }
            
            if species.conservationStatus.lowercased().contains(lowercasedSearchText) {
                return true
            }
            
            let fullStatus = getStatusDescription(species.conservationStatus)
            if fullStatus.contains(lowercasedSearchText) {
                return true
            }
            
            if let statusCode = possibleStatusCode, species.conservationStatus.uppercased() == statusCode {
                return true
            }
            
            return false
        }
    }
}
