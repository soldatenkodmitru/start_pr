//
//  MovieCell.swift
//  TestForInterview
//
//  Created by Dmytro Soldatenko on 10.09.2025.
//

import UIKit
import SDWebImage

class MovieCell: UICollectionViewCell {
    
    @IBOutlet weak var movieImageView: UIImageView!
    @IBOutlet weak var movieTitleLabel: UILabel!
    @IBOutlet weak var movieRatingLabel: UILabel!
    
    func configure(with movie: Movies) {
        movieTitleLabel.text = movie.original_title
        movieRatingLabel.text = "⭐️ \(movie.vote_average)"
        let urlString = "https://image.tmdb.org/t/p/w500\(movie.poster_path)"
        if let url = URL(string: urlString) {
            movieImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"))
        }
    }
}
