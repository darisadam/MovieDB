//
//  MovieManagerDelegate.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 23/11/24.
//

import Foundation

protocol MovieManagerDelegate {
    func didUpdateMovies(_ movieManager: MovieManager, movies: MovieModel)
    func didFailWithError(_ error: Error)
}
