//
//  GaneViewController.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/3/23.
//

import UIKit

class GameViewController: UIViewController, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var guessTextField: UITextField!
    @IBOutlet weak var randPokemonImg: UIImageView!
    @IBOutlet weak var guessButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pokemonName: String!
    var suggestions: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        guessTextField.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SuggestionCollectionViewCell.self, forCellWithReuseIdentifier: "suggestionCell")

        //Adding scroll wheel to suggestions
        collectionView.isScrollEnabled = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: 200 * 3) // Limit the height to show 3 suggestions at once
        ])
        
        // Suggestion box layout
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: collectionView.bounds.width, height: 40) // Set the height of each suggestion box
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layout.minimumLineSpacing = 0 // Remove line spacing
        layout.minimumInteritemSpacing = 0 // Remove item spacing
        layout.scrollDirection = .vertical
        collectionView.collectionViewLayout = layout



        let numberOfRows = 3
        let rowHeight: CGFloat = 40
        let totalSpacing: CGFloat = layout.minimumLineSpacing * CGFloat(numberOfRows - 1) + layout.sectionInset.top + layout.sectionInset.bottom
        let collectionViewHeight = CGFloat(numberOfRows) * rowHeight + totalSpacing
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: collectionViewHeight)
        ])
        
        // Calls FetchRandomPokemon and loads in a random Pokemon Image
        fetchRandomPokemon { result in
            switch result {
                case .success(let pokemonData):
                    if let spriteURLString = pokemonData.sprites.frontDefault, let spriteURL = URL(string: spriteURLString) {
                        // Load the image from the sprite URL
                        URLSession.shared.dataTask(with: spriteURL) { data, response, error in
                            if let data = data, let image = UIImage(data: data) {
                                // Set the image in randPokeImg
                                DispatchQueue.main.async {
                                    self.randPokemonImg.image = image
                                }
                            }
                        }.resume()
                    } else {
                        print("Error: no sprite URL found")
                    }
                    case .failure(let error):
                        print("Error fetching random Pokemon: \(error)")
                    }
                }
    }
    
    @IBAction func guessButtonTapped(_ sender: UIButton) {
        guard let guess = guessTextField.text else { return }

        if guess.lowercased() == pokemonName?.lowercased() {
            // Generate a new Pokémon
                fetchRandomPokemon { result in
                    switch result {
                    case .success(let pokemonData):
                        // Update pokemonName and randPokemonImg with the new data
                        self.pokemonName = pokemonData.name
                        if let spriteURLString = pokemonData.sprites.frontDefault, let spriteURL = URL(string: spriteURLString) {
                            URLSession.shared.dataTask(with: spriteURL) { data, response, error in
                                if let data = data, let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        self.randPokemonImg.image = image
                                    }
                                }
                            }.resume()
                        } else {
                            print("Error: no sprite URL found")
                        }
                    case .failure(let error):
                        print("Error fetching random Pokemon: \(error)")
                    }
                }
            } else {
                // Perform segue to DescriptionViewController
                performSegue(withIdentifier: "showDescription", sender: self)
            }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDescription" {
            let destinationVC = segue.destination as! DescriptionViewController
            destinationVC.pokemonName = pokemonName
        }
    }
    
    
    // Function for getting a random pokemon
    func fetchRandomPokemon(completion: @escaping (Result<PokemonData, Error>) -> Void) {
        let baseURL = "https://pokeapi.co/api/v2/pokemon/"
        let randomID = Int.random(in: 1...150)
        let pokemonURL = URL(string: baseURL + "\(randomID)")!

        URLSession.shared.dataTask(with: pokemonURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error!)")
                completion(.failure(error!))
                return
            }

            do {
                let pokemonJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let name = pokemonJson?["name"] as? String,
                    let sprites = pokemonJson?["sprites"] as? [String: Any],
                    let frontDefault = sprites["front_default"] as? String else {
                        print("Error: Pokemon sprite URL or name not found")
                        completion(.failure(NSError(domain: "com.example.pokedex", code: 1, userInfo: nil)))
                        return
                    }

                    let pokemonData = PokemonData(name: name, sprites: Sprites(frontDefault: frontDefault))
                    self.pokemonName = pokemonData.name
                    completion(.success(pokemonData))
                } catch {
                    print("Error: \(error)")
                    completion(.failure(error))
                }
            }.resume()
        }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        updateCollectionViewWithSuggestions(for: updatedString)
        return true
    }
    
    func updateCollectionViewWithSuggestions(for input: String?) {
        guard let input = input, !input.isEmpty else {
            collectionView.isHidden = true
            return
        }

        // Read the Pokémon names from the file
        guard let fileURL = Bundle.main.url(forResource: "pokemon_names", withExtension: "txt"),
              let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("Error: Unable to read pokemon_names.txt")
            return
        }

        let allPokemonNames = fileContents.split(separator: "\n").map { String($0) }

        // Filter the Pokémon names based on the input
        suggestions = allPokemonNames.filter { $0.lowercased().hasPrefix(input.lowercased()) }

        collectionView.reloadData()
        collectionView.isHidden = suggestions.isEmpty
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // I made a cell class and this will be using that cell.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "suggestionCell", for: indexPath) as! SuggestionCollectionViewCell
        
        cell.suggestionLabel.text = suggestions[indexPath.row]
        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = UIColor.black.cgColor
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedSuggestion = suggestions[indexPath.row]
        guessTextField.text = selectedSuggestion
        collectionView.isHidden = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 44)
    }
}
