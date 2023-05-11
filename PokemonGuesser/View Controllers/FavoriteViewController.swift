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
       
    
       override func viewDidLoad() {
           super.viewDidLoad()
           collectionView.delegate = self
           collectionView.dataSource = self
           fetchFavoritedPokemon()
       }
    
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            fetchFavoritedPokemon()
            collectionView.reloadData()
        }
       
       
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
           
           let pokemon = favoritedPokemon[indexPath.item]
           cell.pokemonNameLabel.text = pokemon.name
           if let urlString = pokemon.front_default, let url = URL(string: urlString) {
               fetchImage(from: url) { image in
                   DispatchQueue.main.async {
                       cell.pokemonImageView.image = image
                   }
               }
           }
           
           return cell
       }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            performSegue(withIdentifier: "showDescription", sender: indexPath)
        }


        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showDescription",
               let destinationVC = segue.destination as? DescriptionViewController,
               let indexPath = sender as? IndexPath {
                let pokemonEntity = favoritedPokemon[indexPath.row]
                destinationVC.pokemonEntity = pokemonEntity
            }
        }
    

       func fetchImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
           URLSession.shared.dataTask(with: url) { data, response, error in
               guard let data = data, let image = UIImage(data: data) else {
                   print("Error: \(error?.localizedDescription ?? "Unknown error")")
                   return
               }
               completion(image)
           }.resume()
       }
   }
