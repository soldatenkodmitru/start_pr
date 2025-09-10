//
//  MovieManager.swift
//  TestForInterview
//
//  Created by Dmytro Soldatenko on 10.09.2025.
//
import Foundation

struct MovieManager {
    
    func fetchMovies(completion : @escaping(MovieModel) -> ()){
        guard let url = URL(string :"https://api.themoviedb.org/3/movie/popular?api_key=3b4f187bffd4689de170754dc129c939") else { return }
        let dataTask = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print(error.localizedDescription)
            }
            // DECODING
            guard let jsonData = data else { return }
            let decoder = JSONDecoder()
            
            do {
                let decodedData = try decoder.decode(MovieModel.self, from: jsonData)
                completion(decodedData )
            }catch{
                print("Error to decoding data")
            }
        }
        dataTask.resume()
        
    }
    
}
