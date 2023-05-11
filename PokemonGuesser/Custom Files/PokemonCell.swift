//
//  PokemonCell.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/10/23.
//

import UIKit

class PokemonCell: UICollectionViewCell {
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var pokemonNameLabel: UILabel!
    @IBOutlet weak var pokemonImageView: UIImageView!
    
    var onButtonTapped: (() -> Void)?
    
    @IBAction func buttonTapped(_ sender: Any) {
        onButtonTapped?()
    }
    
}
