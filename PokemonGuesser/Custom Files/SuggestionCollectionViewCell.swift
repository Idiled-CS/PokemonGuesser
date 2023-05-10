//
//  SuggestionCollectionViewCell.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/3/23.
//

import UIKit

class SuggestionCollectionViewCell: UICollectionViewCell {
    
    var suggestionLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCell()
    }
    
    func setupCell() {
        suggestionLabel = UILabel(frame: contentView.bounds)
        contentView.addSubview(suggestionLabel)
        
        layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        layer.borderWidth = 1
        
        let topLineView = UIView(frame: CGRect(x: 0, y: 0, width: contentView.bounds.width, height: 1))
        topLineView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        contentView.addSubview(topLineView)
    }
}
