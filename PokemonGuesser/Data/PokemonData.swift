//
//  PokemonData.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/3/23.
//

import Foundation

struct PokemonData: Codable {
    let name: String
    let sprites: Sprites
    
    private enum CodingKeys: String, CodingKey {
        case name
        case sprites
    }
}

struct Sprites: Codable {
    let frontDefault: String?
    
    private enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}
