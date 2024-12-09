//
//  MovieManager.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import Foundation

class MovieManager {
    static let shared = MovieManager()
    private let baseURL = "https://api.themoviedb.org/3"
    private let apiKey = "123abc"
    
    func fetchPopularMovies(page: Int = 1, completion: @escaping (Result<MovieResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/movie/popular?api_key=\(apiKey)&language=en-US&page=\(page)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in

            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "Invalid Response", code: 0)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 0)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let movieResponse = try decoder.decode(MovieResponse.self, from: data)
                completion(.success(movieResponse))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }
}
