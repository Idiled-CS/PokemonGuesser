//
//  DescriptionViewController.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/3/23.
//

import UIKit
import CoreData

struct Species: Decodable {
    let flavorTextEntries: [FlavorTextEntry]

    struct FlavorTextEntry: Decodable {
        let flavorText: String
        let language: Language

        enum CodingKeys: String, CodingKey {
            case flavorText = "flavor_text"
            case language
        }
    }

    struct Language: Decodable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case flavorTextEntries = "flavor_text_entries"
    }
}

class DescriptionViewController: UIViewController {
    
    @IBOutlet weak var pokemonTypeLabel: UILabel!
    @IBOutlet weak var pokeNameText: UITextField!
    @IBOutlet weak var pokemonImageView: UIImageView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var pokemonDescriptionLabel: UILabel!
    
    var pokemon: Pokemon?

        override func viewDidLoad() {
            super.viewDidLoad()
            
            updateFavoriteButton()
            
            guard let pokemon = pokemon else { return }
            
            pokeNameText.text = pokemon.name.capitalized
            pokemonTypeLabel.text = pokemon.types.first?.type.name.capitalized ?? "Unknown"
            
            if let urlString = pokemon.sprites.front_default, let url = URL(string: urlString) {
                fetchImage(from: url) { [weak self] image in
                    self?.pokemonImageView.image = image
                }
            }
            
            if let speciesURLString = pokemon.species.url, let speciesURL = URL(string: speciesURLString) {
                fetchSpeciesData(from: speciesURL) { [weak self] species in
                    let englishFlavorText = species?.flavorTextEntries.first(where: { $0.language.name == "en" })?.flavorText
                    self?.pokemonDescriptionLabel.text = englishFlavorText
                }
            }
        }
    
    
        func fetchImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, let image = UIImage(data: data) else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                DispatchQueue.main.async {
                    completion(image)
                }
            }.resume()
        }
        @IBAction func favoriteButtonTapped(_ sender: Any) {
            if isFavorited() {
                    removePokemonFromFavorites()
                } else {
                    savePokemonToCoreData(pokemon: pokemon!)
                }
                updateFavoriteButton()
        }
    
        func removePokemonFromFavorites() {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PokemonEntity")
            fetchRequest.predicate = NSPredicate(format: "id = %d", pokemon?.id ?? 0)
            
            do {
                let result = try context.fetch(fetchRequest)
                for object in result {
                    context.delete(object)
                }
                try context.save()
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

    
        func fetchSpeciesData(from url: URL, completion: @escaping (Species?) -> Void) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                do {
                    let species = try JSONDecoder().decode(Species.self, from: data)
                    DispatchQueue.main.async {
                        completion(species)
                    }
                } catch let error {
                    print("Error decoding Species: \(error)")
                }
            }.resume()
        }
    
        func updateFavoriteButton() {
            if isFavorited() {
                favoriteButton.tintColor = .yellow
            } else {
                favoriteButton.tintColor = .gray
            }
        }
        
        func isFavorited() -> Bool {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PokemonEntity")
            fetchRequest.predicate = NSPredicate(format: "id = %d", pokemon?.id ?? 0)
            
            do {
                let result = try context.fetch(fetchRequest)
                return !result.isEmpty
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
            
            return false
        }

    
        func savePokemonToCoreData(pokemon: Pokemon) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            
            // Create a new PokemonEntity object
            let pokemonEntity = PokemonEntity(context: context)
            
            // Assign properties from the Pokemon struct to the PokemonEntity object
            pokemonEntity.id = Int64(pokemon.id)
            pokemonEntity.name = pokemon.name
            pokemonEntity.front_default = pokemon.sprites.front_default
            pokemonEntity.speciesUrl = pokemon.species.url
            
            // Convert the types array to a comma-separated string
            let typesString = pokemon.types.map { $0.type.name }.joined(separator: ",")
            pokemonEntity.types = typesString
            
            // Save the context
            do {
                try context.save()
            } catch {
                print("Failed saving")
            }
        }

    }
