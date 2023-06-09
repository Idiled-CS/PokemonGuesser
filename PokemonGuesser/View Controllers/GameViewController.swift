//
//  GaneViewController.swift
//  PokemonGuesser
//
//  Created by Andrew Pan on 5/3/23.
//

import UIKit


// Custom Protocol
protocol PokeBallChangeDelegate: AnyObject {
    func didChangePokeBall()
}


class GameViewController: UIViewController, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PokeBallChangeDelegate {
    func didChangePokeBall() {
        startSpinningPokeball()
    }
    
    // MARK: - Outlets
    @IBOutlet weak var guessTextField: UITextField!
    @IBOutlet weak var randPokemonImg: UIImageView!
    @IBOutlet weak var guessButton: UIButton!
    @IBOutlet weak var pokeballImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pokemonName: String!
    var suggestions: [String] = []
    var pokemon: Pokemon?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        guessTextField.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self

        // Adding scroll wheel to suggestions
        collectionView.isScrollEnabled = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: 200 * 3) // Limit the height to show 3 suggestions at once
        ])
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 0
        }
        
        // Set the initial pokeball image
        let pokeBallColor = UserDefaults.standard.string(forKey: "pokeBallColor") ?? "redPokeBall"
        pokeballImageView.image = UIImage(named: pokeBallColor)

        // Add tap gesture recognizer to the image view
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pokeBallTapped))
        pokeballImageView.isUserInteractionEnabled = true
        pokeballImageView.addGestureRecognizer(tapGestureRecognizer)
        
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
        
        startSpinningPokeball()
    }

    
    @objc func pokeBallTapped() {
        
        
        // Get the current pokeball color
        var pokeBallColor = UserDefaults.standard.string(forKey: "pokeBallColor") ?? "redPokeBall"

        // Swap the color
        pokeBallColor = (pokeBallColor == "redPokeBall") ? "bluePokeBall" : "redPokeBall"

        // Save the new color and update the image
        UserDefaults.standard.setValue(pokeBallColor, forKey: "pokeBallColor")
        pokeballImageView.image = UIImage(named: pokeBallColor)

        // Call the delegate method
        didChangePokeBall()
    }
        
    
    // Animation for spinning
    func startSpinningPokeball() {
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {
            self.pokeballImageView.transform = self.pokeballImageView.transform.rotated(by: CGFloat.pi)
        }) { (finished) in
            if finished {
                self.startSpinningPokeball()
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
        processGuess()
    }
    
    func processGuess() {
        guard let guess = guessTextField.text else { return }

        if guess.lowercased() == pokemon?.name.lowercased() {
            fetchRandomPokemonAndUpdateUI()
        } else {
            performSegue(withIdentifier: "showDescription", sender: self)
        }
    }
    
    func fetchRandomPokemonAndUpdateUI() {
        fetchRandomPokemon { result in
            switch result {
            case .success(let pokemon):
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
    
    // MARK: CollectionView
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "suggestionCell", for: indexPath) as! SuggestionCollectionViewCell
        cell.suggestionLabel.text = suggestions[indexPath.row]

        // remove the border
        cell.layer.borderWidth = 0.0
        cell.backgroundColor = .white

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

// Native class Extension to fetch Images
extension UIImage {
    static func fetchFrom(url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            completion(image)
        }.resume()
    }
}


extension GameViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        processGuess()
        textField.resignFirstResponder()
        return true
    }
}

