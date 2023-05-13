//
//  SuggestionCollectionViewCell.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/12/23.
//

import UIKit

class SuggestionCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var suggestionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Constraints
        suggestionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            suggestionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            suggestionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            suggestionLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            suggestionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
}
