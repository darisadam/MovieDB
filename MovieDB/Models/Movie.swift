//
//  Movie.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 22/11/24.
//

import Foundation

struct Movie: Identifiable, Decodable {
    let id: Int
    let title: String
    let backdrop_path: String
    let original_title: String
    let poster_path: String
    let overview: String
    let isFavorite: Bool
    let runtime: Int
}

struct BelongsToCollection: Identifiable, Decodable {
    let id: Int
    let name: String
    let poster_path: String
    let backdrop_path: String
}

struct Genres: Identifiable, Decodable {
    let id: Int
    let name: String
}

