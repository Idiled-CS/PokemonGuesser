//
//  DescriptionViewController.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/3/23.
//

import UIKit

class DescriptionViewController: UIViewController {
    
    @IBOutlet weak var pokeNameText: UITextField!
    var pokemonName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        
        pokeNameText.text = pokemonName!
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
