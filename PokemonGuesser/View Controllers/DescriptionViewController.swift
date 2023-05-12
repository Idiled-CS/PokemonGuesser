//
//  DescriptionViewController.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/3/23.
//

import UIKit
import CoreData

// MARK: Struct for Species
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

// MARK: DescriptionViewController
class DescriptionViewController: UIViewController {
    
    // MARK: Outlet Connections
    @IBOutlet weak var pokemonTypeLabel: UILabel!
    @IBOutlet weak var pokeNameText: UITextField!
    @IBOutlet weak var pokemonImageView: UIImageView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var pokemonDescriptionLabel: UILabel!
    
    // MARK: Variables
    var pokemon: Pokemon?
    var pokemonEntity: PokemonEntity?
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
               
        updateFavoriteButton()

        if let pokemonEntity = pokemonEntity {
            setupViewWithPokemonEntity(pokemonEntity)
        } else if let pokemon = pokemon {
            setupViewWithPokemon(pokemon)
        }
    }


    // MARK: Set up views
    func setupViewWithPokemonEntity(_ pokemonEntity: PokemonEntity) {
        pokeNameText.text = pokemonEntity.name?.capitalized
        pokemonTypeLabel.text = pokemonEntity.types?.components(separatedBy: ",").first?.capitalized ?? "Unknown"

        if let urlString = pokemonEntity.front_default, let url = URL(string: urlString) {
            fetchImage(from: url) { [weak self] image in
                self?.pokemonImageView.image = image
            }
        }

        if let speciesURLString = pokemonEntity.speciesUrl, let speciesURL = URL(string: speciesURLString) {
            fetchSpeciesData(from: speciesURL) { [weak self] species in
                let englishFlavorText = species?.flavorTextEntries.first(where: { $0.language.name == "en" })?.flavorText
                self?.pokemonDescriptionLabel.text = englishFlavorText
            }
        }
    }
    

    func setupViewWithPokemon(_ pokemon: Pokemon) {
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
    
    // MARK: Favorite actions
    @IBAction func favoriteButtonTapped(_ sender: Any) {
        if let pokemon = self.pokemon {
               if isFavorited(pokemon: pokemon) {
                   removePokemonFromFavorites()
               } else {
                   savePokemonToCoreData(pokemon: pokemon)
               }
           } else if let pokemonEntity = self.pokemonEntity {
               if isFavorited(pokemonEntity: pokemonEntity) {
                   removePokemonEntityFromFavorites(pokemonEntity: pokemonEntity)
               }
           }
        updateFavoriteButton()
    }
    
    //  Remove when it is a Pokemon Struct
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

        NotificationCenter.default.post(name: NSNotification.Name("PokemonUnfavorited"), object: nil)
    }

    // Remove when it is a PokemonEntity, also puts it in a Pokemon Struct for refavorite cases
    func removePokemonEntityFromFavorites(pokemonEntity: PokemonEntity) {
        // Transform the PokemonEntity into a Pokemon struct before it's deleted
        let pokemon = Pokemon(id: Int(pokemonEntity.id),
                              name: pokemonEntity.name ?? "",
                              types: pokemonEntity.types?.components(separatedBy: ",").map { Pokemon.TypeWrapper(type: Pokemon.PokemonType(name: $0)) } ?? [],
                              sprites: Pokemon.Sprite(front_default: pokemonEntity.front_default),
                              species: Pokemon.Species(url: pokemonEntity.speciesUrl))

        // Assign it to the pokemon property
        self.pokemon = pokemon

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PokemonEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %d", pokemonEntity.id)

        do {
            let result = try context.fetch(fetchRequest)
            for object in result {
                context.delete(object)
            }
            try context.save()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        self.pokemonEntity = nil
        NotificationCenter.default.post(name: NSNotification.Name("PokemonUnfavorited"), object: nil)
    }


    
    func isFavorited(pokemon: Pokemon) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PokemonEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %d", pokemon.id)

        do {
            let result = try context.fetch(fetchRequest)
            return !result.isEmpty
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        return false
    }

    func isFavorited(pokemonEntity: PokemonEntity) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PokemonEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %d", pokemonEntity.id)

        do {
            let result = try context.fetch(fetchRequest)
            return !result.isEmpty
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        return false
    }
    
    // MARK: Updates Favorite Button
    func updateFavoriteButton() {
        if let pokemon = self.pokemon {
            if isFavorited(pokemon: pokemon) {
                favoriteButton.tintColor = .yellow
            } else {
                favoriteButton.tintColor = .gray
                }
            } else if let pokemonEntity = self.pokemonEntity {
                if isFavorited(pokemonEntity: pokemonEntity) {
                favoriteButton.tintColor = .yellow
        } else {
            favoriteButton.tintColor = .gray
            }
        }
    }

    // MARK: Saving to Core Data
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
