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
    
    // Programmatically created favorite button
    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .systemYellow
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.layer.cornerRadius = 15
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return button
    }()
    
    // Callback for favorite button tap
    var onFavoriteToggle: ((MovieListItem) -> Void)?
    private var currentMovie: MovieListItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupFavoriteButton()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        movieImageView.image = nil
        movieImageView.sd_cancelCurrentImageLoad()
        onFavoriteToggle = nil
        currentMovie = nil
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
        movieImageView.isUserInteractionEnabled = true
        
        // Labels styling
        movieTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        movieTitleLabel.textColor = .label
        movieTitleLabel.numberOfLines = 2
        
        movieRatingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        movieRatingLabel.textColor = .secondaryLabel
    }
    
    private func setupFavoriteButton() {
        // Add favorite button to the image view (top-right corner)
        movieImageView.addSubview(favoriteButton)
        
        NSLayoutConstraint.activate([
            favoriteButton.topAnchor.constraint(equalTo: movieImageView.topAnchor, constant: 8),
            favoriteButton.trailingAnchor.constraint(equalTo: movieImageView.trailingAnchor, constant: -8),
            favoriteButton.widthAnchor.constraint(equalToConstant: 30),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }
    
    @objc private func favoriteButtonTapped() {
        guard var movie = currentMovie else { return }
        
        // Toggle favorite status
        movie.isFavorite = !movie.isFavorite
        currentMovie = movie
        
        // Update button appearance
        updateFavoriteButton(isFavorite: movie.isFavorite)
        
        // Notify delegate
        onFavoriteToggle?(movie)
    }
    
    private func updateFavoriteButton(isFavorite: Bool) {
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorite ? .systemRed : .systemYellow
    }
    
    func configure(with movieItem: MovieListItem, onFavoriteToggle: @escaping (MovieListItem) -> Void) {
        currentMovie = movieItem
        self.onFavoriteToggle = onFavoriteToggle
        
        movieTitleLabel.text = movieItem.original_title
        movieRatingLabel.text = "⭐️ \(movieItem.vote_average)"
        
        let urlString = "https://image.tmdb.org/t/p/w500\(movieItem.poster_path)"
        if let url = URL(string: urlString) {
            movieImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"), options: [.progressiveLoad, .scaleDownLargeImages])
        }
        
        // Update favorite button
        updateFavoriteButton(isFavorite: movieItem.isFavorite)
    }
    
    // Backwards compatibility - keep the old configure method
    func configure(with movieItem: MovieListItem) {
        configure(with: movieItem) { _ in }
    }
}
