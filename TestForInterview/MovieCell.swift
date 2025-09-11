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
    //@IBOutlet weak var favoriteImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        movieImageView.image = nil
        movieImageView.sd_cancelCurrentImageLoad()
    }
    
    private func setupUI() {
        // Cell styling
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
        
        // Image view styling
        movieImageView.contentMode = .scaleAspectFill
        movieImageView.clipsToBounds = true
        movieImageView.layer.cornerRadius = 8
        
        // Labels styling
        movieTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        movieTitleLabel.textColor = .label
        movieTitleLabel.numberOfLines = 2
        
        movieRatingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        movieRatingLabel.textColor = .secondaryLabel
        
        // Favorite icon styling
        //favoriteImageView.tintColor = .systemYellow
        //favoriteImageView.image = UIImage(systemName: "star.fill")
    }
    
    func configure(with movieItem: MovieListItem) {
        movieTitleLabel.text = movieItem.original_title
        movieRatingLabel.text = "⭐️ \(movieItem.vote_average)"
        let urlString = "https://image.tmdb.org/t/p/w500\(movieItem.poster_path)"
        if let url = URL(string: urlString) {
            movieImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"), options: [.progressiveLoad, .scaleDownLargeImages])
        }
        //favoriteImageView.isHidden = !movieItem.isFavorite
        
    }
}
