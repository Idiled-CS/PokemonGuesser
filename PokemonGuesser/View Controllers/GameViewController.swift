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
    var pokemon: Pokemon?
    
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
                case .success(let pokemon):
                    self.pokemon = pokemon
                    if let url = URL(string: pokemon.sprites.front_default!) {
                        self.downloadImage(from: url)
                    }
                case .failure(let error):
                    print("Error fetching random Pokemon: \(error)")
                }
            }
        
    }
    
    
    func downloadImage(from url: URL) {
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.randPokemonImg.image = UIImage(data: data)
            }
        }
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    
    @IBAction func guessButtonTapped(_ sender: UIButton) {
        guard let guess = guessTextField.text else { return }

            if guess.lowercased() == pokemon?.name.lowercased() {
                // Generate a new Pokémon
                fetchRandomPokemon { result in
                    switch result {
                    case .success(let pokemon):
                        // Update pokemon and randPokemonImg with the new data
                        self.pokemon = pokemon
                        if let spriteURLString = pokemon.sprites.front_default, let spriteURL = URL(string: spriteURLString) {
                            self.downloadImage(from: spriteURL)
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
            destinationVC.pokemon = pokemon
        }
    }
    
    
    // Function for getting a random pokemon
    func fetchRandomPokemon(completion: @escaping (Result<Pokemon, Error>) -> Void) {
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
                let pokemon = try JSONDecoder().decode(Pokemon.self, from: data)
                self.pokemon = pokemon
                DispatchQueue.main.async {
                    if let spriteURLString = pokemon.sprites.front_default, let spriteURL = URL(string: spriteURLString) {
                        URLSession.shared.dataTask(with: spriteURL) { data, response, error in
                            if let data = data, let image = UIImage(data: data) {
                                self.randPokemonImg.image = image
                            }
                        }.resume()
                    } else {
                        print("Error: no sprite URL found")
                    }
                }
                completion(.success(pokemon))
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
