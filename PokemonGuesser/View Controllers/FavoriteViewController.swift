//
//  FavoriteViewController.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/10/23.
//

import UIKit
import CoreData

class FavoriteViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    

    @IBOutlet weak var collectionView: UICollectionView!
    
    var favoritedPokemon: [PokemonEntity] = []
       
    // MARK: Overridding Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchFavoritedPokemon()
           
        NotificationCenter.default.addObserver(self, selector: #selector(PokemonUnfavorited), name: NSNotification.Name("PokemonUnfavorited"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchFavoritedPokemon()
        collectionView.reloadData()
    }
    
    // Segue for showDescription from favorite Menu
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFavoriteDescription",
            let destinationVC = segue.destination as? DescriptionViewController,
            let pokemonEntity = sender as? PokemonEntity {
                destinationVC.pokemonEntity = pokemonEntity
        }
    }
    // Updates when a pokemon is unfavorited
    @objc func PokemonUnfavorited(notification: NSNotification) {
        fetchFavoritedPokemon()
        collectionView.reloadData()
    }
       
    // Fetching Favorite Pokemons from Entity
    func fetchFavoritedPokemon() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<PokemonEntity>(entityName: "PokemonEntity")

        do {
           favoritedPokemon = try context.fetch(fetchRequest)
        } catch let error as NSError {
           print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       return favoritedPokemon.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PokemonCell", for: indexPath) as! PokemonCell

        let pokemonEntity = favoritedPokemon[indexPath.item]
        cell.pokemonNameLabel.text = pokemonEntity.name?.uppercased()
        cell.configureCell(pokemonEntity: pokemonEntity) { [weak self] pokemonEntity in
            self?.performSegue(withIdentifier: "showFavoriteDescription", sender: pokemonEntity)
        }
        
        if let urlString = pokemonEntity.front_default, let url = URL(string: urlString) {
            UIImage.fetchFrom(url: url) { image in
                DispatchQueue.main.async {
                    cell.pokemonImageView.image = image
                }
            }
        }

        return cell
    }
    
}
