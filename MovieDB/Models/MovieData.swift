//
//  MovieData.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 22/11/24.
//

import Foundation

struct MovieResponse: Decodable {
    let results: [Movie]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct Movie: Identifiable, Decodable {
    let id: Int
    let title: String
    let backdropPath: String?
    let originalTitle: String
    let posterPath: String?
    let overview: String
    let popularity: Double
    let releaseDate: String
    let genreIds: [Int]
    let voteAverage: Double
    let voteCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case backdropPath = "backdrop_path"
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case overview
        case popularity
        case releaseDate = "release_date"
        case genreIds = "genre_ids"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
    
    var fullPosterPath: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var fullBackdropPath: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(backdropPath)")
    }
}

