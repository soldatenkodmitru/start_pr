//
//  MovieModel.swift
//  TestForInterview
//
//  Created by Dmytro Soldatenko on 10.09.2025.
//

import Foundation

struct MovieModel : Decodable {
    let page : Int
    let total_pages : Int
    let results : [MovieListItem]
    
}

struct MovieListItem : Decodable {
    let id : Int
    let original_title : String
    let overview : String
    let poster_path : String
    let vote_average : Double
    let release_date : String
    
    // Non-decoded property for favorites functionality
    var isFavorite: Bool = false
    
    // Custom CodingKeys to exclude isFavorite from decoding
    enum CodingKeys: String, CodingKey {
        case id
        case original_title
        case overview
        case poster_path
        case vote_average
        case release_date
    }
}
