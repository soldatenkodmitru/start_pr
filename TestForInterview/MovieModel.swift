//
//  MovieModel.swift
//  TestForInterview
//
//  Created by Dmytro Soldatenko on 10.09.2025.
//

import Foundation

struct MovieModel : Decodable {
    let page : Int
    let results : [Movies]
    
}

struct Movies : Decodable {
    let original_title : String
    let overview : String
    let poster_path : String
    
}
