//
//  SpeciesModel.swift
//  SwiftUITask
//
//  Created by AbiyaFeba on 28/05/25.
//

import Foundation
import SwiftData

// MARK: - API Response Models


struct APISpeciesResponse: Codable, Identifiable {
    let id: Int
    let commonName: String
    let scientificName: String
    let group: String
    let conservationStatus: String
    let isoCode: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case commonName = "common_name"
        case scientificName = "scientific_name"
        case group
        case conservationStatus = "conservation_status"
        case isoCode = "iso_code"
    }
    
    var name: String {
        return commonName
    }
}

// MARK: - SwiftData Models


@Model
final class Species {
    @Attribute(.unique) var id: Int
    var commonName: String
    var scientificName: String
    var group: String
    var conservationStatus: String
    var isoCode: String
    var timestamp: Date
    var page: Int
    
    var name: String {
        return commonName
    }
    
    init(id: Int, commonName: String, scientificName: String, group: String, conservationStatus: String, isoCode: String, page: Int = 1) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.group = group
        self.conservationStatus = conservationStatus
        self.isoCode = isoCode
        self.timestamp = Date()
        self.page = page
    }
    

    convenience init(from response: APISpeciesResponse, page: Int = 1) {
        self.init(
            id: response.id,
            commonName: response.commonName,
            scientificName: response.scientificName,
            group: response.group,
            conservationStatus: response.conservationStatus,
            isoCode: response.isoCode,
            page: page
        )
    }
}

// MARK: - Helper Extensions


extension Array where Element == APISpeciesResponse {
    func toSwiftDataModels(page: Int = 1) -> [Species] {
        return self.map { Species(from: $0, page: page) }
    }
}


struct PaginationMeta: Codable {
    let total: Int
    let perPage: Int
    let currentPage: Int
    let lastPage: Int
    
    enum CodingKeys: String, CodingKey {
        case total
        case perPage = "per_page"
        case currentPage = "current_page"
        case lastPage = "last_page"
    }
}
