//
//  DummyData.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 03/12/24.
//

import Foundation

//MARK: - Home

struct HomeDummyData {
    static let section0Images = ["captainamerica", "captainamerica", "captainamerica"]
    static let section1Images = ["split", "rover", "greenbook", "split", "rover", "greenbook"]
    static let section2Images = ["cars", "murdermystery", "avengers", "cars", "murdermystery", "avengers"]
}

//MARK: - Popular

struct PopularData {
    let imageName: String
    let title: String
    let actors: String

}

struct PopularDummyData {
    static let popularMovies: [PopularData] = [
        PopularData(
            imageName: "mz1",
            title: "Maze Runner - Guide to The Glade",
            actors: "Dylan O'Brien, Kaya Scodelario, Will Poulter"
        ),
        PopularData(
            imageName: "mz2",
            title: "Maze Runner - Scorch Trials",
            actors: "Dylan O'Brien, Kaya Scodelario, Will Poulter"
        ),
        PopularData(
            imageName: "mz3",
            title: "Maze Runner - Death Cure",
            actors: "Dylan O'Brien, Kaya Scodelario, Will Poulter"
        )
    ]
}

//MARK: - Favorite

struct FavoriteData {
    let imageName: String
    let title: String
    let year: String
    let genre: String
    var isFavorited: Bool
}

struct FavoriteDummyData {
    static let movies = [
        FavoriteData(
            imageName: "itaewon",
            title: "Itaewon Class",
            year: "2020",
            genre: "Drama, Asian, Comedy, Series",
            isFavorited: true
        ),
        FavoriteData(
            imageName: "conjuring",
            title: "Conjuring 3",
            year: "2019",
            genre: "Horror, Dark",
            isFavorited: true
        ),
        FavoriteData(
            imageName: "cars3",
            title: "Cars 3",
            year: "2020",
            genre: "Kids, Comedy, Racing",
            isFavorited: true
        ),
        FavoriteData(
            imageName: "coco",
            title: "Coco",
            year: "2019",
            genre: "Kids, Family",
            isFavorited: true
        )
    ]
}

//MARK: - Detail

struct MovieDetail: Hashable {
    let movieImage: String
    let movieTitle: String
    let movieDuration: String
    let movieQuality: String
    let movieGenre: [MovieGenre]
    let movieDescription: String
    let movieCast: [MovieCast]
    
}

struct MovieGenre: Hashable {
    let genreName: String
}

struct MovieCast: Hashable {
    let actorImage: String
    let actorName: String
}

struct MovieDetailDummyData {
    static let genres = [
        MovieGenre(genreName: "Adventure"),
        MovieGenre(genreName: "Action"),
        MovieGenre(genreName: "Comedy")
    ]
    
    static let cast = [
        MovieCast(actorImage: "dave", actorName: "Dave Franco"),
        MovieCast(actorImage: "jesse", actorName: "Jesse Eisenberg"),
        MovieCast(actorImage: "woody", actorName: "Woody Harrelson"),
        MovieCast(actorImage: "daniel", actorName: "Daniel Radcliffe")
    ]
    
    static let movie = MovieDetail(
        movieImage: "nowyouseeme2",
        movieTitle: "Now You See Me 2",
        movieDuration: "1h 29m",
        movieQuality: "HD",
        movieGenre: genres,
        movieDescription: "Eighteen months after outwitting the FBI, the fugitive Four Horsemen – J. Daniel Atlas, Merritt McKinney, Jack Wilder, and new member Lula May – await orders from the Eye, the secret society of magicians. The Horsemen’s handler, FBI Special Agent Dylan Rhodes, delivers their instructions: the Horsemen are to expose corrupt tech CEO Owen Case, whose latest cell phone will secretly collect users’ personal data to sell on the black market. In New York City, the Horsemen hijack the phone’s launch, but are interrupted by a mysterious figure who reveals to the public that Jack faked his death, and that Dylan is working with the Horsemen. Dylan eludes the FBI as the Horsemen escape down a construction chute only to find themselves in Macau.",
        movieCast: cast
    )
}
