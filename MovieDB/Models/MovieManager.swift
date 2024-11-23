//
//  MovieManager.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import Foundation

struct MovieManager {
    let movieURL = "https://api.themoviedb.org/3/movie/100?api_key=#"
    let apiKey  = ""
    
    var delegate: MovieManagerDelegate?
    
    func fetchMovies() {
        //
    }
    
    func performRequest(with urlString: String) {
        
        if let url = URL(string: movieURL) {
            
            let session = URLSession(configuration: .default)
            
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error!)
                }
                
                if let safeData = data {
                    if let movies = self.parseJSON(safeData) {
                        self.delegate?.didUpdateMovies(self, movies: movies)
                    }
                }
            }
            
            task.resume()
        }
    }
    
    func parseJSON(_ movieData: Data) -> MovieModel? {
        let decoder = JSONDecoder()
        
        do {
            let decodedData = try decoder.decode(MovieData.self, from: movieData)
            let id = decodedData.id
            let title = decodedData.title
            
            let movie = MovieModel(id: id, title: title)
            return movie
        } catch {
            delegate?.didFailWithError(error)
            return nil
        }
    }
}
