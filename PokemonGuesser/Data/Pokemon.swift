//
//  Pokemon.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/10/23.
//

import Foundation

struct Pokemon: Decodable {
    let id: Int
    let name: String
    let types: [TypeWrapper]
    let sprites: Sprite
    let species: Species
    
    struct TypeWrapper: Decodable {
        let type: PokemonType
    }
    
    struct PokemonType: Decodable {
        let name: String
    }
    
    struct Sprite: Decodable {
        let front_default: String?
    }
    
    struct Species: Decodable {
        let url: String?
    }
}

