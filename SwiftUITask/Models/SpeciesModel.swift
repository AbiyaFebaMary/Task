//
//  SpeciesModel.swift
//  SwiftUITask
//
//  Created by AbiyaFeba on 28/05/25.
//

import Foundation

struct Species: Codable, Identifiable {
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        commonName = try container.decode(String.self, forKey: .commonName)
        scientificName = try container.decode(String.self, forKey: .scientificName)
        group = try container.decode(String.self, forKey: .group)
        conservationStatus = try container.decode(String.self, forKey: .conservationStatus)
        isoCode = try container.decode(String.self, forKey: .isoCode)
    }
}

struct SpeciesResponse: Codable {
    let data: [Species]
    let meta: Meta?
    
    // Add a custom initializer to create a response with just species data
    init(data: [Species], meta: Meta?) {
        self.data = data
        self.meta = meta
    }
    
    // Add a custom initializer to handle different response structures
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode data as an array of Species
        do {
            data = try container.decode([Species].self, forKey: .data)
        } catch {
            // If that fails, maybe the response is just an array of Species without a data wrapper
            do {
                // Try to decode the entire response as an array of Species directly
                let species = try decoder.singleValueContainer().decode([Species].self)
                data = species
                meta = nil
                return
            } catch {
                // Re-throw the original error if both approaches fail
                throw error
            }
        }
        
        // Meta might be optional in some responses
        meta = try container.decodeIfPresent(Meta.self, forKey: .meta)
    }
    
    enum CodingKeys: String, CodingKey {
        case data
        case meta
    }
}

struct Meta: Codable {
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
    
    // Add init with default values for optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        perPage = try container.decode(Int.self, forKey: .perPage)
        currentPage = try container.decode(Int.self, forKey: .currentPage)
        lastPage = try container.decode(Int.self, forKey: .lastPage)
    }
}
