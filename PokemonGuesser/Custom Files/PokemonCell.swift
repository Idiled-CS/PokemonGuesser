//
//  PokemonCell.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/10/23.
//

import UIKit

class PokemonCell: UICollectionViewCell {
    
    @IBOutlet weak var pokemonNameLabel: UILabel!
    @IBOutlet weak var pokemonImageView: UIImageView!
    
    private var pokemonButton = UIButton()
    private var pokemonEntity: PokemonEntity?
    private var completion: ((PokemonEntity) -> Void)?
        
    override func awakeFromNib() {
        super.awakeFromNib()
        setupButton()
    }

    func configureCell(pokemonEntity: PokemonEntity, completion: @escaping (PokemonEntity) -> Void) {
        self.pokemonEntity = pokemonEntity
        self.completion = completion
        setupButton()
    }

    private func setupButton() {
        pokemonButton.removeFromSuperview()
        pokemonButton = UIButton(frame: contentView.bounds)
        pokemonButton.backgroundColor = .clear
        pokemonButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        contentView.addSubview(pokemonButton)
        contentView.bringSubviewToFront(pokemonButton)
    }

    @objc private func buttonTapped() {
        if let pokemonEntity = pokemonEntity {
                completion?(pokemonEntity)
        }
    }
}
