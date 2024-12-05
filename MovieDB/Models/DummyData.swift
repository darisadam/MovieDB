//
//  DummyData.swift
//  MovieDB
//
//  Created by Adam Daris Ryadhi on 03/12/24.
//

import Foundation

struct HomeDummyData {
    static let section0Images = ["captainamerica", "captainamerica", "captainamerica"]
    static let section1Images = ["split", "rover", "greenbook", "split", "rover", "greenbook"]
    static let section2Images = ["cars", "murdermystery", "avengers", "cars", "murdermystery", "avengers"]
}

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
